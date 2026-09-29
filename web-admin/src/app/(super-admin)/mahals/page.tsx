"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { EmptyState } from "@/components/ui/EmptyState";
import { ErrorState, LoadingBlock } from "@/components/ui/States";
import { ApiClient, type Mahal } from "@/lib/api-client";
import { errorMessage, formatINR, formatPhone, humanize } from "@/lib/format";

export default function MahalDirectoryPage() {
  const router = useRouter();
  const [mahals, setMahals] = useState<Mahal[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    // A Mahal admin has exactly one Mahal: go straight to it.
    if (!ApiClient.isSuperAdmin()) {
      router.replace(`/mahals/${encodeURIComponent(ApiClient.getTenant())}`);
      return;
    }
    setLoading(true);
    setError(null);
    ApiClient.getMahals()
      .then((res) => setMahals(res?.mahals || []))
      .catch((err) => setError(errorMessage(err, "Could not load Mahals.")))
      .finally(() => setLoading(false));
  }, [router]);

  useEffect(() => {
    load();
  }, [load]);

  const q = search.trim().toLowerCase();
  const filtered = mahals.filter(
    (m) =>
      !q ||
      (m.name || "").toLowerCase().includes(q) ||
      (m.id || "").toLowerCase().includes(q) ||
      (m.registration_number || "").toLowerCase().includes(q) ||
      (m.contact?.address || "").toLowerCase().includes(q)
  );

  return (
    <>
      <PageHeader
        title="Mahal Directory"
        description="All Mahals registered on the platform."
        actions={
          <Link
            href="/mahals/new"
            className="px-4 py-2 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center gap-2 h-[44px]"
          >
            <span className="material-symbols-outlined text-[18px]">add</span>
            Add New Mahal
          </Link>
        }
      />

      {error ? (
        <ErrorState message={error} onRetry={load} />
      ) : loading ? (
        <LoadingBlock rows={6} />
      ) : mahals.length === 0 ? (
        <EmptyState
          icon="location_city"
          title="No Mahals yet"
          description="Register the first Mahal to start onboarding members."
          actionLabel="Add New Mahal"
          onAction={() => router.push("/mahals/new")}
        />
      ) : (
        <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
          <div className="p-lg border-b border-border-base">
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">search</span>
              <input
                className="pl-9 pr-4 py-2 border border-border-base rounded-lg text-body font-body w-full sm:w-72 h-[44px] focus:border-primary focus:ring-0 outline-none"
                placeholder="Search name, ID, registration, address..."
                type="search"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface-container-low border-b border-border-base">
                  {["MAHAL NAME", "ADDRESS", "STATUS", "PHONE", "DEFAULT DUES", "PLAN"].map((h) => (
                    <th key={h} className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                      {h}
                    </th>
                  ))}
                  <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap text-right">ACTIONS</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-base">
                {filtered.map((mahal) => (
                  <tr key={mahal.id} className="hover:bg-surface-bright transition-colors">
                    <td className="py-4 px-lg">
                      <Link href={`/mahals/${encodeURIComponent(mahal.id)}`} className="flex items-center gap-3 group">
                        <div className="w-10 h-10 rounded-lg bg-surface-container flex items-center justify-center shrink-0 border border-border-base">
                          <span className="material-symbols-outlined text-text-secondary text-[20px]">mosque</span>
                        </div>
                        <div>
                          <p className="font-button text-button text-text-primary group-hover:text-primary">{mahal.name || "—"}</p>
                          <p className="font-small text-small text-text-muted">{mahal.id}</p>
                        </div>
                      </Link>
                    </td>
                    <td className="py-4 px-lg font-body text-body text-text-primary max-w-[240px] truncate">{mahal.contact?.address || "—"}</td>
                    <td className="py-4 px-lg">
                      <StatusBadge status={mahal.subscription?.status} />
                    </td>
                    <td className="py-4 px-lg font-body text-body text-text-primary whitespace-nowrap">{formatPhone(mahal.contact?.phone)}</td>
                    <td className="py-4 px-lg font-body text-body text-text-primary">{formatINR(mahal.settings?.default_monthly_dues ?? 0)}</td>
                    <td className="py-4 px-lg font-body text-body text-text-secondary">{mahal.subscription?.plan ? humanize(mahal.subscription.plan) : "—"}</td>
                    <td className="py-4 px-lg text-right">
                      <div className="flex items-center justify-end gap-1">
                        <Link
                          href={`/mahals/${encodeURIComponent(mahal.id)}`}
                          className="text-text-secondary hover:text-primary p-2 rounded-lg hover:bg-surface-container-low transition-colors"
                          aria-label={`View ${mahal.name}`}
                        >
                          <span className="material-symbols-outlined">visibility</span>
                        </Link>
                        <Link
                          href={`/mahals/${encodeURIComponent(mahal.id)}/edit`}
                          className="text-text-secondary hover:text-primary p-2 rounded-lg hover:bg-surface-container-low transition-colors"
                          aria-label={`Edit ${mahal.name}`}
                        >
                          <span className="material-symbols-outlined">edit</span>
                        </Link>
                      </div>
                    </td>
                  </tr>
                ))}
                {filtered.length === 0 && (
                  <tr>
                    <td colSpan={7} className="py-8 text-center text-text-muted">
                      No Mahals match &quot;{search}&quot;.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
          <div className="p-md border-t border-border-base bg-surface-container-lowest">
            <p className="font-small text-small text-text-secondary">
              Showing {filtered.length} of {mahals.length} Mahals
            </p>
          </div>
        </div>
      )}
    </>
  );
}
