"use client";

import { useEffect, useState } from "react";
import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { ShimmerSkeleton } from "@/components/ui/ShimmerSkeleton";
import { ApiClient, type FinancialReport, type ReportPeriod } from "@/lib/api-client";

type PeriodMode = "MONTH" | "CUSTOM" | "ALL_TIME";

function currentMonthIST(): string {
  // en-CA formats as YYYY-MM-DD.
  return new Date().toLocaleDateString("en-CA", { timeZone: "Asia/Kolkata" }).slice(0, 7);
}

function formatBound(iso?: string | null): string {
  if (!iso) return "";
  return new Date(iso).toLocaleDateString("en-IN", { timeZone: "Asia/Kolkata", day: "2-digit", month: "short", year: "numeric" });
}

export default function FinancialReportsPage() {
  const [report, setReport] = useState<FinancialReport | null>(null);
  const [payments, setPayments] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [mode, setMode] = useState<PeriodMode>("MONTH");
  const [month, setMonth] = useState(currentMonthIST());
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");

  const buildPeriod = (): ReportPeriod | null => {
    if (mode === "MONTH") return month ? { month } : null;
    if (mode === "CUSTOM") return from && to ? { from, to } : null;
    return {};
  };

  const loadReport = (period: ReportPeriod) => {
    setLoading(true);
    setError(null);
    Promise.all([ApiClient.getFinancialReports(period), ApiClient.getPayments(undefined, 1, 50)])
      .then(([repRes, payRes]) => {
        if (repRes) setReport(repRes);
        if (payRes && payRes.payments) setPayments(payRes.payments);
      })
      .catch((err) => {
        console.error("Error loading financial report:", err);
        setError("Could not load report for this period.");
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadReport({ month: currentMonthIST() });
  }, []);

  const applyPeriod = (e: React.FormEvent) => {
    e.preventDefault();
    const period = buildPeriod();
    if (!period) {
      setError(mode === "CUSTOM" ? "Pick both From and To dates." : "Pick a month.");
      return;
    }
    if (period.from && period.to && period.from > period.to) {
      setError("From date must be on or before To date.");
      return;
    }
    loadReport(period);
  };

  const totalCollected = report?.summary?.total_collected || 0;
  const duesCollected = report?.summary?.dues_collected || 0;
  const donations = report?.summary?.donations || 0;
  const pendingDues = report?.summary?.pending_dues || 0;
  const txnCount = report?.summary?.transaction_count;
  const period = report?.period || "ALL_TIME";
  const periodLabel =
    period === "ALL_TIME"
      ? "All time"
      : period === "CUSTOM"
      ? `${formatBound(report?.from)} – ${formatBound(report?.to)}`
      : period;

  // The ledger below is the latest 50 transactions; narrow it to the report window when bounded.
  const fromMs = report?.from ? new Date(report.from).getTime() : null;
  const toMs = report?.to ? new Date(report.to).getTime() : null;
  const ledger = payments.filter((p) => {
    if (fromMs === null && toMs === null) return true;
    const t = p.created_at ? new Date(p.created_at).getTime() : NaN;
    if (Number.isNaN(t)) return false;
    return (fromMs === null || t >= fromMs) && (toMs === null || t <= toMs);
  });

  return (
    <>
      <PageHeader
        title="Reports & Analytics"
        description="Accounting balance sheet, dues collection rate, and live transaction ledger."
        actions={
          <div className="flex gap-2">
            <button
              onClick={() => window.print()}
              className="px-4 py-2 bg-surface border border-border-base text-text-primary font-button text-sm font-semibold rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2 h-[44px]"
            >
              <span className="material-symbols-outlined text-[18px]">picture_as_pdf</span>
              Print Statement
            </button>
            <button
              onClick={() => {
                const csvContent =
                  "data:text/csv;charset=utf-8," +
                  "Transaction ID,Member,Amount,Type,Gateway,Status,Date\n" +
                  ledger
                    .map(
                      (p) =>
                        `"${p.id}","${p.member_id}","${p.amount}","${p.type}","${p.gateway}","${p.status}","${p.created_at}"`
                    )
                    .join("\n");
                const encodedUri = encodeURI(csvContent);
                const link = document.createElement("a");
                link.setAttribute("href", encodedUri);
                link.setAttribute("download", `financial_report_${period === "CUSTOM" ? `${from}_${to}` : period}.csv`);
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
              }}
              className="px-4 py-2 bg-primary text-on-primary font-button text-sm font-semibold rounded-lg hover:bg-primary-dark transition-colors flex items-center gap-2 h-[44px] shadow-sm"
            >
              <span className="material-symbols-outlined text-[18px]">download</span>
              Export CSV
            </button>
          </div>
        }
      />

      <form
        onSubmit={applyPeriod}
        className="bg-surface border border-border-base rounded-2xl p-4 mb-4 flex flex-wrap items-end gap-3 shadow-sm"
      >
        <div>
          <label className="block text-xs font-semibold text-text-secondary mb-1">Period</label>
          <select
            value={mode}
            onChange={(e) => setMode(e.target.value as PeriodMode)}
            className="h-10 px-3 border border-border-base rounded-lg text-sm text-text-primary bg-surface"
          >
            <option value="MONTH">Month</option>
            <option value="CUSTOM">Custom range</option>
            <option value="ALL_TIME">All time</option>
          </select>
        </div>
        {mode === "MONTH" && (
          <div>
            <label className="block text-xs font-semibold text-text-secondary mb-1">Month</label>
            <input
              type="month"
              value={month}
              onChange={(e) => setMonth(e.target.value)}
              className="h-10 px-3 border border-border-base rounded-lg text-sm text-text-primary bg-surface"
            />
          </div>
        )}
        {mode === "CUSTOM" && (
          <>
            <div>
              <label className="block text-xs font-semibold text-text-secondary mb-1">From</label>
              <input
                type="date"
                value={from}
                onChange={(e) => setFrom(e.target.value)}
                className="h-10 px-3 border border-border-base rounded-lg text-sm text-text-primary bg-surface"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-text-secondary mb-1">To</label>
              <input
                type="date"
                value={to}
                onChange={(e) => setTo(e.target.value)}
                className="h-10 px-3 border border-border-base rounded-lg text-sm text-text-primary bg-surface"
              />
            </div>
          </>
        )}
        <button
          type="submit"
          disabled={loading}
          className="h-10 px-4 bg-primary text-on-primary rounded-lg font-button text-sm font-semibold hover:bg-primary-dark transition-colors disabled:opacity-50"
        >
          Apply
        </button>
        <div className="ml-auto text-xs text-text-secondary">
          Showing: <span className="font-semibold text-text-primary">{periodLabel}</span>
          {report?.timezone ? ` (${report.timezone})` : ""}
          {typeof txnCount === "number" ? ` • ${txnCount} transactions` : ""}
        </div>
        {error && <p className="w-full text-xs text-error">{error}</p>}
      </form>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-surface rounded-2xl border border-border-base p-5 shadow-sm">
          <div className="flex justify-between items-start mb-2">
            <p className="text-xs font-semibold text-text-muted">Total Collected ({periodLabel})</p>
            <span className="flex items-center gap-1 text-success text-xs font-bold bg-success-bg px-2 py-0.5 rounded-full">
              <span className="w-1.5 h-1.5 rounded-full bg-success" />
              Live
            </span>
          </div>
          {loading ? (
            <ShimmerSkeleton height={32} width={120} className="mt-2" />
          ) : (
            <h3 className="font-amount-lg text-2xl font-bold text-success mt-1">
              ₹{totalCollected.toLocaleString()}
            </h3>
          )}
        </div>

        <div className="bg-surface rounded-2xl border border-border-base p-5 shadow-sm">
          <p className="text-xs font-semibold text-text-muted mb-2">Dues Collected</p>
          {loading ? (
            <ShimmerSkeleton height={32} width={100} className="mt-2" />
          ) : (
            <h3 className="font-amount-lg text-2xl font-bold text-text-primary mt-1">
              ₹{duesCollected.toLocaleString()}
            </h3>
          )}
        </div>

        <div className="bg-surface rounded-2xl border border-border-base p-5 shadow-sm">
          <p className="text-xs font-semibold text-text-muted mb-2">Donations & Funds</p>
          {loading ? (
            <ShimmerSkeleton height={32} width={100} className="mt-2" />
          ) : (
            <h3 className="font-amount-lg text-2xl font-bold text-info mt-1">
              ₹{donations.toLocaleString()}
            </h3>
          )}
        </div>

        <div className="bg-surface rounded-2xl border border-border-base p-5 shadow-sm">
          <p className="text-xs font-semibold text-text-muted mb-2">Pending Dues Balance (current)</p>
          {loading ? (
            <ShimmerSkeleton height={32} width={100} className="mt-2" />
          ) : (
            <h3 className="font-amount-lg text-2xl font-bold text-warning mt-1">
              ₹{pendingDues.toLocaleString()}
            </h3>
          )}
        </div>
      </div>

      <div className="bg-surface border border-border-base rounded-2xl overflow-hidden shadow-sm">
        <div className="p-5 border-b border-border-base flex items-center justify-between">
          <h3 className="font-card-title text-base font-bold text-text-primary">
            Recent Ledger Breakdown ({periodLabel})
          </h3>
          <span className="text-xs font-semibold text-text-muted bg-surface-container-low px-2.5 py-1 rounded-md">
            {ledger.length} Transactions
          </span>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low/70 border-b border-border-base">
                <th className="text-xs font-bold text-text-secondary py-3 px-5">TRANSACTION ID</th>
                <th className="text-xs font-bold text-text-secondary py-3 px-5">TYPE</th>
                <th className="text-xs font-bold text-text-secondary py-3 px-5">AMOUNT</th>
                <th className="text-xs font-bold text-text-secondary py-3 px-5">GATEWAY / CHANNEL</th>
                <th className="text-xs font-bold text-text-secondary py-3 px-5">SETTLEMENT STATUS</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base">
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i}>
                    <td colSpan={5} className="py-4 px-5">
                      <ShimmerSkeleton height={20} className="w-full" />
                    </td>
                  </tr>
                ))
              ) : ledger.length === 0 ? (
                <tr>
                  <td colSpan={5} className="py-12 text-center text-text-muted text-sm">
                    No transactions recorded for this period
                  </td>
                </tr>
              ) : (
                ledger.map((p) => (
                  <tr key={p.id} className="hover:bg-surface-bright transition-colors">
                    <td className="py-3.5 px-5 font-mono text-xs text-text-primary font-medium">
                      {p.id}
                    </td>
                    <td className="py-3.5 px-5 text-sm text-text-primary">
                      {p.type === "MONTHLY_DUES" ? "Monthly Dues" : p.type || "Payment"}
                    </td>
                    <td className="py-3.5 px-5 text-sm text-text-primary font-bold">
                      ₹{p.amount}
                    </td>
                    <td className="py-3.5 px-5 text-xs text-text-secondary font-medium">
                      {p.gateway || "CASH"}
                    </td>
                    <td className="py-3.5 px-5">
                      <StatusBadge status={p.status} />
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}
