import { PageHeader } from "@/components/ui/PageHeader";
import { MetricCard } from "@/components/ui/MetricCard";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { mockMahals } from "@/lib/mock-data";

export default function DashboardPage() {
  return (
    <>
      <PageHeader
        title="Platform Overview"
        description="Real-time metrics for all integrated Mahals and financial flow."
        actions={
          <button className="px-4 py-2 bg-surface border border-primary text-primary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2 h-[44px]">
            <span className="material-symbols-outlined text-[18px]">download</span>
            Export Data
          </button>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-gutter">
        <MetricCard
          icon="account_balance"
          iconBg="bg-info-bg"
          iconColor="text-info"
          label="Total Mahals"
          value="1,248"
          trend={{ value: "12%", positive: true }}
          footer={
            <div className="flex justify-between gap-2">
              <div className="text-center flex-1">
                <div className="font-small text-small text-success flex items-center justify-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-success" />
                  Active
                </div>
                <div className="font-button text-button text-text-primary">1,102</div>
              </div>
              <div className="w-px bg-border-base" />
              <div className="text-center flex-1">
                <div className="font-small text-small text-warning flex items-center justify-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-warning" />
                  Grace
                </div>
                <div className="font-button text-button text-text-primary">94</div>
              </div>
            </div>
          }
        />

        <MetricCard
          icon="payments"
          iconBg="bg-success-bg"
          iconColor="text-success"
          label="Total Mahal Collections (MTD)"
          value="₹4.2Cr"
          trend={{ value: "8%", positive: true }}
          footer={
            <div className="flex justify-between gap-2">
              <div className="text-left">
                <div className="font-small text-small text-text-secondary">Expected</div>
                <div className="font-button text-button text-text-primary">₹4.5Cr</div>
              </div>
              <div className="text-right">
                <div className="font-small text-small text-text-secondary">Recovery Rate</div>
                <div className="font-button text-button text-success">93.3%</div>
              </div>
            </div>
          }
        />

        <MetricCard
          icon="volunteer_activism"
          iconBg="bg-secondary-container"
          iconColor="text-secondary"
          label="Total Contributions (MTD)"
          value="₹85L"
          trend={{ value: "2%", positive: false }}
          footer={
            <div>
              <div className="w-full bg-surface-container-low rounded-full h-1.5 mb-2">
                <div className="bg-secondary h-1.5 rounded-full" style={{ width: "75%" }} />
              </div>
              <div className="flex justify-between text-small font-small">
                <span className="text-text-secondary">75% of goal</span>
                <span className="text-text-secondary">Goal: ₹1.1Cr</span>
              </div>
            </div>
          }
        />

        <MetricCard
          icon="monetization_on"
          iconBg="bg-primary-container"
          iconColor="text-on-primary-container"
          label="MahalFlow Revenue (MTD)"
          value="₹12.5L"
          gradient
          footer={
            <div className="flex justify-between gap-2">
              <div className="text-left">
                <div className="font-small text-small text-text-secondary">Platform Fees</div>
                <div className="font-button text-button text-text-primary">₹8.2L</div>
              </div>
              <div className="text-right">
                <div className="font-small text-small text-text-secondary">Gateway Markup</div>
                <div className="font-button text-button text-text-primary">₹4.3L</div>
              </div>
            </div>
          }
        />
      </div>

      <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
        <div className="p-lg border-b border-border-base flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <h3 className="font-card-title text-card-title text-text-primary">
            Recent Mahal Activity
          </h3>
          <div className="flex gap-2">
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                search
              </span>
              <input
                className="pl-9 pr-4 py-2 border border-border-base rounded-lg text-body font-body w-full sm:w-64 h-[44px] focus:border-primary focus:ring-0 outline-none"
                placeholder="Search by name or ID"
                type="text"
              />
            </div>
            <button className="h-[44px] px-3 border border-border-base rounded-lg text-text-secondary hover:bg-surface-container-low transition-colors flex items-center justify-center">
              <span className="material-symbols-outlined">filter_list</span>
            </button>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low border-b border-border-base">
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  MAHAL NAME
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  STATUS
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  MEMBERS
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  COLLECTIONS (MTD)
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap text-right">
                  ACTIONS
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base">
              {mockMahals.slice(0, 4).map((mahal) => (
                <tr key={mahal.id} className="hover:bg-surface-bright transition-colors group">
                  <td className="py-4 px-lg">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-lg bg-surface-container flex items-center justify-center shrink-0 border border-border-base">
                        <span className="material-symbols-outlined text-text-secondary text-[20px]">
                          mosque
                        </span>
                      </div>
                      <div>
                        <p className="font-button text-button text-text-primary">
                          {mahal.name}
                        </p>
                        <p className="font-small text-small text-text-muted">
                          ID: {mahal.id}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="py-4 px-lg">
                    <StatusBadge status={mahal.status} />
                  </td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">
                    {mahal.members.toLocaleString()}
                  </td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">
                    {mahal.collections}
                  </td>
                  <td className="py-4 px-lg text-right">
                    <button className="text-text-secondary hover:text-primary p-2 rounded-lg hover:bg-surface-container-low transition-colors">
                      <span className="material-symbols-outlined">more_vert</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="p-md border-t border-border-base flex justify-center bg-surface-container-lowest">
          <a href="/mahals" className="text-primary font-button text-button hover:underline">
            View All Mahals
          </a>
        </div>
      </div>
    </>
  );
}
