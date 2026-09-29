"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/cn";
import { ApiClient } from "@/lib/api-client";
import { MahalFlowLogo } from "@/components/ui/MahalFlowLogo";

interface NavItem {
  label: string;
  icon: string;
  href: string;
  isAlerts?: boolean;
}

function navFor(superAdmin: boolean, tenant: string): NavItem[] {
  return [
    { label: "Dashboard", icon: "dashboard", href: "/dashboard" },
    superAdmin
      ? { label: "Mahals", icon: "location_city", href: "/mahals" }
      : { label: "My Mahal", icon: "mosque", href: `/mahals/${encodeURIComponent(tenant)}` },
    { label: "Members", icon: "group", href: "/members" },
    { label: "Import Members", icon: "upload_file", href: "/excel-import" },
    { label: "Payments", icon: "payments", href: "/payments" },
    ...(superAdmin ? [{ label: "Subscriptions", icon: "card_membership", href: "/subscriptions" }] : []),
    { label: "Gateways", icon: "account_balance_wallet", href: "/gateways" },
    { label: "Refunds", icon: "undo", href: "/refunds" },
    { label: "Reports", icon: "assessment", href: "/reports" },
    { label: "Audit Logs", icon: "history_edu", href: "/audit-logs" },
    { label: "Alerts", icon: "notifications", href: "/alerts", isAlerts: true },
    { label: "Settings", icon: "settings", href: "/settings" },
  ];
}

export function Sidebar({
  unreadAlerts,
  mobileOpen,
  onClose,
}: {
  unreadAlerts: number;
  mobileOpen: boolean;
  onClose: () => void;
}) {
  const pathname = usePathname();
  const navItems = navFor(ApiClient.isSuperAdmin(), ApiClient.getTenant());

  return (
    <>
      {mobileOpen && <div className="md:hidden fixed inset-0 bg-black/40 z-40" onClick={onClose} aria-hidden="true" />}
      <nav
        className={cn(
          "flex flex-col h-screen w-64 fixed left-0 top-0 border-r border-border-base bg-surface p-md gap-xs shadow-[0_2px_8px_rgba(23,32,29,0.08)] z-50 transition-transform duration-200",
          mobileOpen ? "translate-x-0" : "-translate-x-full md:translate-x-0"
        )}
        aria-label="Main navigation"
      >
        <div className="flex items-center justify-between mb-lg px-sm pt-sm">
          <Link href="/dashboard" onClick={onClose} className="flex items-center gap-sm cursor-pointer hover:opacity-90 transition-opacity">
            <MahalFlowLogo size="lg" />
          </Link>
          <button onClick={onClose} className="md:hidden text-text-secondary p-1 rounded-md" aria-label="Close menu">
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>

        <Link
          href="/reports"
          onClick={onClose}
          className="w-full py-2 px-4 mb-md bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center justify-center gap-2 cursor-pointer active:scale-95 duration-200"
        >
          <span className="material-symbols-outlined text-[18px]">add</span>
          New Report
        </Link>

        <div className="flex-1 overflow-y-auto space-y-1 scrollbar-hide">
          {navItems.map((item) => {
            const isActive = pathname === item.href || pathname.startsWith(item.href + "/");
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onClose}
                className={cn(
                  "flex items-center justify-between px-3 py-2 rounded-lg cursor-pointer active:scale-95 duration-200 transition-all group",
                  isActive
                    ? "bg-primary-fixed font-bold text-on-primary-fixed-variant"
                    : "text-text-secondary hover:bg-surface-container-low hover:text-primary"
                )}
              >
                <div className="flex items-center gap-3">
                  <span className={cn("material-symbols-outlined transition-colors", isActive ? "" : "group-hover:text-primary")}>
                    {item.icon}
                  </span>
                  <span className="font-button text-button">{item.label}</span>
                </div>
                {item.isAlerts && unreadAlerts > 0 && (
                  <span className="inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 text-xs font-bold bg-error text-white rounded-full">
                    {unreadAlerts}
                  </span>
                )}
              </Link>
            );
          })}
        </div>

        <div className="mt-auto pt-4 border-t border-border-base">
          <button
            onClick={() => ApiClient.logout()}
            className="w-full flex items-center gap-3 px-3 py-2 text-error hover:bg-error-bg rounded-lg cursor-pointer active:scale-95 duration-200 transition-all text-left"
          >
            <span className="material-symbols-outlined">logout</span>
            <span className="font-button text-button">Log Out</span>
          </button>
        </div>
      </nav>
    </>
  );
}
