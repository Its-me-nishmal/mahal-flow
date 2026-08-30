"use client";

import { useEffect, useState } from "react";
import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { ApiClient } from "@/lib/api-client";

export default function RefundManagementPage() {
  const [refunds, setRefunds] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const loadRefunds = () => {
    ApiClient.getRefunds("MH_001_CALICUT")
      .then((res) => {
        if (res && res.refunds) {
          setRefunds(res.refunds);
        }
      })
      .catch((err) => console.error("Error loading refunds:", err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadRefunds();
  }, []);

  const handleAction = async (id: string, action: "APPROVE" | "REJECT") => {
    try {
      await ApiClient.processRefund(id, action, "MH_001_CALICUT");
      loadRefunds();
    } catch (err) {
      console.error("Failed to process refund:", err);
    }
  };

  const pendingCount = refunds.filter((r) => r.status === "PENDING").length;
  const approvedTotal = refunds
    .filter((r) => r.status === "APPROVED" || r.status === "PROCESSED")
    .reduce((sum, r) => sum + (r.amount || 0), 0);

  return (
    <>
      <PageHeader
        title="Refund Management"
        description="Monitor and process live member refund requests backed by MongoDB ledger."
      />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-lg">
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Total Refunded (Live)</p>
          <h3 className="font-amount-lg text-amount-lg text-text-primary">₹{approvedTotal.toLocaleString()}</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Pending Approvals</p>
          <h3 className="font-amount-lg text-amount-lg text-error">{pendingCount}</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Total Requests</p>
          <h3 className="font-amount-lg text-amount-lg text-success">{refunds.length}</h3>
        </div>
      </div>

      <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
        <div className="p-lg border-b border-border-base flex items-center justify-between">
          <h3 className="font-card-title text-card-title text-text-primary">Live Refund Queue</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low border-b border-border-base">
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">REFUND ID</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">MEMBER</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">AMOUNT</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">REASON</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">STATUS</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold text-right">ACTION</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base">
              {refunds.map((ref) => (
                <tr key={ref.id} className="hover:bg-surface-bright transition-colors">
                  <td className="py-4 px-lg font-button text-button text-text-primary">{ref.id}</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">{ref.member_name || ref.member_id}</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary font-semibold">₹{ref.amount}</td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary">{ref.reason || "Double debit"}</td>
                  <td className="py-4 px-lg"><StatusBadge status={ref.status} /></td>
                  <td className="py-4 px-lg text-right">
                    {ref.status === "PENDING" ? (
                      <div className="flex justify-end gap-2">
                        <button
                          onClick={() => handleAction(ref.id, "APPROVE")}
                          className="h-8 px-3 bg-primary-container text-on-primary font-button text-small rounded-lg hover:bg-primary transition-colors"
                        >
                          Approve
                        </button>
                        <button
                          onClick={() => handleAction(ref.id, "REJECT")}
                          className="h-8 px-3 border border-border-base text-text-secondary font-button text-small rounded-lg hover:bg-surface-container-low transition-colors"
                        >
                          Reject
                        </button>
                      </div>
                    ) : (
                      <span className="text-xs text-text-muted">Completed</span>
                    )}
                  </td>
                </tr>
              ))}
              {refunds.length === 0 && (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-text-muted">
                    {loading ? "Loading refund queue from live database..." : "No active refund disputes found."}
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
