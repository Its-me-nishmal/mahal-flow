package pg

import (
	"crypto/sha512"
	"encoding/hex"
	"testing"
)

func TestPayUHashGenerationAndVerification(t *testing.T) {
	key := "XiiFzG"
	salt := "rhBcaHet9cjLDX0B8oc3QQiJfOTVkH99"
	txnid := "ORD_TEST_101"
	amount := "500.00"
	productinfo := "Mahal Dues Contribution"
	firstname := "Muhammed"
	email := "test@example.com"
	udf1 := "TXN_101"
	udf2 := "MAHAL_CALICUT"
	udf3 := "MEM_01"
	udf4 := ""
	udf5 := ""

	hash := GeneratePayUHash(key, txnid, amount, productinfo, firstname, email, udf1, udf2, udf3, udf4, udf5, salt)
	if hash == "" {
		t.Fatal("expected non-empty PayU hash")
	}

	// Verification of response reverse hash
	respParams := map[string]string{
		"key":         key,
		"txnid":       txnid,
		"amount":      amount,
		"productinfo": productinfo,
		"firstname":   firstname,
		"email":       email,
		"udf1":        udf1,
		"udf2":        udf2,
		"udf3":        udf3,
		"udf4":        udf4,
		"udf5":        udf5,
		"status":      "success",
	}

	// Calculate expected response hash
	reverseHashStr := salt + "|success||||||" + udf5 + "|" + udf4 + "|" + udf3 + "|" + udf2 + "|" + udf1 + "|" + email + "|" + firstname + "|" + productinfo + "|" + amount + "|" + txnid + "|" + key
	hasher := sha512.New()
	hasher.Write([]byte(reverseHashStr))
	expectedRespHash := hex.EncodeToString(hasher.Sum(nil))

	if !VerifyPayUResponseHash(respParams, salt, expectedRespHash) {
		t.Fatal("VerifyPayUResponseHash failed for valid response hash")
	}

	// Tamper status
	respParams["status"] = "failure"
	if VerifyPayUResponseHash(respParams, salt, expectedRespHash) {
		t.Fatal("VerifyPayUResponseHash should fail for tampered status")
	}
}

func TestParseVerifyPayment(t *testing.T) {
	body := []byte(`{"status":1,"msg":"1 out of 1 Transactions Fetched Successfully","transaction_details":{"ORDTXN1":{"mihpayid":"403993715521","status":"success","mode":"UPI","amt":"500.00"}}}`)
	d, err := parseVerifyPayment(body, "ORDTXN1")
	if err != nil || d.MihPayID != "403993715521" || d.Status != "success" || d.Mode != "UPI" || d.Amount != "500.00" {
		t.Fatalf("parse: %+v %v", d, err)
	}
	d, err = parseVerifyPayment([]byte(`{"status":0,"transaction_details":{}}`), "ORDX")
	if err != nil || d.Status != "Not Found" {
		t.Fatalf("missing txn: %+v %v", d, err)
	}
	if _, err := parseVerifyPayment([]byte(`<html>`), "ORDX"); err == nil {
		t.Fatal("HTML must be an error")
	}
}

func TestDynamicHashPostSaltIsAppended(t *testing.T) {
	c := NewClient(Config{APIKey: "K", Salt: "SALT"})
	withPost := c.GenerateDynamicHash("x", "K|cmd|v|", "", "POST")
	// The client-supplied post salt must never replace the merchant salt.
	if withPost == NewClient(Config{APIKey: "K", Salt: "POST"}).GenerateDynamicHash("x", "K|cmd|v|", "", "") {
		t.Fatal("post_salt replaced the merchant salt")
	}
	if withPost != NewClient(Config{APIKey: "K", Salt: "SALTPOST"}).GenerateDynamicHash("x", "K|cmd|v|", "", "") {
		t.Fatal("post_salt must be appended after the salt")
	}
}

func TestModeAndMaskedKey(t *testing.T) {
	c := NewClient(Config{BaseURL: "https://secure.payu.in/_payment", APIKey: "abcdef1234", Salt: "s"})
	if c.Mode() != "LIVE" || c.MaskedKey() != "••••1234" || !c.Live() {
		t.Fatalf("live client: %s %s %v", c.Mode(), c.MaskedKey(), c.Live())
	}
	if NewClient(Config{}).Mode() != "TEST" || NewClient(Config{}).Live() {
		t.Fatal("default client targets the sandbox and is not live")
	}
	var nilClient *Client
	if nilClient.Live() {
		t.Fatal("nil client is not live")
	}
}
