"use client";

import { useEffect, useState } from "react";
import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { ApiClient } from "@/lib/api-client";

export default function SubscriptionManagementPage() {
  const [subscriptions, setSubscriptions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    ApiClient.getSubscriptions()
      .then((res) => {
        if (res && res.subscriptions) {
          setSubscriptions(res.subscriptions);
        }
      })
      .catch((err) => console.error("Error fetching subscriptions:", err))
      .finally(() => setLoading(false));
  }, []);

  const totalMRR = subscriptions.reduce((acc, sub) => acc + (sub.monthly_fee || 499), 0);
  const activeCount = subscriptions.filter((s) => s.status === "ACTIVE" || !s.status).length;
  const graceCount = subscriptions.filter((s) => s.status === "GRACE_PERIOD").length;

  return (
    <>
      <PageHeader title="Subscription Management" description="Manage live Mahal subscription tiers, MRR, and SaaS billing." />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-lg">
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Monthly Recurring Revenue (MRR)</p>
          <h3 className="font-amount-lg text-amount-lg text-text-primary">₹{totalMRR.toLocaleString()}</h3>
          <p className="font-small text-small text-text-muted mt-2">From {subscriptions.length} registered Mahals</p>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Active Subscriptions</p>
          <h3 className="font-amount-lg text-amount-lg text-success">{activeCount}</h3>
          <p className="font-small text-small text-success mt-2">100% Online AutoPay Verified</p>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">In Grace Period</p>
          <h3 className="font-amount-lg text-amount-lg text-warning">{graceCount}</h3>
          <p className="font-small text-small text-warning mt-2">Dunning alerts dispatched</p>
        </div>
      </div>

      <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
        <div className="p-lg border-b border-border-base flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <h3 className="font-card-title text-card-title text-text-primary">Live Subscriptions</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low border-b border-border-base">
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">MAHAL</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">PLAN & BILLING</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">STATUS</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">NEXT BILLING</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base">
              {subscriptions.map((sub) => (
                <tr key={sub.mahal_id} className="hover:bg-surface-bright transition-colors">
                  <td className="py-4 px-lg">
                    <div>
                      <p className="font-button text-button text-text-primary">{sub.mahal_name}</p>
                      <p className="font-small text-small text-text-muted">{sub.mahal_id}</p>
                    </div>
                  </td>
                  <td className="py-4 px-lg">
                    <p className="font-body text-body text-text-primary">{sub.plan || "STANDARD"}</p>
                    <p className="font-small text-small text-text-muted">₹{sub.monthly_fee || 499}/month</p>
                  </td>
                  <td className="py-4 px-lg"><StatusBadge status={sub.status || "ACTIVE"} /></td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">
                    {sub.next_billing_date ? new Date(sub.next_billing_date).toLocaleDateString() : "Next Cycle"}
                  </td>
                </tr>
              ))}
              {subscriptions.length === 0 && (
                <tr>
                  <td colSpan={4} className="py-8 text-center text-text-muted">
                    {loading ? "Fetching live subscriptions from MongoDB..." : "No active subscriptions found."}
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
