import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";

export default function MahalDetailPage({ params }: { params: { id: string } }) {
  return (
    <>
      <PageHeader
        title="Mahal Details"
        description={`Overview of Mahal ${params.id}.`}
        actions={
          <div className="flex gap-2">
            <a
              href={`/mahals/${params.id}/edit`}
              className="px-4 py-2 bg-surface border border-primary text-primary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2 h-[44px]"
            >
              <span className="material-symbols-outlined text-[18px]">edit</span>
              Edit Details
            </a>
          </div>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Status</p>
          <div className="mt-1"><StatusBadge status="Active" /></div>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Members</p>
          <h3 className="font-amount-lg text-amount-lg text-text-primary">2,450</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Monthly Dues Rate</p>
          <h3 className="font-amount-lg text-amount-lg text-text-primary">₹500</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Collection (MTD)</p>
          <h3 className="font-amount-lg text-amount-lg text-success">₹8.4L</h3>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-lg">
        <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
          <h3 className="font-card-title text-card-title text-text-primary mb-lg">Organization Details</h3>
          <div className="space-y-4">
            {[
              ["Name", "Central Juma Masjid"],
              ["Registration", "REG-2024-8492"],
              ["Email", "admin@centraljuma.org"],
              ["Phone", "+91 98765 43210"],
              ["Currency", "INR (₹)"],
              ["Dunning", "Enabled"],
              ["AutoPay", "Allowed"],
            ].map(([label, value]) => (
              <div key={label} className="flex justify-between py-2 border-b border-border-base last:border-0">
                <span className="font-body text-body text-text-secondary">{label}</span>
                <span className="font-body text-body text-text-primary font-medium">{value}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
          <h3 className="font-card-title text-card-title text-text-primary mb-lg">Subscription</h3>
          <div className="space-y-4">
            {[
              ["Plan", "Premium Annual"],
              ["Monthly Fee", "₹999"],
              ["Status", "Active"],
              ["Next Billing", "Sep 30, 2026"],
            ].map(([label, value]) => (
              <div key={label} className="flex justify-between py-2 border-b border-border-base last:border-0">
                <span className="font-body text-body text-text-secondary">{label}</span>
                <span className="font-body text-body text-text-primary font-medium">{value}</span>
              </div>
            ))}
          </div>
          <div className="mt-lg pt-lg border-t border-border-base">
            <h4 className="font-card-title text-card-title text-text-primary mb-4">Recent Activity</h4>
            <div className="space-y-3">
              {[
                { member: "Mohammed Ali", amount: "₹1,500", status: "Success", date: "Aug 23" },
                { member: "Fatima Khan", amount: "₹500", status: "Pending", date: "Aug 22" },
                { member: "Syed Ali", amount: "₹1,500", status: "Success", date: "Aug 21" },
              ].map((txn, i) => (
                <div key={i} className="flex items-center justify-between">
                  <div>
                    <p className="font-button text-button text-text-primary">{txn.member}</p>
                    <p className="font-small text-small text-text-muted">{txn.date}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-button text-button text-text-primary">{txn.amount}</p>
                    <StatusBadge status={txn.status} />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
