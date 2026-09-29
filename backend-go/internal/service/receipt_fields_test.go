package service

import (
	"testing"

	"github.com/mahalflow/backend-go/internal/domain"
)

func TestReceiptGatewayAndMethod(t *testing.T) {
	cases := []struct {
		txn             domain.Transaction
		gateway, method string
	}{
		{domain.Transaction{Gateway: "CASH"}, "CASH", "CASH"},
		{domain.Transaction{Gateway: "PAYU", PaymentMode: "NB"}, "PAYU", "NETBANKING"},
		{domain.Transaction{Gateway: "PAYU", IdempotencyKey: "SI_MND1_2026", PaymentMode: "UPI"}, "PAYU_SI", "UPI"},
		{domain.Transaction{Gateway: "PAYU"}, "PAYU", ""},
	}
	for _, c := range cases {
		if g := ReceiptGateway(&c.txn); g != c.gateway {
			t.Errorf("%+v: gateway %q, want %q", c.txn, g, c.gateway)
		}
		if m := ReceiptPaymentMethod(&c.txn); m != c.method {
			t.Errorf("%+v: method %q, want %q", c.txn, m, c.method)
		}
	}
}
