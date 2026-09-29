"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { ErrorState } from "@/components/ui/States";
import { ApiClient } from "@/lib/api-client";
import { errorMessage, formatDate, formatINR, humanize } from "@/lib/format";

export default function PaymentsPage() {
  const [payments, setPayments] = useState<any[]>([]);
  const [statusFilter, setStatusFilter] = useState("ALL");
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [total, setTotal] = useState(0);

  const load = useCallback(() => {
    setLoading(true);
    setError(null);
    ApiClient.getPayments(undefined, 1, 100)
      .then((res) => {
        setPayments(res?.payments || []);
        setTotal(res?.total || 0);
      })
      .catch((err) => setError(errorMessage(err, "Could not load payments.")))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const totalSuccess = payments.filter((p) => p.status === "SUCCESS").length;
  const totalPending = payments.filter((p) => p.status === "PENDING" || p.status === "INITIALIZED").length;
  const totalFailed = payments.filter((p) => p.status === "FAILED").length;

  const filteredPayments = payments.filter((p) => {
    const matchesStatus =
      statusFilter === "ALL" ||
      (statusFilter === "SUCCESS" && p.status === "SUCCESS") ||
      (statusFilter === "PENDING" && (p.status === "PENDING" || p.status === "INITIALIZED")) ||
      (statusFilter === "FAILED" && p.status === "FAILED") ||
      (statusFilter === "REFUNDED" && p.status === "REFUNDED");

    const matchesSearch =
      (p.id || "").toLowerCase().includes(search.toLowerCase()) ||
      (p.member_id || "").toLowerCase().includes(search.toLowerCase()) ||
      (p.member_name || "").toLowerCase().includes(search.toLowerCase()) ||
      (p.receipt_id || "").toLowerCase().includes(search.toLowerCase()) ||
      (p.purpose || "").toLowerCase().includes(search.toLowerCase());

    return matchesStatus && matchesSearch;
  });

  return (
    <>
      <PageHeader
        title="Payments & Ledger"
        description={
          total > payments.length
            ? `Latest ${payments.length.toLocaleString("en-IN")} of ${total.toLocaleString("en-IN")} transactions (counts below cover the ones shown).`
            : "Transactions and their receipts for this Mahal."
        }
      />

      {error && <ErrorState message={error} onRetry={load} />}

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-lg">
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Transactions Shown</p>
          <h3 className="font-amount-lg text-amount-lg text-text-primary">{payments.length}</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Successful</p>
          <h3 className="font-amount-lg text-amount-lg text-success">{totalSuccess}</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Pending</p>
          <h3 className="font-amount-lg text-amount-lg text-warning">{totalPending}</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg">
          <p className="font-small text-small text-text-secondary mb-1">Failed</p>
          <h3 className="font-amount-lg text-amount-lg text-error">{totalFailed}</h3>
        </div>
      </div>

      <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
        <div className="p-lg border-b border-border-base flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <h3 className="font-card-title text-card-title text-text-primary">Transactions</h3>
          <div className="flex gap-2">
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                search
              </span>
              <input
                className="pl-9 pr-4 py-2 border border-border-base rounded-lg text-body font-body w-full sm:w-64 h-[44px] focus:border-primary focus:ring-0 outline-none"
                placeholder="Search ID, member, receipt..."
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            <select
              className="h-[44px] px-3 border border-border-base rounded-lg text-text-secondary bg-surface font-button text-small"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="ALL">All Status</option>
              <option value="SUCCESS">Success</option>
              <option value="PENDING">Pending</option>
              <option value="FAILED">Failed</option>
              <option value="REFUNDED">Refunded</option>
            </select>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low border-b border-border-base">
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">TXN ID</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">MEMBER</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">TYPE</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">AMOUNT</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">GATEWAY</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">DATE</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">STATUS</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold text-right">RECEIPT</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base">
              {filteredPayments.map((txn) => (
                <tr key={txn.id} className="hover:bg-surface-bright transition-colors">
                  <td className="py-4 px-lg font-button text-button text-text-primary">{txn.id}</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">
                    {txn.member_id ? (
                      <Link href={`/members/${encodeURIComponent(txn.member_id)}`} className="hover:text-primary">
                        {txn.member_name || txn.member_id}
                        {txn.member_name && <span className="block text-xs text-text-muted">{txn.member_id}</span>}
                      </Link>
                    ) : (
                      "—"
                    )}
                  </td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary">
                    {humanize(txn.type)}
                    {txn.purpose && <span className="block text-xs text-text-muted">Fund: {txn.purpose}</span>}
                  </td>
                  <td className="py-4 px-lg font-body text-body text-text-primary font-semibold whitespace-nowrap">{formatINR(txn.amount)}</td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary">
                    {txn.gateway || "—"}
                    {txn.payment_mode && <span className="block text-xs text-text-muted">{txn.payment_mode}</span>}
                  </td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary">
                    {formatDate(txn.completed_at || txn.created_at)}
                  </td>
                  <td className="py-4 px-lg">
                    <StatusBadge status={txn.status} />
                  </td>
                  <td className="py-4 px-lg text-right">
                    {txn.receipt_id ? (
                      <span className="text-xs font-mono bg-surface-container px-2 py-1 rounded text-primary">
                        {txn.receipt_id}
                      </span>
                    ) : (
                      <span className="text-xs text-text-muted">—</span>
                    )}
                  </td>
                </tr>
              ))}
              {filteredPayments.length === 0 && (
                <tr>
                  <td colSpan={8} className="py-8 text-center text-text-muted">
                    {loading ? "Loading transactions..." : payments.length === 0 ? "No transactions recorded yet." : "No transactions match these filters."}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}
