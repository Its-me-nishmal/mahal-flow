"use client";

import { useEffect, useState } from "react";
import { PageHeader } from "@/components/ui/PageHeader";
import { MetricCard } from "@/components/ui/MetricCard";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { ApiClient } from "@/lib/api-client";
import { mockMahals } from "@/lib/mock-data";

export default function DashboardPage() {
  const [metrics, setMetrics] = useState({
    total_members: 4,
    paid_members: 1,
    pending_members: 3,
    total_pending_dues: 3000,
    total_collected_mtd: 85500,
    subscription_status: "ACTIVE",
  });
  const [dataSource, setDataSource] = useState<"mongodb" | "fallback_mock">("mongodb");

  useEffect(() => {
    ApiClient.getAdminDashboard("MH_001_CALICUT").then((res) => {
      setMetrics(res.data);
      setDataSource(res.source);
    });
  }, []);

  return (
    <>
      <PageHeader
        title="Platform Overview"
        description="Real-time metrics for all integrated Mahals and financial flow."
        actions={
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold bg-primary-light text-primary border border-border-base">
              <span className="w-2 h-2 rounded-full bg-success animate-pulse" />
              {dataSource === "mongodb" ? "Live MongoDB Active" : "Offline Fallback"}
            </div>
            <button className="px-4 py-2 bg-surface border border-primary text-primary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2 h-[44px]">
              <span className="material-symbols-outlined text-[18px]">download</span>
              Export Data
            </button>
          </div>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-gutter">
        <MetricCard
          icon="account_balance"
          iconBg="bg-info-bg"
          iconColor="text-info"
          label="Total Mahals"
          value="2"
          trend={{ value: "Live", positive: true }}
          footer={
            <div className="flex justify-between gap-2">
              <div className="text-center flex-1">
                <div className="font-small text-small text-success flex items-center justify-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-success" />
                  Active
                </div>
                <div className="font-button text-button text-text-primary">1</div>
              </div>
              <div className="w-px bg-border-base" />
              <div className="text-center flex-1">
                <div className="font-small text-small text-warning flex items-center justify-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-warning" />
                  Grace
                </div>
                <div className="font-button text-button text-text-primary">1</div>
              </div>
            </div>
          }
        />

        <MetricCard
          icon="payments"
          iconBg="bg-success-bg"
          iconColor="text-success"
          label="Total Mahal Collections (MTD)"
          value={`₹${(metrics.total_collected_mtd / 1000).toFixed(1)}k`}
          trend={{ value: "Live API", positive: true }}
          footer={
            <div className="flex justify-between gap-2">
              <div className="text-left">
                <div className="font-small text-small text-text-secondary">Pending Dues</div>
                <div className="font-button text-button text-error">₹{metrics.total_pending_dues}</div>
              </div>
              <div className="text-right">
                <div className="font-small text-small text-text-secondary">Paid Members</div>
                <div className="font-button text-button text-success font-semibold">{metrics.paid_members} / {metrics.total_members}</div>
              </div>
            </div>
          }
        />

        <MetricCard
          icon="volunteer_activism"
          iconBg="bg-surface-container-high"
          iconColor="text-primary"
          label="Total Members (MH_001)"
          value={metrics.total_members.toString()}
          trend={{ value: "MongoDB", positive: true }}
          footer={
            <div className="flex justify-between gap-2">
              <div className="text-left">
                <div className="font-small text-small text-text-secondary">Pending Collection</div>
                <div className="font-button text-button text-warning">{metrics.pending_members} Households</div>
              </div>
            </div>
          }
        />

        <MetricCard
          icon="monetization_on"
          iconBg="bg-primary"
          iconColor="text-on-primary"
          label="MahalFlow SaaS Status"
          value={metrics.subscription_status}
          trend={{ value: "Active", positive: true }}
          footer={
            <div className="flex justify-between gap-2">
              <div className="text-left">
                <div className="font-small text-small text-text-secondary">Monthly Plan</div>
                <div className="font-button text-button text-text-primary">₹499/mo</div>
              </div>
              <div className="text-right">
                <div className="font-small text-small text-text-secondary">AutoPay</div>
                <div className="font-button text-button text-success">Enabled</div>
              </div>
            </div>
          }
        />
      </div>

      {/* Recent Mahal Activity Table */}
      <div className="mt-8 bg-surface rounded-xl border border-border-base overflow-hidden shadow-sm">
        <div className="p-4 md:p-6 border-b border-border-base flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <h2 className="font-card-title text-card-title text-text-primary">Recent Mahal Activity</h2>
          <div className="flex items-center gap-2">
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                search
              </span>
              <input
                type="text"
                placeholder="Search by name or ID"
                className="pl-9 pr-3 py-1.5 text-sm bg-bg-app border border-border-base rounded-lg focus:outline-none focus:ring-1 focus:ring-primary w-48 lg:w-64"
              />
            </div>
            <button className="px-3 py-1.5 border border-border-base rounded-lg text-sm text-text-secondary hover:bg-surface-container-low flex items-center gap-1">
              <span className="material-symbols-outlined text-[16px]">filter_list</span>
              Filter
            </button>
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-bright border-b border-border-base text-text-secondary text-xs uppercase tracking-wider">
                <th className="py-3 px-4 font-semibold">Mahal Name</th>
                <th className="py-3 px-4 font-semibold">Status</th>
                <th className="py-3 px-4 font-semibold">Members</th>
                <th className="py-3 px-4 font-semibold">Collections (MTD)</th>
                <th className="py-3 px-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base text-sm">
              {mockMahals.slice(0, 5).map((mahal) => (
                <tr key={mahal.id} className="hover:bg-surface-container-low/50 transition-colors">
                  <td className="py-3 px-4">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-lg bg-primary-light text-primary flex items-center justify-center flex-shrink-0">
                        <span className="material-symbols-outlined text-[18px]">mosque</span>
                      </div>
                      <div>
                        <div className="font-semibold text-text-primary">{mahal.name}</div>
                        <div className="text-xs text-text-muted">ID: {mahal.id}</div>
                      </div>
                    </div>
                  </td>
                  <td className="py-3 px-4">
                    <StatusBadge status={mahal.status} />
                  </td>
                  <td className="py-3 px-4 font-medium text-text-primary">{mahal.members}</td>
                  <td className="py-3 px-4 font-semibold text-text-primary">{mahal.collections}</td>
                  <td className="py-3 px-4 text-right">
                    <button className="text-text-muted hover:text-text-primary p-1 rounded hover:bg-surface-variant/50">
                      <span className="material-symbols-outlined text-[18px]">more_vert</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}
