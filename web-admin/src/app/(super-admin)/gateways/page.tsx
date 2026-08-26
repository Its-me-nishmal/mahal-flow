import { PageHeader } from "@/components/ui/PageHeader";

export default function GatewayConfigurationPage() {
  const gateways = [
    { name: "Razorpay", enabled: true, keyId: "rzp_live_••••••••K7xQ", secret: "••••••••••••••••" },
    { name: "Stripe", enabled: false, keyId: "", secret: "" },
  ];

  return (
    <>
      <PageHeader title="Gateway Configuration" description="Configure payment processing gateways." />

      <div className="bg-warning-bg border border-warning/20 rounded-xl p-md flex items-start gap-3 mb-lg">
        <span className="material-symbols-outlined text-warning mt-0.5">info</span>
        <div>
          <p className="font-button text-button text-warning">Strict Credential Masking Enabled</p>
          <p className="font-small text-small text-text-secondary mt-1">
            API keys and secrets are permanently masked. An authenticated workflow is required to update credentials.
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {gateways.map((gw) => (
          <div key={gw.name} className="bg-surface border border-border-base rounded-xl p-lg shadow-sm relative">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-lg bg-primary-container flex items-center justify-center">
                  <span className="material-symbols-outlined text-on-primary-container text-[22px]">
                    account_balance_wallet
                  </span>
                </div>
                <div>
                  <p className="font-card-title text-card-title text-text-primary">{gw.name}</p>
                  <p className="font-small text-small text-text-muted">
                    {gw.name === "Razorpay" ? "Primary Route" : "Secondary Route"}
                  </p>
                </div>
              </div>
              <span className="inline-flex items-center px-2 py-1 rounded-full bg-success-bg text-success font-small text-small gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-success" />
                {gw.enabled ? "Connected" : "Not Configured"}
              </span>
            </div>
            <div className="space-y-3 mb-4">
              <div>
                <label className="font-small text-small text-text-secondary">API Key ID</label>
                <input
                  className="w-full h-10 px-3 mt-1 rounded-lg border border-border-base bg-surface-container-low text-text-primary font-body text-body"
                  defaultValue={gw.keyId}
                  readOnly
                  type="password"
                />
              </div>
              <div>
                <label className="font-small text-small text-text-secondary">Secret Key</label>
                <input
                  className="w-full h-10 px-3 mt-1 rounded-lg border border-border-base bg-surface-container-low text-text-primary font-body text-body"
                  defaultValue={gw.secret}
                  readOnly
                  type="password"
                />
              </div>
            </div>
            <div className="flex gap-2 pt-4 border-t border-border-base">
              <button className="h-9 px-4 border border-border-base rounded-lg text-text-secondary hover:bg-surface-container-low font-button text-small transition-colors flex items-center gap-1">
                <span className="material-symbols-outlined text-[14px]">wifi_tethering</span>
                Test Connection
              </button>
              <button className="h-9 px-4 border border-primary text-primary rounded-lg hover:bg-primary-container/10 font-button text-small transition-colors flex items-center gap-1">
                <span className="material-symbols-outlined text-[14px]">key</span>
                {gw.enabled ? "Manage Credentials" : "Configure"}
              </button>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
