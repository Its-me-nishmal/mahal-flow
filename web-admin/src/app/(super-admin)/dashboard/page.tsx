"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { PageHeader } from "@/components/ui/PageHeader";
import { MetricCard } from "@/components/ui/MetricCard";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { ShimmerSkeleton } from "@/components/ui/ShimmerSkeleton";
import { ErrorState } from "@/components/ui/States";
import { ApiClient, type Mahal } from "@/lib/api-client";
import { errorMessage, formatDateTime, formatINR, formatMonth, formatPhone } from "@/lib/format";

type Dashboard = Awaited<ReturnType<typeof ApiClient.getAdminDashboard>>;

export default function DashboardPage() {
  const [metrics, setMetrics] = useState<Dashboard | null>(null);
  const [mahals, setMahals] = useState<Mahal[] | null>(null);
  const [superAdmin, setSuperAdmin] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [mahalsError, setMahalsError] = useState<string | null>(null);
  const [updatedAt, setUpdatedAt] = useState<Date | null>(null);

  const loadData = useCallback(() => {
    const isSuper = ApiClient.isSuperAdmin();
    setSuperAdmin(isSuper);
    setLoading(true);
    setError(null);
    setMahalsError(null);
    Promise.allSettled([ApiClient.getAdminDashboard(), isSuper ? ApiClient.getMahals() : Promise.resolve(null)]).then(
      ([dash, list]) => {
        if (dash.status === "fulfilled") setMetrics(dash.value);
        else setError(errorMessage(dash.reason, "Could not load dashboard metrics."));
        if (list.status === "fulfilled") setMahals(list.value ? list.value.mahals || [] : null);
        else setMahalsError(errorMessage(list.reason, "Could not load Mahals."));
        setUpdatedAt(new Date());
        setLoading(false);
      }
    );
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const m = metrics;
  const paidPct = m && m.total_members > 0 ? Math.round((m.paid_members / m.total_members) * 100) : 0;
  const activeMahals = (mahals || []).filter((x) => x.subscription?.status === "ACTIVE").length;

  return (
    <>
      <PageHeader
        title={superAdmin ? "Platform Overview" : "Mahal Overview"}
        description={
          superAdmin
            ? "Collections and member health for your Mahal, plus every Mahal on the platform."
            : "Collections and member health for your Mahal."
        }
        actions={
          <div className="flex items-center gap-3">
            {updatedAt && !loading && <span className="text-xs text-text-muted">Updated {formatDateTime(updatedAt)}</span>}
            <button
              onClick={loadData}
              disabled={loading}
              className="px-3.5 py-2 bg-surface border border-border-base text-text-primary text-xs font-semibold rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-1.5 h-[38px] disabled:opacity-60"
            >
              <span className="material-symbols-outlined text-[16px]">refresh</span>
              Refresh
            </button>
          </div>
        }
      />

      {error && <ErrorState message={error} onRetry={loadData} />}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {loading ? (
          Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="bg-surface rounded-2xl border border-border-base p-5 space-y-3">
              <ShimmerSkeleton height={16} width={90} />
              <ShimmerSkeleton height={32} width={120} />
              <ShimmerSkeleton height={14} width="100%" />
            </div>
          ))
        ) : m ? (
          <>
            {superAdmin && mahals && (
              <MetricCard
                icon="account_balance"
                iconBg="bg-info-bg"
                iconColor="text-info"
                label="Registered Mahals"
                value={mahals.length.toLocaleString("en-IN")}
                footer={
                  <div className="flex justify-between items-center text-xs text-text-secondary pt-1">
                    <span>Active subscriptions</span>
                    <span className="font-bold text-success">{activeMahals.toLocaleString("en-IN")}</span>
                  </div>
                }
              />
            )}

            <MetricCard
              icon="payments"
              iconBg="bg-success-bg"
              iconColor="text-success"
              label={`Collected ${m.mtd_month ? formatMonth(m.mtd_month) : "this month"} (MTD)`}
              value={formatINR(m.total_collected_mtd || 0)}
              footer={
                <div className="space-y-1 pt-1">
                  <div className="flex justify-between items-center text-xs text-text-secondary">
                    <span>All-time collected</span>
                    <span className="font-bold text-text-primary">{formatINR(m.total_collected_all_time || 0)}</span>
                  </div>
                  <div className="flex justify-between items-center text-xs text-text-secondary">
                    <span>Paid-up members</span>
                    <span className="font-bold text-success">
                      {m.paid_members.toLocaleString("en-IN")} / {m.total_members.toLocaleString("en-IN")} ({paidPct}%)
                    </span>
                  </div>
                </div>
              }
            />

            <MetricCard
              icon="group"
              iconBg="bg-surface-container-high"
              iconColor="text-primary"
              label="Registered Members"
              value={m.total_members.toLocaleString("en-IN")}
              footer={
                <div className="flex justify-between items-center text-xs text-text-secondary pt-1">
                  <span>With dues outstanding</span>
                  <span className="font-bold text-warning">{m.pending_members.toLocaleString("en-IN")}</span>
                </div>
              }
            />

            <MetricCard
              icon="schedule"
              iconBg="bg-warning-bg"
              iconColor="text-warning"
              label="Pending Dues Balance"
              value={formatINR(m.total_pending_dues || 0)}
              footer={
                <div className="flex justify-between items-center text-xs text-text-secondary pt-1">
                  <span>Subscription</span>
                  <StatusBadge status={m.subscription_status} />
                </div>
              }
            />
          </>
        ) : null}
      </div>

      {superAdmin && (
        <div className="bg-surface border border-border-base rounded-2xl overflow-hidden shadow-sm">
          <div className="p-5 border-b border-border-base flex items-center justify-between">
            <h3 className="font-card-title text-base font-bold text-text-primary">Mahals on the Platform</h3>
            <Link href="/mahals" className="text-xs font-semibold text-primary hover:underline">
              View all
            </Link>
          </div>
          {mahalsError ? (
            <div className="p-5">
              <ErrorState message={mahalsError} onRetry={loadData} />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-surface-container-low/70 border-b border-border-base">
                    {["MAHAL NAME", "REGISTRATION", "CONTACT PHONE", "DEFAULT DUES", "SUBSCRIPTION"].map((h) => (
                      <th key={h} className="text-xs font-bold text-text-secondary py-3 px-5">
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-border-base">
                  {loading || !mahals ? (
                    Array.from({ length: 3 }).map((_, i) => (
                      <tr key={i}>
                        <td colSpan={5} className="py-4 px-5">
                          <ShimmerSkeleton height={20} className="w-full" />
                        </td>
                      </tr>
                    ))
                  ) : mahals.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="py-12 text-center text-text-muted text-sm">
                        No Mahals registered yet.
                      </td>
                    </tr>
                  ) : (
                    mahals.map((mahal) => (
                      <tr key={mahal.id} className="hover:bg-surface-bright transition-colors">
                        <td className="py-3.5 px-5 text-sm font-semibold text-text-primary">
                          <Link href={`/mahals/${encodeURIComponent(mahal.id)}`} className="hover:text-primary">
                            {mahal.name || mahal.id}
                          </Link>
                        </td>
                        <td className="py-3.5 px-5 font-mono text-xs text-text-secondary">{mahal.registration_number || "—"}</td>
                        <td className="py-3.5 px-5 text-xs text-text-secondary">{formatPhone(mahal.contact?.phone)}</td>
                        <td className="py-3.5 px-5 text-sm text-text-primary font-bold">{formatINR(mahal.settings?.default_monthly_dues ?? 0)}</td>
                        <td className="py-3.5 px-5">
                          <StatusBadge status={mahal.subscription?.status} />
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </>
  );
}
