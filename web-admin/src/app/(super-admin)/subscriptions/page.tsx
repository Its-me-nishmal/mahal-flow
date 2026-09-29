"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { ErrorState } from "@/components/ui/States";
import { ApiClient } from "@/lib/api-client";
import { errorMessage, formatDate, formatINR, humanize } from "@/lib/format";

export default function SubscriptionManagementPage() {
  const [subscriptions, setSubscriptions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    setLoading(true);
    setError(null);
    ApiClient.getSubscriptions()
      .then((res) => setSubscriptions(res?.subscriptions || []))
      .catch((err) => setError(errorMessage(err, "Could not load subscriptions.")))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  // MRR counts billable (ACTIVE / GRACE_PERIOD) subscriptions at their recorded fee.
  const totalMRR = subscriptions
    .filter((s) => s.status === "ACTIVE" || s.status === "GRACE_PERIOD")
    .reduce((acc, sub) => acc + (Number(sub.monthly_fee) || 0), 0);
  const activeCount = subscriptions.filter((s) => s.status === "ACTIVE").length;
  const unpricedCount = subscriptions.filter((s) => !s.monthly_fee).length;
  const graceCount = subscriptions.filter((s) => s.status === "GRACE_PERIOD").length;

  return (
    <>
      <PageHeader title="Subscription Management" description="Platform subscription plan and status for every Mahal." />

      {error && <ErrorState message={error} onRetry={load} />}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-lg">
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Monthly Recurring Revenue (MRR)</p>
          <h3 className="font-amount-lg text-amount-lg text-text-primary">{formatINR(totalMRR)}</h3>
          <p className="font-small text-small text-text-muted mt-2">
            Across {subscriptions.length.toLocaleString("en-IN")} Mahals
            {unpricedCount > 0 ? ` · ${unpricedCount} without a fee set` : ""}
          </p>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Active Subscriptions</p>
          <h3 className="font-amount-lg text-amount-lg text-success">{activeCount}</h3>

        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">In Grace Period</p>
          <h3 className="font-amount-lg text-amount-lg text-warning">{graceCount}</h3>

        </div>
      </div>

      <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
        <div className="p-lg border-b border-border-base flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <h3 className="font-card-title text-card-title text-text-primary">Subscriptions</h3>
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
                      <Link href={`/mahals/${encodeURIComponent(sub.mahal_id)}`} className="font-button text-button text-text-primary hover:text-primary">
                        {sub.mahal_name || sub.mahal_id}
                      </Link>
                      <p className="font-small text-small text-text-muted">{sub.mahal_id}</p>
                    </div>
                  </td>
                  <td className="py-4 px-lg">
                    <p className="font-body text-body text-text-primary">{sub.plan ? humanize(sub.plan) : "No plan set"}</p>
                    <p className="font-small text-small text-text-muted">{sub.monthly_fee ? `${formatINR(sub.monthly_fee)}/month` : "No fee set"}</p>
                  </td>
                  <td className="py-4 px-lg"><StatusBadge status={sub.status} /></td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">
                    {formatDate(sub.next_billing_date)}
                  </td>
                </tr>
              ))}
              {subscriptions.length === 0 && (
                <tr>
                  <td colSpan={4} className="py-8 text-center text-text-muted">
                    {loading ? "Loading subscriptions..." : "No Mahals registered yet."}
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
