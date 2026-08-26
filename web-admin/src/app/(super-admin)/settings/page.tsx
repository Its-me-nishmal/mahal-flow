import { PageHeader } from "@/components/ui/PageHeader";

export default function SystemSettingsPage() {
  const admins = [
    { name: "System Admin", role: "Owner", lastLogin: "Today, 10:42 AM" },
    { name: "John Doe", role: "Support", lastLogin: "Yesterday, 3:15 PM" },
  ];

  return (
    <>
      <PageHeader
        title="System Settings"
        description="Configure platform-wide defaults and manage super admin access."
        actions={
          <button className="px-4 py-2 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center gap-2 h-[44px]">
            <span className="material-symbols-outlined text-[18px]">save</span>
            Save Changes
          </button>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-lg">
        <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm lg:col-span-2">
          <h3 className="font-section-title text-section-title text-text-primary mb-lg">
            Global Payment Gateways
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="border border-border-base rounded-xl p-lg">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-primary-container flex items-center justify-center">
                    <span className="material-symbols-outlined text-on-primary-container text-[20px]">
                      account_balance_wallet
                    </span>
                  </div>
                  <p className="font-card-title text-card-title text-text-primary">Razorpay</p>
                </div>
                <div className="w-11 h-6 bg-success rounded-full relative cursor-pointer">
                  <div className="absolute right-0.5 top-0.5 w-5 h-5 bg-surface rounded-full shadow transition-transform" />
                </div>
              </div>
              <div className="space-y-3">
                <div>
                  <label className="font-small text-small text-text-secondary">API Key ID</label>
                  <input className="w-full h-10 px-3 mt-1 rounded-lg border border-border-base bg-surface-container-low text-text-primary font-body text-body" defaultValue="rzp_live_••••••••K7xQ" readOnly type="password" />
                </div>
                <div>
                  <label className="font-small text-small text-text-secondary">Secret Key</label>
                  <input className="w-full h-10 px-3 mt-1 rounded-lg border border-border-base bg-surface-container-low text-text-primary font-body text-body" defaultValue="••••••••••••" readOnly type="password" />
                </div>
                <button className="text-primary font-button text-small hover:underline">Edit Credentials</button>
              </div>
            </div>
            <div className="border border-border-base rounded-xl p-lg">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg bg-surface-container flex items-center justify-center border border-border-base">
                    <span className="material-symbols-outlined text-text-secondary text-[20px]">
                      account_balance_wallet
                    </span>
                  </div>
                  <p className="font-card-title text-card-title text-text-primary">Stripe</p>
                </div>
                <div className="w-11 h-6 bg-surface-container-high rounded-full relative cursor-pointer">
                  <div className="absolute left-0.5 top-0.5 w-5 h-5 bg-surface rounded-full shadow transition-transform" />
                </div>
              </div>
              <div className="space-y-3">
                <div>
                  <label className="font-small text-small text-text-secondary">Publishable Key</label>
                  <input className="w-full h-10 px-3 mt-1 rounded-lg border border-border-base bg-surface-container-low text-text-primary font-body text-body" placeholder="pk_live_..." type="password" />
                </div>
                <div>
                  <label className="font-small text-small text-text-secondary">Secret Key</label>
                  <input className="w-full h-10 px-3 mt-1 rounded-lg border border-border-base bg-surface-container-low text-text-primary font-body text-body" placeholder="sk_live_..." type="password" />
                </div>
                <button className="text-primary font-button text-small hover:underline">Configure</button>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
          <h3 className="font-section-title text-section-title text-text-primary mb-lg">
            Platform Branding
          </h3>
          <div className="space-y-lg">
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">Platform Name</label>
              <input className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container" defaultValue="MahalFlow Admin" type="text" />
            </div>
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">Global Logo</label>
              <div className="border-2 border-dashed border-border-base rounded-xl p-lg text-center hover:bg-surface-container-low cursor-pointer transition-colors">
                <span className="material-symbols-outlined text-[32px] text-text-muted mb-2 block">cloud_upload</span>
                <p className="font-body text-body text-text-secondary">SVG or PNG, max 2MB</p>
              </div>
            </div>
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">Primary Color</label>
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-lg border border-border-base" style={{ backgroundColor: "#005244" }} />
                <input className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container w-32" defaultValue="#005244" type="text" />
              </div>
            </div>
          </div>
        </div>

        <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
          <div className="flex items-center justify-between mb-lg">
            <h3 className="font-section-title text-section-title text-text-primary">Super Admins</h3>
            <button className="h-9 px-4 bg-primary-container text-on-primary rounded-lg font-button text-small hover:bg-primary transition-colors flex items-center gap-1">
              <span className="material-symbols-outlined text-[14px]">add</span>
              Add Admin
            </button>
          </div>
          <div className="space-y-3">
            {admins.map((admin, i) => (
              <div key={i} className="flex items-center justify-between p-3 border border-border-base rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-primary-container flex items-center justify-center text-on-primary font-button text-button">
                    {admin.name.split(" ").map((n) => n[0]).join("")}
                  </div>
                  <div>
                    <p className="font-button text-button text-text-primary">{admin.name}</p>
                    <p className="font-small text-small text-text-muted">{admin.role} - Last login: {admin.lastLogin}</p>
                  </div>
                </div>
                <button className="text-text-secondary hover:text-primary p-2 rounded-lg hover:bg-surface-container-low transition-colors">
                  <span className="material-symbols-outlined">more_vert</span>
                </button>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm lg:col-span-2">
          <h3 className="font-section-title text-section-title text-text-primary mb-lg">
            Audit Retention
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-lg">
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">Financial Transactions Log</label>
              <select className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container">
                <option>7 Years (Recommended)</option>
                <option>5 Years</option>
                <option>10 Years</option>
                <option>Indefinite</option>
              </select>
            </div>
            <div className="flex flex-col gap-sm">
              <label className="font-card-title text-card-title text-text-primary">User Activity Log</label>
              <select className="h-12 px-4 rounded-lg border border-border-base bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container">
                <option>1 Year</option>
                <option>2 Years</option>
                <option>3 Years</option>
              </select>
            </div>
          </div>
          <div className="bg-warning-bg border border-warning/20 rounded-lg p-md mt-lg flex items-start gap-3">
            <span className="material-symbols-outlined text-warning mt-0.5">warning</span>
            <p className="font-small text-small text-text-secondary">
              Reducing retention will permanently delete older logs during the next midnight maintenance window. This action cannot be undone.
            </p>
          </div>
        </div>
      </div>
    </>
  );
}
