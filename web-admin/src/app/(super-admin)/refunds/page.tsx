"use client";

import { useCallback, useEffect, useState } from "react";
import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { ErrorState } from "@/components/ui/States";
import { useToast } from "@/components/ui/Toast";
import { ApiClient } from "@/lib/api-client";
import { errorMessage, formatDate, formatINR } from "@/lib/format";

export default function RefundManagementPage() {
  const toast = useToast();
  const [refunds, setRefunds] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const loadRefunds = useCallback(() => {
    setLoading(true);
    setError(null);
    ApiClient.getRefunds()
      .then((res) => setRefunds(res?.refunds || []))
      .catch((err) => setError(errorMessage(err, "Could not load refunds.")))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    loadRefunds();
  }, [loadRefunds]);

  const handleAction = async (id: string, action: "APPROVE" | "REJECT") => {
    if (action === "APPROVE" && !window.confirm("Approve this refund? The amount is returned through the payment gateway.")) return;
    setBusyId(id);
    try {
      await ApiClient.processRefund(id, action);
      toast.success(action === "APPROVE" ? "Refund approved." : "Refund rejected.");
      loadRefunds();
    } catch (err) {
      toast.error(errorMessage(err, "Could not process the refund."));
    } finally {
      setBusyId(null);
    }
  };

  const pendingCount = refunds.filter((r) => r.status === "PENDING").length;
  const approvedTotal = refunds
    .filter((r) => r.status === "APPROVED" || r.status === "PROCESSED")
    .reduce((sum, r) => sum + (Number(r.amount) || 0), 0);

  return (
    <>
      <PageHeader title="Refund Management" description="Review and process member refund requests." />

      {error && <ErrorState message={error} onRetry={loadRefunds} />}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-lg">
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Total Refunded</p>
          <h3 className="font-amount-lg text-amount-lg text-text-primary">{formatINR(approvedTotal)}</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Pending Approvals</p>
          <h3 className="font-amount-lg text-amount-lg text-error">{pendingCount}</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Total Requests</p>
          <h3 className="font-amount-lg text-amount-lg text-text-primary">{refunds.length}</h3>
        </div>
      </div>

      <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
        <div className="p-lg border-b border-border-base flex items-center justify-between">
          <h3 className="font-card-title text-card-title text-text-primary">Refund Requests</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low border-b border-border-base">
                {["REFUND ID", "MEMBER", "RECEIPT", "AMOUNT", "REASON", "REQUESTED", "STATUS"].map((h) => (
                  <th key={h} className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                    {h}
                  </th>
                ))}
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold text-right">ACTION</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base">
              {refunds.map((ref) => (
                <tr key={ref.id} className="hover:bg-surface-bright transition-colors">
                  <td className="py-4 px-lg font-button text-button text-text-primary">{ref.id}</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">{ref.member_name || ref.member_id || "—"}</td>
                  <td className="py-4 px-lg font-mono text-xs text-text-secondary">{ref.receipt_number || "—"}</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary font-semibold whitespace-nowrap">{formatINR(ref.amount)}</td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary">{ref.reason || "—"}</td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary whitespace-nowrap">{formatDate(ref.requested_at)}</td>
                  <td className="py-4 px-lg">
                    <StatusBadge status={ref.status} />
                  </td>
                  <td className="py-4 px-lg text-right">
                    {ref.status === "PENDING" ? (
                      <div className="flex justify-end gap-2">
                        <button
                          onClick={() => handleAction(ref.id, "APPROVE")}
                          disabled={busyId !== null}
                          className="h-8 px-3 bg-primary-container text-on-primary font-button text-small rounded-lg hover:bg-primary transition-colors disabled:opacity-50"
                        >
                          {busyId === ref.id ? "Working..." : "Approve"}
                        </button>
                        <button
                          onClick={() => handleAction(ref.id, "REJECT")}
                          disabled={busyId !== null}
                          className="h-8 px-3 border border-border-base text-text-secondary font-button text-small rounded-lg hover:bg-surface-container-low transition-colors disabled:opacity-50"
                        >
                          Reject
                        </button>
                      </div>
                    ) : (
                      <span className="text-xs text-text-muted">{ref.processed_at ? formatDate(ref.processed_at) : "Closed"}</span>
                    )}
                  </td>
                </tr>
              ))}
              {refunds.length === 0 && (
                <tr>
                  <td colSpan={8} className="py-8 text-center text-text-muted">
                    {loading ? "Loading refund requests..." : "No refund requests."}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}
