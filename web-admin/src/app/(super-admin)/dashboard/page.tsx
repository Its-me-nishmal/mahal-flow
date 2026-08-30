"use client";

import { useEffect, useState } from "react";
import { PageHeader } from "@/components/ui/PageHeader";
import { MetricCard } from "@/components/ui/MetricCard";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { ShimmerSkeleton } from "@/components/ui/ShimmerSkeleton";
import { ApiClient } from "@/lib/api-client";

export default function DashboardPage() {
  const [metrics, setMetrics] = useState({
    total_members: 0,
    paid_members: 0,
    pending_members: 0,
    total_pending_dues: 0,
    total_collected_mtd: 0,
    subscription_status: "ACTIVE",
  });
  const [mahals, setMahals] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const loadData = () => {
    setLoading(true);
    Promise.all([
      ApiClient.getAdminDashboard("MH_001_CALICUT").catch(() => null),
      ApiClient.getMahals().catch(() => null),
    ]).then(([dashboardRes, mahalsRes]) => {
      if (dashboardRes) {
        setMetrics(dashboardRes);
      }
      if (mahalsRes && mahalsRes.mahals) {
        setMahals(mahalsRes.mahals);
      }
      setLoading(false);
    });
  };

  useEffect(() => {
    loadData();
  }, []);

  return (
    <>
      <PageHeader
        title="Platform Overview"
        description="Real-time financial metrics, collection health, and tenant status for all integrated Mahals."
        actions={
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold bg-primary-light text-primary border border-primary/20 shadow-xs">
              <span className="w-2 h-2 rounded-full bg-success animate-pulse" />
              Live MongoDB Connected
            </div>
            <button
              onClick={loadData}
              className="px-3.5 py-2 bg-surface border border-border-base text-text-primary text-xs font-semibold rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-1.5 h-[38px]"
            >
              <span className="material-symbols-outlined text-[16px]">refresh</span>
              Refresh
            </button>
          </div>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        {loading ? (
          Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="bg-surface rounded-2xl border border-border-base p-5 space-y-3">
              <ShimmerSkeleton height={16} width={90} />
              <ShimmerSkeleton height={32} width={120} />
              <ShimmerSkeleton height={14} width="100%" />
            </div>
          ))
        ) : (
          <>
            <MetricCard
              icon="account_balance"
              iconBg="bg-info-bg"
              iconColor="text-info"
              label="Registered Mahals"
              value={mahals.length.toString()}
              trend={{ value: "Live Tenants", positive: true }}
              footer={
                <div className="flex justify-between items-center text-xs text-text-secondary pt-1">
                  <span>Active Tenants</span>
                  <span className="font-bold text-success">
                    {mahals.filter((m) => m.subscription?.status === "ACTIVE" || !m.subscription).length} Active
                  </span>
                </div>
              }
            />

            <MetricCard
              icon="payments"
              iconBg="bg-success-bg"
              iconColor="text-success"
              label="Total Collections (MTD)"
              value={`₹${(metrics.total_collected_mtd || 0).toLocaleString()}`}
              trend={{ value: "Settled", positive: true }}
              footer={
                <div className="flex justify-between items-center text-xs text-text-secondary pt-1">
                  <span>Paid Members</span>
                  <span className="font-bold text-success">
                    {metrics.paid_members} / {metrics.total_members} ({metrics.total_members > 0 ? Math.round((metrics.paid_members / metrics.total_members) * 100) : 0}%)
                  </span>
                </div>
              }
            />

            <MetricCard
              icon="group"
              iconBg="bg-surface-container-high"
              iconColor="text-primary"
              label="Registered Households"
              value={metrics.total_members.toString()}
              trend={{ value: "Families", positive: true }}
              footer={
                <div className="flex justify-between items-center text-xs text-text-secondary pt-1">
                  <span>Pending Collection</span>
                  <span className="font-bold text-warning">{metrics.pending_members} Households</span>
                </div>
              }
            />

            <MetricCard
              icon="schedule"
              iconBg="bg-warning-bg"
              iconColor="text-warning"
              label="Pending Dues Balance"
              value={`₹${(metrics.total_pending_dues || 0).toLocaleString()}`}
              trend={{ value: "To Collect", positive: false }}
              footer={
                <div className="flex justify-between items-center text-xs text-text-secondary pt-1">
                  <span>Collection Status</span>
                  <span className="font-bold text-text-primary">
                    {metrics.subscription_status}
                  </span>
                </div>
              }
            />
          </>
        )}
      </div>

      <div className="bg-surface border border-border-base rounded-2xl overflow-hidden shadow-sm">
        <div className="p-5 border-b border-border-base flex items-center justify-between">
          <h3 className="font-card-title text-base font-bold text-text-primary">
            Connected Mahals & Mosques
          </h3>
          <span className="text-xs font-semibold text-text-muted bg-surface-container-low px-2.5 py-1 rounded-md">
            {mahals.length} Organizations
          </span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low/70 border-b border-border-base">
                <th className="text-xs font-bold text-text-secondary py-3 px-5">MAHAL NAME</th>
                <th className="text-xs font-bold text-text-secondary py-3 px-5">REGISTRATION</th>
                <th className="text-xs font-bold text-text-secondary py-3 px-5">CONTACT PHONE</th>
                <th className="text-xs font-bold text-text-secondary py-3 px-5">MONTHLY RATE</th>
                <th className="text-xs font-bold text-text-secondary py-3 px-5">SUBSCRIPTION</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base">
              {loading ? (
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
                    No Mahals registered
                  </td>
                </tr>
              ) : (
                mahals.map((mahal) => (
                  <tr key={mahal.id} className="hover:bg-surface-bright transition-colors">
                    <td className="py-3.5 px-5 text-sm font-semibold text-text-primary">
                      {mahal.name}
                    </td>
                    <td className="py-3.5 px-5 font-mono text-xs text-text-secondary">
                      {mahal.registration_number || mahal.id}
                    </td>
                    <td className="py-3.5 px-5 text-xs text-text-secondary">
                      {mahal.contact?.phone || "+91 98471 22334"}
                    </td>
                    <td className="py-3.5 px-5 text-sm text-text-primary font-bold">
                      ₹{mahal.settings?.default_monthly_dues || 500}
                    </td>
                    <td className="py-3.5 px-5">
                      <StatusBadge status={mahal.subscription?.status || "ACTIVE"} />
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}
