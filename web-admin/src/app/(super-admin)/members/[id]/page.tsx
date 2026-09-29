"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { ErrorState, LoadingBlock } from "@/components/ui/States";
import { ApiClient } from "@/lib/api-client";
import { errorMessage, formatDate, formatINR, formatMonth, formatPhone, humanize, initials } from "@/lib/format";

function Info({ icon, label, value }: { icon: string; label: string; value: React.ReactNode }) {
  return (
    <div className="flex items-center gap-3">
      <span className="material-symbols-outlined text-text-muted text-[20px]">{icon}</span>
      <div className="min-w-0">
        <p className="font-small text-small text-text-muted">{label}</p>
        <p className="font-body text-body text-text-primary break-words">{value}</p>
      </div>
    </div>
  );
}

function Tile({ label, value, tone }: { label: string; value: React.ReactNode; tone?: string }) {
  return (
    <div className="text-center p-3 bg-surface-container-low rounded-lg">
      <p className="font-small text-small text-text-muted">{label}</p>
      <p className={`font-card-title text-card-title ${tone || "text-text-primary"}`}>{value}</p>
    </div>
  );
}

export default function MemberDetailPage() {
  const { id } = useParams<{ id: string }>();
  const memberId = decodeURIComponent(id);
  const [member, setMember] = useState<any | null>(null);
  const [receipts, setReceipts] = useState<any[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [receiptsError, setReceiptsError] = useState<string | null>(null);

  const load = useCallback(() => {
    setError(null);
    setReceiptsError(null);
    setMember(null);
    setReceipts(null);
    ApiClient.getMemberProfile(memberId)
      .then(setMember)
      .catch((err) => setError(errorMessage(err, "Could not load this member.")));
    ApiClient.getMemberReceipts(memberId)
      .then((res) => setReceipts(res?.receipts || []))
      .catch((err) => setReceiptsError(errorMessage(err, "Could not load receipts.")));
  }, [memberId]);

  useEffect(() => {
    load();
  }, [load]);

  if (error) {
    return (
      <>
        <PageHeader title="Member Details" description={memberId} />
        <ErrorState message={error} onRetry={load} />
      </>
    );
  }
  if (!member) {
    return (
      <>
        <PageHeader title="Member Details" description={memberId} />
        <LoadingBlock rows={8} />
      </>
    );
  }

  const outstanding = Number(member.outstanding_balance || 0);
  const sorted = [...(receipts || [])].sort(
    (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  );
  const totalPaid = (receipts || []).reduce((sum, r) => sum + Number(r.amount || 0), 0);
  const location = [member.address2, member.city, member.state, member.pincode].filter(Boolean).join(", ");

  return (
    <>
      <PageHeader
        title={member.name || "Member Details"}
        description={`${member.member_code || member.id}${member.mahal_name ? ` · ${member.mahal_name}` : ""}`}
        actions={
          <Link
            href={`/members/${encodeURIComponent(member.id)}/edit`}
            className="px-4 py-2 bg-surface border border-primary text-primary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center gap-2 h-[44px]"
          >
            <span className="material-symbols-outlined text-[18px]">edit</span>
            Edit Member
          </Link>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-lg">
        <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
          <div className="flex flex-col items-center text-center mb-lg">
            <div className="w-20 h-20 rounded-full bg-primary-container flex items-center justify-center text-on-primary font-section-title text-section-title mb-3">
              {initials(member.name)}
            </div>
            <h2 className="font-card-title text-card-title text-text-primary">{member.name}</h2>
            <p className="font-small text-small text-text-muted">{member.member_code || member.id}</p>
            <div className="mt-2">
              <StatusBadge status={member.status} />
            </div>
          </div>
          <div className="space-y-4">
            <Info icon="phone" label="Phone" value={formatPhone(member.phone)} />
            <Info icon="mail" label="Email" value={member.email || "—"} />
            <Info icon="home" label="House Name" value={member.house_name || "—"} />
            {location && <Info icon="location_on" label="Address" value={location} />}
            <Info
              icon="family_restroom"
              label="Household"
              value={`${member.family_head ? "Family head" : "Not family head"}${
                member.family_members_count ? ` · ${member.family_members_count} members` : ""
              }`}
            />
            <Info icon="event" label="Registered" value={formatDate(member.created_at)} />
          </div>
        </div>

        <div className="lg:col-span-2 space-y-lg">
          <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
            <h3 className="font-card-title text-card-title text-text-primary mb-lg">Payment Summary</h3>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <Tile
                label={member.dues_rate_source === "MAHAL_DEFAULT" ? "Monthly Due (Mahal default)" : "Monthly Due"}
                value={formatINR(member.effective_monthly_dues ?? member.monthly_dues_custom_amount)}
              />
              <Tile label="Last Paid" value={formatMonth(member.last_paid_month)} />
              <Tile
                label={outstanding < 0 ? "Advance Credit" : "Outstanding"}
                value={formatINR(Math.abs(outstanding))}
                tone={outstanding > 0 ? "text-error" : "text-success"}
              />
              <Tile label="Total Paid" value={receipts ? formatINR(totalPaid) : "—"} />
            </div>
          </div>

          <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
            <div className="p-lg border-b border-border-base">
              <h3 className="font-card-title text-card-title text-text-primary">Receipts</h3>
            </div>
            {receiptsError ? (
              <div className="p-lg">
                <ErrorState title="Receipts unavailable" message={receiptsError} onRetry={load} />
              </div>
            ) : receipts === null ? (
              <div className="p-lg">
                <LoadingBlock rows={3} />
              </div>
            ) : sorted.length === 0 ? (
              <p className="p-lg text-sm text-text-muted">No receipts issued to this member yet.</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-surface-container-low border-b border-border-base">
                      {["DATE", "RECEIPT", "TYPE", "MONTHS", "AMOUNT"].map((h) => (
                        <th key={h} className="font-small text-small text-text-secondary py-3 px-lg font-semibold">
                          {h}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border-base">
                    {sorted.map((r) => (
                      <tr key={r.id || r.receipt_number} className="hover:bg-surface-bright transition-colors">
                        <td className="py-4 px-lg font-body text-body text-text-primary whitespace-nowrap">{formatDate(r.created_at)}</td>
                        <td className="py-4 px-lg font-mono text-xs text-primary">{r.receipt_number}</td>
                        <td className="py-4 px-lg font-body text-body text-text-secondary">{humanize(r.payment_type)}</td>
                        <td className="py-4 px-lg font-body text-body text-text-secondary">
                          {(r.paid_months || []).map(formatMonth).join(", ") || "—"}
                        </td>
                        <td className="py-4 px-lg font-body text-body text-text-primary font-semibold">{formatINR(r.amount)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      </div>
    </>
  );
}
