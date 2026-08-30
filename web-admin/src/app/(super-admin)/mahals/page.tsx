"use client";

import { useEffect, useState } from "react";
import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { ApiClient } from "@/lib/api-client";

export default function MahalDirectoryPage() {
  const [mahals, setMahals] = useState<any[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    ApiClient.getMahals()
      .then((res) => {
        if (res && res.mahals) {
          setMahals(res.mahals);
        }
      })
      .catch((err) => console.error("Error loading mahals:", err))
      .finally(() => setLoading(false));
  }, []);

  const filteredMahals = mahals.filter((m) =>
    (m.name || "").toLowerCase().includes(search.toLowerCase()) ||
    (m.id || "").toLowerCase().includes(search.toLowerCase()) ||
    (m.contact?.address || "").toLowerCase().includes(search.toLowerCase())
  );

  return (
    <>
      <PageHeader
        title="Mahal Directory"
        description="Manage all registered Mahals across the platform from live database."
        actions={
          <a
            href="/mahals/new"
            className="px-4 py-2 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center gap-2 h-[44px]"
          >
            <span className="material-symbols-outlined text-[18px]">add</span>
            Add New Mahal
          </a>
        }
      />

      <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
        <div className="p-lg border-b border-border-base flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex gap-2">
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                search
              </span>
              <input
                className="pl-9 pr-4 py-2 border border-border-base rounded-lg text-body font-body w-full sm:w-72 h-[44px] focus:border-primary focus:ring-0 outline-none"
                placeholder="Search Mahals..."
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low border-b border-border-base">
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  MAHAL NAME
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  LOCATION
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  STATUS
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  PHONE
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                  PLAN
                </th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap text-right">
                  ACTIONS
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base">
              {filteredMahals.map((mahal) => (
                <tr key={mahal.id} className="hover:bg-surface-bright transition-colors">
                  <td className="py-4 px-lg">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-lg bg-surface-container flex items-center justify-center shrink-0 border border-border-base">
                        <span className="material-symbols-outlined text-text-secondary text-[20px]">
                          mosque
                        </span>
                      </div>
                      <div>
                        <p className="font-button text-button text-text-primary">
                          {mahal.name}
                        </p>
                        <p className="font-small text-small text-text-muted">
                          {mahal.id}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">
                    {mahal.contact?.address || "Calicut, Kerala"}
                  </td>
                  <td className="py-4 px-lg">
                    <StatusBadge status={mahal.subscription?.status || "ACTIVE"} />
                  </td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">
                    {mahal.contact?.phone || "N/A"}
                  </td>
                  <td className="py-4 px-lg font-body text-body text-text-secondary">
                    {mahal.subscription?.plan || "STANDARD"}
                  </td>
                  <td className="py-4 px-lg text-right">
                    <div className="flex items-center justify-end gap-1">
                      <a
                        href={`/mahals/${mahal.id}`}
                        className="text-text-secondary hover:text-primary p-2 rounded-lg hover:bg-surface-container-low transition-colors"
                      >
                        <span className="material-symbols-outlined">visibility</span>
                      </a>
                    </div>
                  </td>
                </tr>
              ))}
              {filteredMahals.length === 0 && (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-text-muted">
                    {loading ? "Loading Mahals from live MongoDB..." : "No Mahals match your criteria."}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
        <div className="p-md border-t border-border-base flex items-center justify-between bg-surface-container-lowest">
          <p className="font-small text-small text-text-secondary">
            Showing {filteredMahals.length} of {mahals.length} entries
          </p>
        </div>
      </div>
    </>
  );
}
