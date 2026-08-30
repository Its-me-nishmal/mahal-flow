"use client";

import { useEffect, useState } from "react";
import { PageHeader } from "@/components/ui/PageHeader";
import { ApiClient } from "@/lib/api-client";

export default function AuditLogsPage() {
  const [logs, setLogs] = useState<any[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    ApiClient.getAuditLogs("MH_001_CALICUT", 1, 50)
      .then((res) => {
        if (res && res.logs) {
          setLogs(res.logs);
        }
      })
      .catch((err) => console.error("Error loading audit logs:", err))
      .finally(() => setLoading(false));
  }, []);

  const filteredLogs = logs.filter(
    (l) =>
      (l.action || "").toLowerCase().includes(search.toLowerCase()) ||
      (l.actor || "").toLowerCase().includes(search.toLowerCase()) ||
      (l.entity_id || "").toLowerCase().includes(search.toLowerCase())
  );

  return (
    <>
      <PageHeader
        title="Audit Logs"
        description="Immutable record of administrative actions and live financial events backed by MongoDB."
      />

      <div className="flex gap-2 mb-lg flex-wrap">
        <div className="relative flex-1 min-w-[200px]">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
            search
          </span>
          <input
            className="pl-9 pr-4 py-2 border border-border-base rounded-lg text-body font-body w-full h-[44px] focus:border-primary focus:ring-0 outline-none"
            placeholder="Search by actor, action, or ID..."
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </div>

      <div className="space-y-3">
        {filteredLogs.map((log) => (
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
                    {log.actor || "System Admin"}
                  </p>
                  <p className="font-small text-small text-text-muted">
                    {log.timestamp ? new Date(log.timestamp).toLocaleString() : "Recent"}
                  </p>
                </div>
              </div>
              <span className="inline-flex items-center px-2.5 py-1 rounded-full font-small text-small bg-primary-light text-primary font-mono text-xs">
                {log.action}
              </span>
            </div>
            <p className="font-body text-body text-text-secondary ml-13">
              {log.details || `Entity affected: ${log.entity_id || log.id}`}
            </p>
            <div className="flex items-center gap-2 mt-3 ml-13">
              <span className="material-symbols-outlined text-[14px] text-text-muted">security</span>
              <span className="font-small text-small text-text-muted font-mono text-xs">{log.id}</span>
            </div>
          </div>
        ))}

        {filteredLogs.length === 0 && (
          <div className="bg-surface border border-border-base rounded-xl p-12 text-center text-text-muted">
            {loading ? "Fetching audit trail from MongoDB..." : "No audit log records found."}
          </div>
        )}
      </div>
    </>
  );
}
