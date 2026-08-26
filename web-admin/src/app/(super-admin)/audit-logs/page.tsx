import { PageHeader } from "@/components/ui/PageHeader";
import { mockAuditLogs } from "@/lib/mock-data";

const typeStyles: Record<string, string> = {
  warning: "bg-warning-bg text-warning",
  error: "bg-error-bg text-error",
  success: "bg-success-bg text-success",
  info: "bg-info-bg text-info",
};

export default function AuditLogsPage() {
  return (
    <>
      <PageHeader
        title="Audit Logs"
        description="Secure record of all administrative actions and system events."
      />

      <div className="flex gap-2 mb-lg flex-wrap">
        <div className="relative flex-1 min-w-[200px]">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
            search
          </span>
          <input
            className="pl-9 pr-4 py-2 border border-border-base rounded-lg text-body font-body w-full h-[44px] focus:border-primary focus:ring-0 outline-none"
            placeholder="Search by admin name or action..."
            type="text"
          />
        </div>
        {["All Events", "Member Update", "Gateway Change", "Destructive"].map((filter, i) => (
          <button
            key={filter}
            className={`h-8 px-4 rounded-full font-button text-small transition-colors whitespace-nowrap ${
              i === 0
                ? "bg-primary-container text-on-primary"
                : "bg-surface border border-border-base text-text-secondary hover:bg-surface-container-low"
            }`}
          >
            {filter}
          </button>
        ))}
      </div>

      <div className="space-y-3">
        {mockAuditLogs.map((log) => (
          <div
            key={log.id}
            className="bg-surface border border-border-base rounded-xl p-lg hover:-translate-y-0.5 transition-transform duration-200"
          >
            <div className="flex items-start justify-between gap-4 mb-3">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-surface-container flex items-center justify-center border border-border-base">
                  <span className="material-symbols-outlined text-text-secondary text-[20px]">
                    person
                  </span>
                </div>
                <div>
                  <p className="font-button text-button text-text-primary">
                    {log.admin}{" "}
                    <span className="font-small text-small text-text-muted">({log.adminId})</span>
                  </p>
                  <p className="font-small text-small text-text-muted">{log.time}</p>
                </div>
              </div>
              <span className={`inline-flex items-center px-2 py-1 rounded-full font-small text-small gap-1 ${typeStyles[log.type] || "bg-surface-variant text-text-secondary"}`}>
                {log.action}
              </span>
            </div>
            <p className="font-body text-body text-text-secondary ml-13">{log.detail}</p>
            <div className="flex items-center gap-2 mt-3 ml-13">
              <span className="material-symbols-outlined text-[14px] text-text-muted">location_on</span>
              <span className="font-small text-small text-text-muted">{log.ip}</span>
            </div>
          </div>
        ))}
      </div>

      <div className="flex justify-center pt-lg">
        <button className="h-11 px-6 border border-border-base rounded-lg text-text-secondary hover:bg-surface-container-low font-button text-button transition-colors">
          Load More Logs
        </button>
      </div>
    </>
  );
}
