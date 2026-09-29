"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ApiClient } from "@/lib/api-client";
import { initials } from "@/lib/format";

export function TopBar({ unreadAlerts, onMenu }: { unreadAlerts: number; onMenu: () => void }) {
  const router = useRouter();
  const [query, setQuery] = useState("");
  const user = ApiClient.getUser();
  const name: string = user?.name || "";
  const role = user?.role === "SUPER_ADMIN" ? "Super Admin" : "Mahal Admin";

  const submitSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const q = query.trim();
    router.push(q ? `/members?q=${encodeURIComponent(q)}` : "/members");
  };

  return (
    <header className="sticky top-0 z-30 flex justify-between items-center px-lg w-full h-16 bg-surface border-b border-border-base shadow-sm md:shadow-none md:border-none">
      <div className="flex items-center gap-4">
        <button
          className="md:hidden text-text-primary p-1 rounded-md hover:bg-surface-container-low cursor-pointer active:opacity-80 transition-colors"
          onClick={onMenu}
          aria-label="Open menu"
        >
          <span className="material-symbols-outlined">menu</span>
        </button>
        <form
          onSubmit={submitSearch}
          role="search"
          className="hidden md:flex items-center bg-surface-container-low rounded-full px-4 py-2 w-72 border border-border-base focus-within:border-primary transition-colors"
        >
          <span className="material-symbols-outlined text-text-muted mr-2 text-[18px]">search</span>
          <input
            className="bg-transparent border-none outline-none text-body font-body text-text-primary w-full placeholder-text-muted focus:ring-0 p-0"
            placeholder="Search members by name, phone, house..."
            type="search"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            aria-label="Search members"
          />
        </form>
      </div>
      <div className="flex items-center gap-4">
        <Link
          href="/alerts"
          className="text-text-secondary hover:bg-surface-container-low p-2 rounded-full cursor-pointer active:opacity-80 transition-colors relative"
          aria-label={unreadAlerts > 0 ? `Alerts: ${unreadAlerts} active` : "Alerts"}
          title={unreadAlerts > 0 ? `${unreadAlerts} active alert${unreadAlerts === 1 ? "" : "s"}` : "No active alerts"}
        >
          <span className="material-symbols-outlined">notifications</span>
          {unreadAlerts > 0 && <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-error rounded-full border border-surface" />}
        </Link>
        <Link href="/settings" className="flex items-center gap-2 ml-2" title={`${name || "Signed in"} (${role})`}>
          <span className="hidden md:flex flex-col items-end leading-tight">
            <span className="text-sm font-semibold text-text-primary">{name || "Admin"}</span>
            <span className="text-xs text-text-muted">{role}</span>
          </span>
          <span className="w-8 h-8 rounded-full bg-primary-container flex items-center justify-center border border-border-base overflow-hidden text-on-primary font-button text-button">
            {initials(name)}
          </span>
        </Link>
      </div>
    </header>
  );
}
