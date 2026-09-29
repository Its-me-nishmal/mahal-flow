package api

import (
	"context"

	"github.com/mahalflow/backend-go/internal/domain"
	"github.com/mahalflow/backend-go/internal/service"
)

// Receipts are immutable (invariant #4): a refund never edits the stored
// receipt. Reads therefore overlay the current state of the receipt's
// transaction: REFUNDED once it was refunded, plus gateway / method / fund
// for receipts issued before those fields were stored.

func (h *Handler) decorateReceipt(ctx context.Context, r *domain.Receipt) {
	if r == nil {
		return
	}
	one := []domain.Receipt{*r}
	h.decorateReceipts(ctx, r.MahalID, one)
	*r = one[0]
}

func (h *Handler) decorateReceipts(ctx context.Context, mahalID string, receipts []domain.Receipt) {
	if len(receipts) == 0 {
		return
	}
	var txns map[string]domain.Transaction
	if h.txnRepo != nil {
		ids := make([]string, 0, len(receipts))
		for _, r := range receipts {
			if r.TransactionID != "" {
				ids = append(ids, r.TransactionID)
			}
		}
		txns, _ = h.txnRepo.GetByIDs(ctx, mahalID, ids)
	}
	for i := range receipts {
		applyReceiptOverlay(&receipts[i], txns)
	}
}

func applyReceiptOverlay(r *domain.Receipt, txns map[string]domain.Transaction) {
	if r.Status == "" {
		r.Status = domain.ReceiptStatusSuccess
	}
	t, ok := txns[r.TransactionID]
	if !ok {
		return
	}
	if t.Status == domain.TxnRefunded {
		r.Status = domain.ReceiptStatusRefunded
		r.RefundedAt = t.CompletedAt
	}
	if r.Gateway == "" {
		r.Gateway = service.ReceiptGateway(&t)
	}
	if r.PaymentMethod == "" {
		r.PaymentMethod = service.ReceiptPaymentMethod(&t)
	}
	if r.Fund == "" {
		r.Fund = t.Purpose
	}
	if r.Note == "" {
		r.Note = t.Note
	}
}
