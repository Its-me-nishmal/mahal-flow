import { PageHeader } from "@/components/ui/PageHeader";

export default function FinancialReportsPage() {
  const recentPayments = [
    { name: "Rahul Sharma", amount: "₹1,500", status: "Paid", type: "Monthly Subscription" },
    { name: "Priya Patel", amount: "₹5,000", status: "Pending", type: "Donation" },
    { name: "Amit Kumar", amount: "₹1,500", status: "Failed", type: "Monthly Subscription" },
  ];

  return (
    <>
      <PageHeader
        title="Reports & Analytics"
        description="Financial overview and payment history across all Mahals."
        actions={
          <div className="flex gap-2">
            <button className="px-4 py-2 bg-surface border border-primary text-primary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2 h-[44px]">
              <span className="material-symbols-outlined text-[18px]">picture_as_pdf</span>
              Export PDF
            </button>
            <button className="px-4 py-2 bg-surface border border-primary text-primary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2 h-[44px]">
              <span className="material-symbols-outlined text-[18px]">download</span>
              Export Excel
            </button>
          </div>
        }
      />

      <div className="flex flex-wrap gap-3 mb-lg">
        <select className="h-10 px-3 rounded-lg border border-border-base bg-surface font-button text-small text-text-primary">
          <option>This Month</option>
          <option>Last Month</option>
          <option>Q3 2026</option>
          <option>Year to Date</option>
          <option>Custom</option>
        </select>
        <select className="h-10 px-3 rounded-lg border border-border-base bg-surface font-button text-small text-text-primary">
          <option>All Status</option>
          <option>Paid</option>
          <option>Pending</option>
          <option>Failed</option>
        </select>
        <select className="h-10 px-3 rounded-lg border border-border-base bg-surface font-button text-small text-text-primary">
          <option>All Types</option>
          <option>Subscription</option>
          <option>Donation</option>
          <option>Event Fee</option>
        </select>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-lg">
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <div className="flex justify-between items-start mb-2">
            <p className="font-small text-small text-text-secondary">Total Collected</p>
            <span className="flex items-center gap-1 text-success font-button text-small bg-success-bg px-2 py-1 rounded-full">
              <span className="material-symbols-outlined text-[14px]">trending_up</span>
              12.5%
            </span>
          </div>
          <h3 className="font-amount-lg text-amount-lg text-text-primary">₹1,45,000</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-2">Outstanding Dues</p>
          <h3 className="font-amount-lg text-amount-lg text-warning">₹24,500</h3>
          <p className="font-small text-small text-text-muted mt-1">48 Members</p>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-2">Payment Success Rate</p>
          <h3 className="font-amount-lg text-amount-lg text-info">94.2%</h3>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="lg:col-span-2 bg-surface border border-border-base rounded-xl p-lg shadow-sm">
          <h3 className="font-card-title text-card-title text-text-primary mb-lg">Revenue Trend</h3>
          <div className="flex items-end gap-3 h-48">
            {["Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct"].map((month, i) => {
              const heights = [60, 75, 45, 90, 80, 65, 95];
              return (
                <div key={month} className="flex-1 flex flex-col items-center gap-2">
                  <div className="w-full bg-primary-container/20 rounded-t-lg relative" style={{ height: `${heights[i]}%` }}>
                    <div className="absolute bottom-0 w-full bg-primary-container rounded-t-lg" style={{ height: "100%" }} />
                  </div>
                  <span className="font-small text-small text-text-muted">{month}</span>
                </div>
              );
            })}
          </div>
        </div>
        <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
          <h3 className="font-card-title text-card-title text-text-primary mb-lg">Recent Payments</h3>
          <div className="space-y-4">
            {recentPayments.map((p, i) => (
              <div key={i} className="flex items-center justify-between">
                <div>
                  <p className="font-button text-button text-text-primary">{p.name}</p>
                  <p className="font-small text-small text-text-muted">{p.type}</p>
                </div>
                <div className="text-right">
                  <p className="font-button text-button text-text-primary">{p.amount}</p>
                  <span
                    className={`font-small text-small ${
                      p.status === "Paid"
                        ? "text-success"
                        : p.status === "Pending"
                        ? "text-warning"
                        : "text-error"
                    }`}
                  >
                    {p.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}
