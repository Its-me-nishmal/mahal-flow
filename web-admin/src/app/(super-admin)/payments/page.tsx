import { PageHeader } from "@/components/ui/PageHeader";
import { mockTransactions } from "@/lib/mock-data";
import { StatusBadge } from "@/components/ui/StatusBadge";

export default function PaymentsPage() {
  return (
    <>
      <PageHeader
        title="Payments"
        description="View all transactions across the platform."
      />

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-lg">
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Total Transactions</p>
          <h3 className="font-amount-lg text-amount-lg text-text-primary">12,458</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Successful</p>
          <h3 className="font-amount-lg text-amount-lg text-success">11,892</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Pending</p>
          <h3 className="font-amount-lg text-amount-lg text-warning">342</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Failed</p>
          <h3 className="font-amount-lg text-amount-lg text-error">224</h3>
        </div>
      </div>

      <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
        <div className="p-lg border-b border-border-base flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <h3 className="font-card-title text-card-title text-text-primary">All Transactions</h3>
          <div className="flex gap-2">
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">search</span>
              <input className="pl-9 pr-4 py-2 border border-border-base rounded-lg text-body font-body w-full sm:w-64 h-[44px] focus:border-primary focus:ring-0 outline-none" placeholder="Search transactions..." type="text" />
            </div>
            <select className="h-[44px] px-3 border border-border-base rounded-lg text-text-secondary bg-surface font-button text-small">
              <option>All Status</option>
              <option>Success</option>
              <option>Pending</option>
              <option>Failed</option>
              <option>Refunded</option>
            </select>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low border-b border-border-base">
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">TXN ID</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">MEMBER</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">MAHAL</th>
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
                  <td className="py-4 px-lg font-body text-body text-text-primary">{txn.member}</td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary">{txn.mahal}</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">{txn.amount}</td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary">{txn.date}</td>
                  <td className="py-4 px-lg"><StatusBadge status={txn.status} /></td>
                  <td className="py-4 px-lg text-right">
                    <button className="text-text-secondary hover:text-primary p-2 rounded-lg hover:bg-surface-container-low transition-colors">
                      <span className="material-symbols-outlined">visibility</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="p-md border-t border-border-base flex items-center justify-between bg-surface-container-lowest">
          <p className="font-small text-small text-text-secondary">Showing 1 to 6 of 12,458 results</p>
          <div className="flex gap-1">
            <button className="h-8 px-3 bg-primary-container text-on-primary font-button text-small rounded-lg">1</button>
            <button className="h-8 px-3 text-text-secondary hover:bg-surface-container-low font-button text-small rounded-lg">2</button>
            <button className="h-8 px-3 text-text-secondary hover:bg-surface-container-low font-button text-small rounded-lg">3</button>
            <span className="h-8 px-2 text-text-muted font-button text-small flex items-center">...</span>
            <button className="h-8 px-3 text-text-secondary hover:bg-surface-container-low font-button text-small rounded-lg">2077</button>
          </div>
        </div>
      </div>
    </>
  );
}
