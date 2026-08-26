import { PageHeader } from "@/components/ui/PageHeader";

export default function EditMahalPage({ params }: { params: { id: string } }) {
  return (
    <>
      <PageHeader
        title="Edit Mahal Details"
        description={`Updating details for Mahal ${params.id}.`}
      />
      <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm max-w-2xl">
        <form className="flex flex-col gap-lg">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-lg">
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">
                Mahal Name
              </label>
              <input
                className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container focus:border-transparent"
                defaultValue="Central Juma Masjid"
                type="text"
              />
            </div>
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">
                Registration Number
              </label>
              <input
                className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container focus:border-transparent"
                defaultValue="REG-2024-8492"
                type="text"
              />
            </div>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-lg">
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">
                Contact Email
              </label>
              <input
                className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container focus:border-transparent"
                defaultValue="admin@centraljuma.org"
                type="email"
              />
            </div>
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">
                Contact Phone
              </label>
              <input
                className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container focus:border-transparent"
                defaultValue="+91 98765 43210"
                type="tel"
              />
            </div>
          </div>
          <div className="flex flex-col gap-sm">
            <label className="font-card-title text-card-title text-text-primary">
              Status
            </label>
            <select className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container focus:border-transparent">
              <option>Active</option>
              <option>Grace Period</option>
              <option>Read Only</option>
              <option>Suspended</option>
            </select>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-lg">
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">
                Default Monthly Dues (₹)
              </label>
              <input
                className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container focus:border-transparent"
                defaultValue="500"
                type="number"
              />
            </div>
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">
                Dunning Enabled
              </label>
              <select className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container focus:border-transparent">
                <option>Yes</option>
                <option>No</option>
              </select>
            </div>
          </div>
          <div className="flex gap-3 pt-lg border-t border-border-base">
            <button
              type="submit"
              className="h-12 px-6 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center gap-2"
            >
              <span className="material-symbols-outlined text-[18px]">save</span>
              Save Changes
            </button>
            <a
              href="/mahals"
              className="h-12 px-6 bg-surface border border-border-base text-text-secondary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center"
            >
              Cancel
            </a>
          </div>
        </form>
      </div>
    </>
  );
}
