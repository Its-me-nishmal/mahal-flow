package api

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/gateway/pg"
	"github.com/rs/zerolog/log"
)

// ---------------------------------------------------------------------------
// Order ids
// ---------------------------------------------------------------------------

// txnIDFromOrderID maps the merchant order id sent to PayU back to our
// transaction id. Initialize issues "ORD"+id; older code and some callers
// used "ORD_"+id; a bare transaction id is accepted as-is.
func txnIDFromOrderID(orderID string) string {
	s := strings.TrimSpace(orderID)
	switch {
	case strings.HasPrefix(s, "ORD_"):
		return s[len("ORD_"):]
	case strings.HasPrefix(s, "ORD") && len(s) > len("ORD"):
		return s[len("ORD"):]
	}
	return s
}

// orderIDForTxn is the canonical PayU txnid for a transaction.
func orderIDForTxn(txn *domain.Transaction) string {
	if txn.GatewayOrderID != "" {
		return txn.GatewayOrderID
	}
	return "ORD" + txn.ID
}

func isMandateID(id string) bool { return strings.HasPrefix(strings.TrimSpace(id), "MND") }

// ---------------------------------------------------------------------------
// Checkout parameters (single source for SDK data, hash checks and the page)
// ---------------------------------------------------------------------------

const (
	defaultPayerName  = "Mahal Member"
	defaultPayerEmail = "member@mahalflow.org"
	defaultPayerPhone = "9900990099"
)

type payer struct{ name, email, phone string }

func (h *Handler) payerFor(ctx context.Context, mahalID, memberID string) payer {
	p := payer{defaultPayerName, defaultPayerEmail, defaultPayerPhone}
	if h.memberRepo == nil || memberID == "" {
		return p
	}
	if m, err := h.memberRepo.GetByID(ctx, mahalID, memberID); err == nil && m != nil {
		if m.Name != "" {
			p.name = m.Name
		}
		if m.Phone != "" {
			p.phone = m.Phone
		}
	}
	return p
}

// checkoutParamsForTxn are the PayU parameters for paying txn. The hash
// endpoint rebuilds exactly these to decide whether a payment hash request is
// genuine, so every checkout path must use this function.
func (h *Handler) checkoutParamsForTxn(ctx context.Context, txn *domain.Transaction) pg.PaymentRequestParams {
	orderID := orderIDForTxn(txn)
	py := h.payerFor(ctx, txn.MahalID, txn.MemberID)
	currency := txn.Currency
	if currency == "" {
		currency = "INR"
	}
	return pg.PaymentRequestParams{
		OrderID:     orderID,
		Amount:      fmt.Sprintf("%.2f", txn.Amount),
		Currency:    currency,
		Description: "Mahal Payment " + orderID,
		Name:        py.name,
		Email:       py.email,
		Phone:       py.phone,
		UDF1:        txn.ID,
		UDF2:        txn.MahalID,
		UDF3:        txn.MemberID,
	}
}

// checkoutParamsForMandate are the PayU parameters for a mandate's ₹1 SI
// consent transaction.
func (h *Handler) checkoutParamsForMandate(ctx context.Context, m *domain.Mandate) pg.PaymentRequestParams {
	py := h.payerFor(ctx, m.MahalID, m.MemberID)
	return pg.PaymentRequestParams{
		OrderID:     m.ID,
		Amount:      "1.00", // penny authorisation for the SI mandate
		Currency:    "INR",
		Description: "MahalFlow AutoPay Mandate for " + py.name,
		Name:        py.name,
		Email:       py.email,
		Phone:       py.phone,
		UDF1:        m.ID,
		UDF2:        m.MahalID,
		UDF3:        m.MemberID,
		IsSI:        true,
		SIDetails:   m.SIDetails,
	}
}

// loadOwnPayable resolves an order id (transaction or mandate) the caller may
// pay, and its checkout parameters.
func (h *Handler) loadOwnPayable(c *fiber.Ctx, id string) (pg.PaymentRequestParams, *apiError) {
	id = strings.Clone(strings.TrimSpace(id))
	if isMandateID(id) {
		if h.mandateRepo == nil {
			return pg.PaymentRequestParams{}, &apiError{status: fiber.StatusServiceUnavailable, msg: "AutoPay service offline"}
		}
		m, err := h.mandateRepo.GetByID(c.Context(), id)
		if err != nil || m == nil || !canSeeMemberRecord(c, m.MahalID, m.MemberID) {
			return pg.PaymentRequestParams{}, errNotFound("Mandate not found")
		}
		return h.checkoutParamsForMandate(c.Context(), m), nil
	}
	txn, aerr := h.loadOwnTransaction(c, txnIDFromOrderID(id))
	if aerr != nil {
		return pg.PaymentRequestParams{}, aerr
	}
	return h.checkoutParamsForTxn(c.Context(), txn), nil
}

// ---------------------------------------------------------------------------
// PayU SDK dynamic hashes
// ---------------------------------------------------------------------------

// payuPublicCommands are read-only CheckoutPro SDK commands whose var1 is not
// tied to a payer.
var payuPublicCommands = map[string]bool{
	"vas_for_mobile_sdk":              true,
	"get_sdk_configuration":           true,
	"getEmiAmountAccordingToInterest": true,
	"eligibleBinsForEMI":              true,
	"check_isDomestic":                true,
	"validateVPA":                     true,
	"check_offer_status":              true,
	"get_eligible_payment_options":    true,
}

// payuUserCommands take the payer's user_credential ("key:memberId") as var1:
// allowed only for the caller's own credential (or PayU's "default").
var payuUserCommands = map[string]bool{
	"payment_related_details_for_mobile_sdk": true,
	"get_user_cards":                         true,
	"save_user_card":                         true,
	"edit_user_card":                         true,
	"delete_user_card":                       true,
	"get_payment_instrument":                 true,
	"get_payment_details":                    true,
	"delete_payment_instrument":              true,
}

// payuV2HashNames are the SDK requests signed with HMAC-SHA256 (V2).
var payuV2HashNames = map[string]bool{
	"get_checkout_details": true,
}

const maxHashStringLength = 4096

// paymentHashPrefix is the SDK's payment hash string for p, without salt:
// key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5||||||
func paymentHashPrefix(key string, p pg.PaymentRequestParams) string {
	return fmt.Sprintf("%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s||||||",
		key, p.OrderID, p.Amount, p.Description, p.Name, p.Email, p.UDF1, p.UDF2, p.UDF3, p.UDF4, p.UDF5)
}

// authorizeHashRequest decides whether the server may sign req. The endpoint
// used to sign any string with the merchant salt — a signing oracle for every
// PayU API (refunds, SI debits, forged payment hashes). Now it signs only:
//   - the payment hash of a transaction / mandate the caller owns, rebuilt
//     from stored data (plus that mandate's si_details, for SI);
//   - allowlisted SDK read commands, and user-bound commands for the
//     caller's own user_credential;
//   - allowlisted V2 names, for a transaction the caller owns.
func (h *Handler) authorizeHashRequest(c *fiber.Ctx, req PayUHashRequest) *apiError {
	refuse := func(why string) *apiError {
		log.Warn().Str("hash_name", req.HashName).Str("role", sessionRole(c)).Str("subject", sessionSubject(c)).
			Str("reason", why).Msg("PayU hash request refused")
		return errForbidden("This hash request is not allowed")
	}
	if req.HashString == "" {
		return errBadRequest("hash_string is required")
	}
	if len(req.HashString) > maxHashStringLength || (strings.ContainsAny(req.HashString, "\r\n") && !strings.EqualFold(req.HashType, "V2")) {
		return refuse("malformed hash string")
	}

	if strings.EqualFold(req.HashType, "V2") {
		if !payuV2HashNames[req.HashName] {
			return refuse("V2 hash name not allowlisted")
		}
		if strings.TrimSpace(req.TxnID) == "" {
			return refuse("V2 hash without txnid")
		}
		if _, aerr := h.loadOwnPayable(c, req.TxnID); aerr != nil {
			return refuse("V2 hash for a transaction the caller does not own")
		}
		return nil
	}

	fields := strings.Split(req.HashString, "|")
	if len(fields) < 4 || fields[0] != h.pgClient.APIKey {
		return refuse("not a hash for this merchant")
	}

	// Payment hash: key|txnid|amount|...|udf5|||||| [+ si_details]
	if len(fields) >= 17 {
		txnid := fields[1]
		if req.TxnID != "" && req.TxnID != txnid {
			return refuse("txnid mismatch")
		}
		params, aerr := h.loadOwnPayable(c, txnid)
		if aerr != nil {
			return refuse("payment hash for a transaction the caller does not own")
		}
		prefix := paymentHashPrefix(h.pgClient.APIKey, params)
		if !strings.HasPrefix(req.HashString, prefix) {
			return refuse("payment hash fields do not match the stored transaction")
		}
		rest := req.HashString[len(prefix):]
		if rest == "" {
			return nil
		}
		if params.IsSI && params.SIDetails != "" {
			for _, ok := range []string{params.SIDetails, params.SIDetails + "|", "|" + params.SIDetails, "|" + params.SIDetails + "|"} {
				if rest == ok {
					return nil
				}
			}
		}
		return refuse("unexpected trailing fields in payment hash")
	}

	// Command hash: key|command|var1|
	if len(fields) != 4 || fields[3] != "" {
		return refuse("unrecognised hash string shape")
	}
	command, var1 := fields[1], fields[2]
	switch {
	case payuPublicCommands[command]:
		return nil
	case payuUserCommands[command]:
		if var1 == "default" {
			return nil
		}
		if sessionRole(c) == domain.RoleMember && var1 == h.pgClient.APIKey+":"+sessionSubject(c) {
			return nil
		}
		return refuse("user credential is not the caller's")
	default:
		return refuse("command not allowlisted: " + command)
	}
}

// ---------------------------------------------------------------------------
// Signed links for the public checkout page
// ---------------------------------------------------------------------------

// CheckoutLinkTTL is how long a signed checkout link works.
const CheckoutLinkTTL = 30 * time.Minute

// SetPublicBaseURL sets how browsers reach this API (used in signed links).
func (h *Handler) SetPublicBaseURL(u string) { h.publicBaseURL = strings.TrimRight(u, "/") }

func checkoutSignature(orderID string, exp int64) string {
	secret, err := getJWTSecret()
	if err != nil {
		return ""
	}
	mac := hmac.New(sha256.New, append([]byte("payu-checkout:"), secret...))
	mac.Write([]byte(orderID + "|" + strconv.FormatInt(exp, 10)))
	return base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
}

// signedCheckoutURL is the public checkout page link for orderID, valid for
// CheckoutLinkTTL. Without the signature the page refuses to render, so an
// order id alone reveals nothing.
func (h *Handler) signedCheckoutURL(orderID string) string {
	base := h.publicBaseURL
	if base == "" {
		base = "http://localhost:8080"
	}
	exp := time.Now().Add(CheckoutLinkTTL).Unix()
	q := url.Values{}
	q.Set("exp", strconv.FormatInt(exp, 10))
	q.Set("sig", checkoutSignature(orderID, exp))
	return base + "/api/v1/payments/payu-checkout/" + url.PathEscape(orderID) + "?" + q.Encode()
}

func validCheckoutSignature(orderID, expStr, sig string, now time.Time) bool {
	exp, err := strconv.ParseInt(expStr, 10, 64)
	if err != nil || sig == "" || now.Unix() > exp || exp > now.Add(CheckoutLinkTTL+time.Minute).Unix() {
		return false
	}
	want := checkoutSignature(orderID, exp)
	return want != "" && hmac.Equal([]byte(want), []byte(sig))
}

// firstName keeps only the first word of a name for pages anyone holding the
// link can see.
func firstName(name string) string {
	if f := strings.Fields(name); len(f) > 0 {
		return f[0]
	}
	return defaultPayerName
}
