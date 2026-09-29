"use client";

import { useCallback, useEffect, useState } from "react";
import { PageHeader } from "@/components/ui/PageHeader";
import { ErrorState } from "@/components/ui/States";
import { ApiClient } from "@/lib/api-client";
import { errorMessage, formatDateTime } from "@/lib/format";

export default function AuditLogsPage() {
  const [logs, setLogs] = useState<any[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const PAGE = 50;

  const load = useCallback((p: number) => {
    setLoading(true);
    setError(null);
    ApiClient.getAuditLogs(undefined, p, PAGE)
      .then((res) => {
        setLogs(res?.logs || []);
        setTotal(res?.total || 0);
        setPage(p);
      })
      .catch((err) => setError(errorMessage(err, "Could not load audit logs.")))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    load(1);
  }, [load]);
  const pages = Math.max(1, Math.ceil(total / PAGE));

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
        description="Record of administrative actions and financial events for this Mahal."
      />

      {error && <ErrorState message={error} onRetry={() => load(page)} />}

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
                    {log.actor || "System"}
                  </p>
                  <p className="font-small text-small text-text-muted">
                    {formatDateTime(log.timestamp)}
                    {log.ip_address ? ` · ${log.ip_address}` : ""}
                  </p>
                </div>
              </div>
              <span className="inline-flex items-center px-2.5 py-1 rounded-full font-small text-small bg-primary-light text-primary font-mono text-xs">
                {log.action}
              </span>
            </div>
            <p className="font-body text-body text-text-secondary ml-13">
              {log.details || (log.entity_id ? `Entity: ${log.entity_id}` : "—")}
            </p>
            <div className="flex items-center gap-2 mt-3 ml-13">
              <span className="material-symbols-outlined text-[14px] text-text-muted">security</span>
              <span className="font-small text-small text-text-muted font-mono text-xs">{log.id}</span>
            </div>
          </div>
        ))}

        {filteredLogs.length === 0 && (
          <div className="bg-surface border border-border-base rounded-xl p-12 text-center text-text-muted">
            {loading ? "Loading audit trail..." : search ? "No entries on this page match your search." : "No audit log records yet."}
          </div>
        )}

        {pages > 1 && (
          <div className="flex items-center justify-between pt-2">
            <button
              onClick={() => load(page - 1)}
              disabled={loading || page <= 1}
              className="h-9 px-4 border border-border-base rounded-lg font-button text-small text-text-secondary disabled:opacity-50"
            >
              Previous
            </button>
            <span className="text-xs text-text-muted">
              Page {page} of {pages} · {total.toLocaleString("en-IN")} entries
            </span>
            <button
              onClick={() => load(page + 1)}
              disabled={loading || page >= pages}
              className="h-9 px-4 border border-border-base rounded-lg font-button text-small text-text-secondary disabled:opacity-50"
            >
              Next
            </button>
          </div>
        )}
      </div>
    </>
  );
}
