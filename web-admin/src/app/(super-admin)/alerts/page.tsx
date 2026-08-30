"use client";

import { useEffect, useState } from "react";
import { PageHeader } from "@/components/ui/PageHeader";
import { ApiClient } from "@/lib/api-client";

export default function AlertsPage() {
  const [alerts, setAlerts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [severity, setSeverity] = useState<"INFO" | "WARNING" | "CRITICAL">("INFO");

  const loadAlerts = () => {
    ApiClient.getAlerts("MH_001_CALICUT")
      .then((res) => {
        if (res && res.alerts) {
          setAlerts(res.alerts);
        }
      })
      .catch((err) => console.error("Error loading alerts:", err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadAlerts();
  }, []);

  const handleAcknowledge = async (id: string) => {
    try {
      await ApiClient.acknowledgeAlert(id, "MH_001_CALICUT");
      loadAlerts();
    } catch (err) {
      console.error("Failed to acknowledge alert:", err);
    }
  };

  const handleCreateAlert = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !description.trim()) return;

    setIsSubmitting(true);
    try {
      await ApiClient.createAlert({ title, description, severity }, "MH_001_CALICUT");
      setTitle("");
      setDescription("");
      setSeverity("INFO");
      setShowModal(false);
      loadAlerts();
    } catch (err) {
      console.error("Failed to create alert:", err);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <>
      <div className="flex items-center justify-between mb-lg">
        <PageHeader
          title="System & Member Alerts"
          description="Broadcast notices, dues reminders, and system announcements to members in real-time."
        />
        <button
          onClick={() => setShowModal(true)}
          className="h-10 px-4 bg-primary text-on-primary rounded-lg font-button text-body hover:bg-primary-dark transition-colors flex items-center gap-2 shadow-sm shrink-0"
        >
          <span className="material-symbols-outlined text-[18px]">add_alert</span>
          Broadcast New Alert
        </button>
      </div>

      <div className="space-y-3">
        {alerts.map((alert) => (
          <div
            key={alert.id}
            className={`bg-surface border rounded-xl p-lg transition-all duration-200 ${
              alert.status === "ACTIVE"
                ? "border-l-4 border-l-primary border-border-base shadow-sm"
                : "border-border-base opacity-75"
            }`}
          >
            <div className="flex items-start justify-between gap-4">
              <div className="flex items-start gap-3">
                {alert.status === "ACTIVE" && (
                  <div className="w-2 h-2 rounded-full bg-primary mt-2 shrink-0" />
                )}
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <span
                      className={`inline-flex items-center px-2 py-0.5 rounded-full font-small text-small font-semibold ${
                        alert.severity === "CRITICAL"
                          ? "bg-error-bg text-error"
                          : alert.severity === "WARNING"
                          ? "bg-warning-bg text-warning"
                          : "bg-info-bg text-info"
                      }`}
                    >
                      {alert.severity || "INFO"}
                    </span>
                    <span className="text-xs text-text-muted">
                      {alert.created_at ? new Date(alert.created_at).toLocaleString() : "Live"}
                    </span>
                  </div>
                  <p className="font-card-title text-card-title text-text-primary mb-1">
                    {alert.title}
                  </p>
                  <p className="font-body text-body text-text-secondary">{alert.description}</p>
                </div>
              </div>
              {alert.status === "ACTIVE" && (
                <button
                  onClick={() => handleAcknowledge(alert.id)}
                  className="h-9 px-4 border border-primary text-primary rounded-lg hover:bg-primary-container/10 font-button text-small transition-colors whitespace-nowrap shrink-0"
                >
                  Dismiss
                </button>
              )}
            </div>
          </div>
        ))}

        {alerts.length === 0 && (
          <div className="flex flex-col items-center justify-center py-16 text-center bg-surface rounded-xl border border-border-base">
            <span className="material-symbols-outlined text-[48px] text-text-muted mb-4">
              notifications_off
            </span>
            <p className="font-card-title text-card-title text-text-primary mb-1">No alerts active</p>
            <p className="font-body text-body text-text-secondary mb-4">
              {loading ? "Checking alerts..." : "Click 'Broadcast New Alert' to notify all members."}
            </p>
            <button
              onClick={() => setShowModal(true)}
              className="h-9 px-4 bg-primary text-on-primary rounded-lg font-button text-small hover:bg-primary-dark transition-colors inline-flex items-center gap-2"
            >
              <span className="material-symbols-outlined text-[16px]">add_alert</span>
              Send First Alert
            </button>
          </div>
        )}
      </div>

      {/* Broadcast Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-surface rounded-2xl border border-border-base shadow-xl max-w-md w-full p-6 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-primary text-[24px]">campaign</span>
                <h3 className="font-card-title text-card-title text-text-primary">
                  Broadcast Alert to Members
                </h3>
              </div>
              <button
                onClick={() => setShowModal(false)}
                className="text-text-muted hover:text-text-primary transition-colors"
              >
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>

            <form onSubmit={handleCreateAlert} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-text-secondary uppercase mb-1">
                  Severity Level
                </label>
                <div className="grid grid-cols-3 gap-2">
                  {(["INFO", "WARNING", "CRITICAL"] as const).map((sev) => (
                    <button
                      key={sev}
                      type="button"
                      onClick={() => setSeverity(sev)}
                      className={`h-9 rounded-lg font-button text-small border transition-all ${
                        severity === sev
                          ? sev === "CRITICAL"
                            ? "bg-error text-white border-error"
                            : sev === "WARNING"
                            ? "bg-warning text-white border-warning"
                            : "bg-primary text-white border-primary"
                          : "bg-surface border-border-base text-text-secondary hover:bg-background"
                      }`}
                    >
                      {sev}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-text-secondary uppercase mb-1">
                  Alert Title
                </label>
                <input
                  type="text"
                  required
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="e.g. Monthly Dues Notice, General Meeting..."
                  className="w-full h-10 px-3 rounded-lg border border-border-base bg-background text-text-primary font-body text-body focus:outline-none focus:border-primary"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-text-secondary uppercase mb-1">
                  Message / Details
                </label>
                <textarea
                  required
                  rows={3}
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="Enter detailed notification content for members..."
                  className="w-full p-3 rounded-lg border border-border-base bg-background text-text-primary font-body text-body focus:outline-none focus:border-primary resize-none"
                />
              </div>

              <div className="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="h-10 px-4 rounded-lg border border-border-base text-text-secondary font-button text-body hover:bg-background transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="h-10 px-5 bg-primary text-on-primary rounded-lg font-button text-body hover:bg-primary-dark transition-colors flex items-center gap-2 shadow-sm disabled:opacity-50"
                >
                  {isSubmitting ? "Sending..." : "Send Broadcast"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
