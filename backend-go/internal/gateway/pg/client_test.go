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
