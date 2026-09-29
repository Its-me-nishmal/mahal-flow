"use client";

import { useEffect, useState } from "react";
import { PageHeader } from "@/components/ui/PageHeader";
import { ApiClient, type Gateway } from "@/lib/api-client";

function Field({ label, value, mono }: { label: string; value: React.ReactNode; mono?: boolean }) {
  return (
    <div className="flex justify-between items-center gap-3 py-2">
      <span className="font-small text-small text-text-secondary">{label}</span>
      <span className={`text-sm text-text-primary text-right ${mono ? "font-mono" : "font-medium"}`}>{value}</span>
    </div>
  );
}

export default function GatewayConfigurationPage() {
  const [gateways, setGateways] = useState<Gateway[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    ApiClient.getGateways()
      .then((res) => {
        if (Array.isArray(res)) setGateways(res);
      })
      .catch((err) => {
        console.error("Error loading gateways:", err);
        setError("Could not load gateway configuration.");
      })
      .finally(() => setLoading(false));
  }, []);

  return (
    <>
      <PageHeader
        title="Gateway Configuration"
        description="Payment gateways currently configured on the MahalFlow server."
      />

      <div className="bg-info-bg border border-info/20 rounded-xl p-md flex items-start gap-3 mb-lg">
        <span className="material-symbols-outlined text-info mt-0.5">lock</span>
        <div>
          <p className="font-button text-button text-info">Managed from server config</p>
          <p className="font-small text-small text-text-secondary mt-1">
            Gateway credentials live in the server environment and cannot be edited here. Merchant keys are
            masked; secrets are never sent to the browser.
          </p>
        </div>
      </div>

      {error && <p className="font-body text-body text-error mb-4">{error}</p>}
      {loading && <p className="font-body text-body text-text-muted">Loading gateways...</p>}
      {!loading && !error && gateways.length === 0 && (
        <p className="font-body text-body text-text-muted">No gateways reported by the server.</p>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {gateways.map((gw) => {
          const active = gw.status === "ACTIVE";
          const isCash = gw.provider === "CASH";
          return (
            <div key={gw.id} className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
              <div className="flex items-start justify-between gap-3 mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-lg bg-primary-container flex items-center justify-center">
                    <span className="material-symbols-outlined text-on-primary-container text-[22px]">
                      {isCash ? "payments" : "account_balance_wallet"}
                    </span>
                  </div>
                  <div>
                    <p className="font-card-title text-card-title text-text-primary">
                      {gw.display_name || gw.provider}
                    </p>
                    <p className="font-small text-small text-text-muted">
                      {gw.is_primary ? "Primary provider" : isCash ? "Recorded by committee" : "Secondary provider"}
                    </p>
                  </div>
                </div>
                <div className="flex flex-col items-end gap-1">
                  <span
                    className={`inline-flex items-center px-2.5 py-1 rounded-full font-small text-small font-semibold gap-1 ${
                      active ? "bg-success-bg text-success" : "bg-error-bg text-error"
                    }`}
                  >
                    <span className={`w-1.5 h-1.5 rounded-full ${active ? "bg-success" : "bg-error"}`} />
                    {active ? "Active" : "Not configured"}
                  </span>
                  {!isCash && gw.mode && (
                    <span
                      className={`inline-flex px-2 py-0.5 rounded-full font-small text-small font-semibold ${
                        gw.mode === "LIVE" ? "bg-primary-light text-primary" : "bg-warning-bg text-warning"
                      }`}
                    >
                      {gw.mode}
                    </span>
                  )}
                </div>
              </div>

              {gw.simulated && (
                <div className="bg-warning-bg text-warning rounded-lg px-3 py-2 font-small text-small mb-3">
                  Simulated: server test mode is on, no real gateway calls are made.
                </div>
              )}

              <div className="divide-y divide-border-base border-t border-border-base">
                <Field label="Gateway ID" value={gw.id} mono />
                {!isCash && <Field label="Merchant Key" value={gw.merchant_key_masked || "—"} mono />}
                <Field
                  label="Methods"
                  value={
                    <span className="flex flex-wrap justify-end gap-1">
                      {(gw.supported_methods || []).length === 0
                        ? "—"
                        : gw.supported_methods!.map((m) => (
                            <span key={m} className="px-2 py-0.5 rounded bg-surface-container-low text-xs font-semibold">
                              {m}
                            </span>
                          ))}
                    </span>
                  }
                />
                {!isCash && (
                  <Field
                    label="AutoPay (SI)"
                    value={gw.autopay_enabled ? "Enabled" : gw.si_supported ? "Supported, not enabled" : "Not supported"}
                  />
                )}
                <Field label="Managed by" value={gw.managed_by === "SERVER_CONFIG" ? "Server config" : gw.managed_by || "—"} />
              </div>
            </div>
          );
        })}
      </div>
    </>
  );
}
