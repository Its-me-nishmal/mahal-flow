import { PageHeader } from "@/components/ui/PageHeader";
import { mockTransactions } from "@/lib/mock-data";
import { StatusBadge } from "@/components/ui/StatusBadge";

export default function RefundManagementPage() {
  return (
    <>
      <PageHeader
        title="Refund Management"
        description="Monitor and process refund requests across all Mahals."
        actions={
          <button className="px-4 py-2 bg-surface border border-primary text-primary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2 h-[44px]">
            <span className="material-symbols-outlined text-[18px]">download</span>
            Export CSV
          </button>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Total Refunded (MTD)</p>
          <h3 className="font-amount-lg text-amount-lg text-text-primary">₹1,45,000</h3>
          <p className="font-small text-small text-text-muted mt-2">12% vs last month</p>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Pending Approvals</p>
          <h3 className="font-amount-lg text-amount-lg text-error">42</h3>
          <p className="font-small text-small text-error mt-2">Requires immediate attention</p>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Refund Success Rate</p>
          <h3 className="font-amount-lg text-amount-lg text-success">98.5%</h3>
          <p className="font-small text-small text-text-muted mt-2">Last 30 days average</p>
        </div>
      </div>

      <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
        <div className="p-lg border-b border-border-base flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex gap-2">
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                search
              </span>
              <input
                className="pl-9 pr-4 py-2 border border-border-base rounded-lg text-body font-body w-full sm:w-64 h-[44px] focus:border-primary focus:ring-0 outline-none"
                placeholder="Search by ID or Mahal..."
                type="text"
              />
            </div>
            <select className="h-[44px] px-3 border border-border-base rounded-lg text-text-secondary bg-surface font-button text-small">
              <option>All Status</option>
              <option>Pending</option>
              <option>Successful</option>
              <option>Failed</option>
            </select>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low border-b border-border-base">
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">TXN ID</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">MAHAL</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">MEMBER</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">AMOUNT</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">DATE</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">STATUS</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold text-right">ACTIONS</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base">
              {mockTransactions.map((txn) => (
                <tr key={txn.id} className="hover:bg-surface-bright transition-colors">
                  <td className="py-4 px-lg font-button text-button text-text-primary">{txn.id}</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">{txn.mahal}</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">{txn.member}</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">{txn.amount}</td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary">{txn.date}</td>
                  <td className="py-4 px-lg"><StatusBadge status={txn.status} /></td>
                  <td className="py-4 px-lg text-right">
                    {txn.status === "Pending" ? (
                      <button className="h-8 px-3 bg-primary-container text-on-primary font-button text-small rounded-lg hover:bg-primary transition-colors">
                        Process Refund
                      </button>
                    ) : txn.status === "Failed" ? (
                      <button className="h-8 px-3 border border-border-base text-text-secondary font-button text-small rounded-lg hover:bg-surface-container-low transition-colors">
                        Retry
                      </button>
                    ) : (
                      <button className="text-text-secondary hover:text-primary p-2 rounded-lg hover:bg-surface-container-low transition-colors">
                        <span className="material-symbols-outlined">visibility</span>
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="p-md border-t border-border-base flex items-center justify-between bg-surface-container-lowest">
          <p className="font-small text-small text-text-secondary">Showing 1 to 4 of 128 results</p>
          <div className="flex gap-1">
            <button className="h-8 px-3 bg-primary-container text-on-primary font-button text-small rounded-lg">1</button>
            <button className="h-8 px-3 text-text-secondary hover:bg-surface-container-low font-button text-small rounded-lg">2</button>
            <button className="h-8 px-3 text-text-secondary hover:bg-surface-container-low font-button text-small rounded-lg">3</button>
          </div>
        </div>
      </div>
    </>
  );
}
