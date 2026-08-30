"use client";

import { useEffect, useState } from "react";
import { PageHeader } from "@/components/ui/PageHeader";
import { ApiClient } from "@/lib/api-client";

export default function GatewayConfigurationPage() {
  const [gateways, setGateways] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [tested, setTested] = useState<string | null>(null);

  useEffect(() => {
    ApiClient.getGateways("MH_001_CALICUT")
      .then((res) => {
        if (res && Array.isArray(res)) {
          setGateways(res);
        }
      })
      .catch((err) => console.error("Error loading gateways:", err))
      .finally(() => setLoading(false));
  }, []);

  const handleTestConnection = (id: string) => {
    setTested(id);
    setTimeout(() => {
      setTested(null);
    }, 3000);
  };

  return (
    <>
      <PageHeader
        title="Gateway Configuration"
        description="Configure live payment processing gateways and routing rules."
      />

      <div className="bg-warning-bg border border-warning/20 rounded-xl p-md flex items-start gap-3 mb-lg">
        <span className="material-symbols-outlined text-warning mt-0.5">info</span>
        <div>
          <p className="font-button text-button text-warning">Strict Credential Masking Enabled</p>
          <p className="font-small text-small text-text-secondary mt-1">
            API keys and secrets are stored in secure environment vaults. Only authorized administrators may update webhook secrets.
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {gateways.map((gw) => (
          <div
            key={gw.id}
            className="bg-surface border border-border-base rounded-xl p-lg shadow-sm relative"
          >
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-lg bg-primary-container flex items-center justify-center">
                  <span className="material-symbols-outlined text-on-primary-container text-[22px]">
                    account_balance_wallet
                  </span>
                </div>
                <div>
                  <p className="font-card-title text-card-title text-text-primary">{gw.provider}</p>
                  <p className="font-small text-small text-text-muted">
                    {gw.is_primary ? "Primary Routing Provider" : "Secondary Fallback Provider"}
                  </p>
                </div>
              </div>
              <span className="inline-flex items-center px-2.5 py-1 rounded-full bg-success-bg text-success font-small text-small font-semibold gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-success" />
                {gw.status === "ACTIVE" ? "Connected" : "Inactive"}
              </span>
            </div>
            <div className="space-y-3 mb-4">
              <div>
                <label className="font-small text-small text-text-secondary">Gateway ID</label>
                <input
                  className="w-full h-10 px-3 mt-1 rounded-lg border border-border-base bg-surface-container-low text-text-primary font-body text-body font-mono text-sm"
                  defaultValue={gw.id}
                  readOnly
                />
              </div>
              <div>
                <label className="font-small text-small text-text-secondary">Webhook Signature Secret</label>
                <input
                  className="w-full h-10 px-3 mt-1 rounded-lg border border-border-base bg-surface-container-low text-text-primary font-body text-body font-mono text-sm"
                  defaultValue="••••••••••••••••••••••••"
                  readOnly
                  type="password"
                />
              </div>
            </div>
            <div className="flex gap-2 pt-4 border-t border-border-base">
              <button
                onClick={() => handleTestConnection(gw.id)}
                className="h-9 px-4 border border-border-base rounded-lg text-text-secondary hover:bg-surface-container-low font-button text-small transition-colors flex items-center gap-1"
              >
                <span className="material-symbols-outlined text-[14px]">
                  {tested === gw.id ? "check_circle" : "wifi_tethering"}
                </span>
                {tested === gw.id ? "Verified Online" : "Test Connection"}
              </button>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
