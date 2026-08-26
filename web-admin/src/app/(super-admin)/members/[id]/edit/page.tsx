import { PageHeader } from "@/components/ui/PageHeader";

export default function EditMemberPage({ params }: { params: { id: string } }) {
  return (
    <>
      <PageHeader
        title="Edit Member Details"
        description={`Updating member ${params.id}.`}
      />
      <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm max-w-2xl">
        <form className="flex flex-col gap-lg">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-lg">
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">Full Name</label>
              <input className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container" defaultValue="Abdul Malik" type="text" />
            </div>
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">Phone Number</label>
              <input className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container" defaultValue="+91 98765 43210" type="tel" />
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-lg">
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">House Name</label>
              <input className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container" defaultValue="Malik Manzil" type="text" />
            </div>
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">Monthly Dues Amount (₹)</label>
              <input className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container" defaultValue="500" type="number" />
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-lg">
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">Status</label>
              <select className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container">
                <option>Active</option>
                <option>Pending</option>
                <option>Suspended</option>
              </select>
            </div>
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">Family Members Count</label>
              <input className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container" defaultValue="5" type="number" />
            </div>
          </div>
          <div className="flex flex-col gap-sm">
            <label className="font-card-title text-card-title text-text-primary">Family Head</label>
            <select className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container">
              <option>Yes</option>
              <option>No</option>
            </select>
          </div>
          <div className="flex gap-3 pt-lg border-t border-border-base">
            <button type="submit" className="h-12 px-6 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center gap-2">
              <span className="material-symbols-outlined text-[18px]">save</span>
              Save Changes
            </button>
            <a href="/members" className="h-12 px-6 bg-surface border border-border-base text-text-secondary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center">
              Cancel
            </a>
          </div>
        </form>
      </div>
    </>
  );
}
