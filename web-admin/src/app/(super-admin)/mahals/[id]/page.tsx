"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { ErrorState, LoadingBlock } from "@/components/ui/States";
import { ApiClient, type Mahal, type MahalStats } from "@/lib/api-client";
import { errorMessage, formatDate, formatDateTime, formatINR, formatMonth, formatPhone, humanize } from "@/lib/format";

function Row({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex justify-between gap-4 py-2 border-b border-border-base last:border-0">
      <span className="font-body text-body text-text-secondary">{label}</span>
      <span className="font-body text-body text-text-primary font-medium text-right break-words min-w-0">{value}</span>
    </div>
  );
}

function Stat({ label, value, tone }: { label: string; value: React.ReactNode; tone?: string }) {
  return (
    <div className="bg-surface rounded-xl border border-border-base p-lg">
      <p className="font-small text-small text-text-secondary mb-1">{label}</p>
      <h3 className={`font-amount-lg text-amount-lg ${tone || "text-text-primary"}`}>{value}</h3>
    </div>
  );
}

export default function MahalDetailPage() {
  const { id } = useParams<{ id: string }>();
  const mahalId = decodeURIComponent(id);
  const [mahal, setMahal] = useState<Mahal | null>(null);
  const [stats, setStats] = useState<MahalStats | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [statsError, setStatsError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(() => {
    setLoading(true);
    setError(null);
    setStatsError(null);
    Promise.allSettled([ApiClient.getMahal(mahalId), ApiClient.getMahalStats(mahalId)]).then(([m, s]) => {
      if (m.status === "fulfilled") setMahal(m.value);
      else setError(errorMessage(m.reason, "Could not load this Mahal."));
      if (s.status === "fulfilled") setStats(s.value);
      else setStatsError(errorMessage(s.reason, "Could not load statistics."));
      setLoading(false);
    });
  }, [mahalId]);

  useEffect(() => {
    load();
  }, [load]);

  if (loading && !mahal) {
    return (
      <>
        <PageHeader title="Mahal Details" description={mahalId} />
        <LoadingBlock rows={8} />
      </>
    );
  }
  if (error || !mahal) {
    return (
      <>
        <PageHeader title="Mahal Details" description={mahalId} />
        <ErrorState message={error || "Mahal not found."} onRetry={load} />
      </>
    );
  }

  const recent = stats?.recent_payments || [];

  return (
    <>
      <PageHeader
        title={mahal.name || "Mahal Details"}
        description={`Mahal ID ${mahal.id}`}
        actions={
          <div className="flex gap-2">
            <button
              onClick={load}
              disabled={loading}
              className="px-3 py-2 bg-surface border border-border-base text-text-primary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2 h-[44px] disabled:opacity-60"
            >
              <span className="material-symbols-outlined text-[18px]">refresh</span>
              Refresh
            </button>
            <Link
              href={`/mahals/${encodeURIComponent(mahal.id)}/edit`}
              className="px-4 py-2 bg-surface border border-primary text-primary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2 h-[44px]"
            >
              <span className="material-symbols-outlined text-[18px]">edit</span>
              Edit Details
            </Link>
          </div>
        }
      />

      {statsError && <ErrorState title="Statistics unavailable" message={statsError} onRetry={load} />}

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Subscription Status</p>
          <div className="mt-1">
            <StatusBadge status={mahal.subscription?.status} />
          </div>
        </div>
        <Stat label="Members" value={stats ? stats.total_members.toLocaleString("en-IN") : "—"} />
        <Stat label="Default Monthly Dues" value={formatINR(mahal.settings?.default_monthly_dues ?? 0)} />
        <Stat
          label={`Collected ${stats ? formatMonth(stats.mtd_month) : "this month"} (MTD)`}
          value={stats ? formatINR(stats.collected_mtd) : "—"}
          tone="text-success"
        />
      </div>

      {stats && (
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <Stat label="Paid-up Members" value={`${stats.paid_members.toLocaleString("en-IN")} / ${stats.total_members.toLocaleString("en-IN")}`} />
          <Stat label="Pending Dues Balance" value={formatINR(stats.total_pending_dues)} tone="text-warning" />
          <Stat label="Collected All Time" value={formatINR(stats.collected_all_time)} />
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-lg">
        <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
          <h3 className="font-card-title text-card-title text-text-primary mb-lg">Organization Details</h3>
          <Row label="Name" value={mahal.name || "—"} />
          <Row label="Registration" value={mahal.registration_number || "—"} />
          <Row label="Email" value={mahal.contact?.email || "—"} />
          <Row label="Phone" value={formatPhone(mahal.contact?.phone)} />
          <Row label="WhatsApp" value={formatPhone(mahal.contact?.whatsapp)} />
          <Row label="Address" value={mahal.contact?.address || "—"} />
          <Row label="Currency" value={mahal.settings?.currency || "INR"} />
          <Row label="Dunning" value={mahal.settings?.dunning_enabled ? "Enabled" : "Disabled"} />
          <Row label="AutoPay" value={mahal.settings?.autopay_allowed ? "Allowed" : "Not allowed"} />
          <Row label="Registered" value={formatDate(mahal.created_at)} />
        </div>

        <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
          <h3 className="font-card-title text-card-title text-text-primary mb-lg">Subscription</h3>
          <Row label="Plan" value={mahal.subscription?.plan ? humanize(mahal.subscription.plan) : "—"} />
          <Row label="Monthly Fee" value={mahal.subscription?.monthly_fee ? formatINR(mahal.subscription.monthly_fee) : "—"} />
          <Row label="Status" value={<StatusBadge status={mahal.subscription?.status} />} />
          <Row label="Next Billing" value={formatDate(mahal.subscription?.next_billing_date)} />
          {mahal.subscription?.grace_period_ends_at && (
            <Row label="Grace Period Ends" value={formatDate(mahal.subscription.grace_period_ends_at)} />
          )}

          <div className="mt-lg pt-lg border-t border-border-base">
            <h4 className="font-card-title text-card-title text-text-primary mb-4">Recent Payments</h4>
            {!stats ? (
              <p className="text-sm text-text-muted">—</p>
            ) : recent.length === 0 ? (
              <p className="text-sm text-text-muted">No payments recorded for this Mahal yet.</p>
            ) : (
              <div className="space-y-3">
                {recent.map((p) => (
                  <div key={p.id} className="flex items-center justify-between gap-3">
                    <div className="min-w-0">
                      <p className="font-button text-button text-text-primary truncate">{p.member_name || p.member_id || "—"}</p>
                      <p className="font-small text-small text-text-muted">
                        {formatDateTime(p.completed_at || p.created_at)} · {humanize(p.type)}
                      </p>
                    </div>
                    <div className="text-right shrink-0">
                      <p className="font-button text-button text-text-primary">{formatINR(p.amount)}</p>
                      <StatusBadge status={p.status} />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </>
  );
}
