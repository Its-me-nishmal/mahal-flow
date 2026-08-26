import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { mockSubscriptions } from "@/lib/mock-data";

export default function SubscriptionManagementPage() {
  return (
    <>
      <PageHeader title="Subscription Management" description="Manage Mahal subscription plans and billing." />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Monthly Recurring Revenue</p>
          <h3 className="font-amount-lg text-amount-lg text-text-primary">₹1,24,750</h3>
          <p className="font-small text-small text-text-muted mt-2">From 250 active subscriptions</p>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Active Mahals</p>
          <h3 className="font-amount-lg text-amount-lg text-success">250</h3>
          <p className="font-small text-small text-success mt-2">98% AutoPay Enabled</p>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Pending Renewals</p>
          <h3 className="font-amount-lg text-amount-lg text-error">12</h3>
          <p className="font-small text-small text-error mt-2">Requires attention this week</p>
        </div>
      </div>

      <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
        <div className="p-lg border-b border-border-base flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <h3 className="font-card-title text-card-title text-text-primary">Mahal Subscriptions</h3>
          <div className="flex gap-2">
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">search</span>
              <input className="pl-9 pr-4 py-2 border border-border-base rounded-lg text-body font-body w-full sm:w-64 h-[44px] focus:border-primary focus:ring-0 outline-none" placeholder="Search subscriptions..." type="text" />
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
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">MAHAL</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">PLAN & BILLING</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">STATUS</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">RENEWAL DATE</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold text-right">ACTIONS</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base">
              {mockSubscriptions.map((sub) => (
                <tr key={sub.id} className="hover:bg-surface-bright transition-colors">
                  <td className="py-4 px-lg">
                    <div>
                      <p className="font-button text-button text-text-primary">{sub.mahal}</p>
                      <p className="font-small text-small text-text-muted">{sub.id}</p>
                    </div>
                  </td>
                  <td className="py-4 px-lg">
                    <p className="font-body text-body text-text-primary">{sub.plan}</p>
                    <p className="font-small text-small text-text-muted">{sub.payment}</p>
                  </td>
                  <td className="py-4 px-lg"><StatusBadge status={sub.status} /></td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">{sub.renewal}</td>
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
      </div>
    </>
  );
}
