import { PageHeader } from "@/components/ui/PageHeader";
import { mockAlerts } from "@/lib/mock-data";

const typeBadgeStyles: Record<string, string> = {
  "Payment Due": "bg-warning-bg text-warning",
  "Committee Meeting": "bg-info-bg text-info",
  "Receipt Generated": "bg-success-bg text-success",
  "System Update": "bg-surface-variant text-text-secondary",
};

export default function AlertsPage() {
  return (
    <>
      <PageHeader
        title="Alerts"
        description="Stay updated on payments and announcements."
        actions={
          <button className="text-primary font-button text-button hover:underline">
            Mark all as read
          </button>
        }
      />

      <div className="space-y-3">
        {mockAlerts.map((alert) => (
          <div
            key={alert.id}
            className={`bg-surface border rounded-xl p-lg transition-all duration-200 ${
              alert.unread
                ? "border-l-4 border-l-primary-container border-border-base shadow-sm"
                : "border-border-base opacity-75"
            }`}
          >
            <div className="flex items-start justify-between gap-4">
              <div className="flex items-start gap-3">
                {alert.unread && (
                  <div className="w-2 h-2 rounded-full bg-primary-container mt-2 shrink-0" />
                )}
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <span
                      className={`inline-flex items-center px-2 py-0.5 rounded-full font-small text-small ${typeBadgeStyles[alert.type] || "bg-surface-variant text-text-secondary"}`}
                    >
                      {alert.type}
                    </span>
                  </div>
                  <p className="font-card-title text-card-title text-text-primary mb-1">
                    {alert.title}
                  </p>
                  <p className="font-body text-body text-text-secondary">{alert.message}</p>
                </div>
              </div>
              {alert.action && (
                <button className="h-9 px-4 border border-primary text-primary rounded-lg hover:bg-primary-container/10 font-button text-small transition-colors whitespace-nowrap shrink-0">
                  {alert.action}
                </button>
              )}
            </div>
          </div>
        ))}
      </div>

      <div className="hidden flex-col items-center justify-center py-16 text-center">
        <span className="material-symbols-outlined text-[48px] text-text-muted mb-4">
          notifications_off
        </span>
        <p className="font-card-title text-card-title text-text-primary mb-1">All caught up!</p>
        <p className="font-body text-body text-text-secondary mb-4">
          No new notifications at this time.
        </p>
        <button className="h-10 px-4 border border-border-base rounded-lg text-text-secondary hover:bg-surface-container-low font-button text-button transition-colors">
          Refresh
        </button>
      </div>
    </>
  );
}
