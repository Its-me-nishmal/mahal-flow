import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";

export default function MemberDetailPage({ params }: { params: { id: string } }) {
  return (
    <>
      <PageHeader
        title="Member Details"
        description={`Profile for member ${params.id}.`}
        actions={
          <a
            href={`/members/${params.id}/edit`}
            className="px-4 py-2 bg-surface border border-primary text-primary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2 h-[44px]"
          >
            <span className="material-symbols-outlined text-[18px]">edit</span>
            Edit Member
          </a>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-lg">
        <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
          <div className="flex flex-col items-center text-center mb-lg">
            <div className="w-20 h-20 rounded-full bg-primary-container flex items-center justify-center text-on-primary font-section-title text-section-title mb-3">
              AM
            </div>
            <h2 className="font-card-title text-card-title text-text-primary">Abdul Malik</h2>
            <p className="font-small text-small text-text-muted">MEM-9910</p>
            <div className="mt-2"><StatusBadge status="Active" /></div>
          </div>
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-text-muted text-[20px]">phone</span>
              <div>
                <p className="font-small text-small text-text-muted">Phone</p>
                <p className="font-body text-body text-text-primary">+91 98765 43210</p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-text-muted text-[20px]">home</span>
              <div>
                <p className="font-small text-small text-text-muted">House Name</p>
                <p className="font-body text-body text-text-primary">Malik Manzil</p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-text-muted text-[20px]">family_restroom</span>
              <div>
                <p className="font-small text-small text-text-muted">Family Members</p>
                <p className="font-body text-body text-text-primary">5</p>
              </div>
            </div>
          </div>
        </div>

        <div className="lg:col-span-2 space-y-lg">
          <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
            <h3 className="font-card-title text-card-title text-text-primary mb-lg">Payment Summary</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="text-center p-3 bg-surface-container-low rounded-lg">
                <p className="font-small text-small text-text-muted">Monthly Due</p>
                <p className="font-card-title text-card-title text-text-primary">₹500</p>
              </div>
              <div className="text-center p-3 bg-surface-container-low rounded-lg">
                <p className="font-small text-small text-text-muted">Last Paid</p>
                <p className="font-card-title text-card-title text-text-primary">Aug 2026</p>
              </div>
              <div className="text-center p-3 bg-surface-container-low rounded-lg">
                <p className="font-small text-small text-text-muted">Outstanding</p>
                <p className="font-card-title text-card-title text-success">₹0</p>
              </div>
              <div className="text-center p-3 bg-surface-container-low rounded-lg">
                <p className="font-small text-small text-text-muted">Total Paid</p>
                <p className="font-card-title text-card-title text-text-primary">₹4,500</p>
              </div>
            </div>
          </div>

          <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
            <div className="p-lg border-b border-border-base">
              <h3 className="font-card-title text-card-title text-text-primary">Recent Transactions</h3>
            </div>
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface-container-low border-b border-border-base">
                  <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">DATE</th>
                  <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">TYPE</th>
                  <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">AMOUNT</th>
                  <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">STATUS</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-base">
                <tr className="hover:bg-surface-bright transition-colors">
                  <td className="py-4 px-lg font-body text-body text-text-primary">Aug 1, 2026</td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary">Monthly Dues</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">₹500</td>
                  <td className="py-4 px-lg"><StatusBadge status="Success" /></td>
                </tr>
                <tr className="hover:bg-surface-bright transition-colors">
                  <td className="py-4 px-lg font-body text-body text-text-primary">Jul 1, 2026</td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary">Monthly Dues</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">₹500</td>
                  <td className="py-4 px-lg"><StatusBadge status="Success" /></td>
                </tr>
                <tr className="hover:bg-surface-bright transition-colors">
                  <td className="py-4 px-lg font-body text-body text-text-primary">Jun 1, 2026</td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary">Monthly Dues</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">₹500</td>
                  <td className="py-4 px-lg"><StatusBadge status="Success" /></td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </>
  );
}
