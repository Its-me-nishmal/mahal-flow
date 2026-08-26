"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/cn";

const navItems = [
  { label: "Dashboard", icon: "dashboard", href: "/dashboard" },
  { label: "Mahals", icon: "location_city", href: "/mahals" },
  { label: "Members", icon: "group", href: "/members" },
  { label: "Payments", icon: "payments", href: "/payments" },
  { label: "Subscriptions", icon: "card_membership", href: "/subscriptions" },
  { label: "Gateways", icon: "account_balance_wallet", href: "/gateways" },
  { label: "Refunds", icon: "undo", href: "/refunds" },
  { label: "Reports", icon: "assessment", href: "/reports" },
  { label: "Audit Logs", icon: "history_edu", href: "/audit-logs" },
  { label: "Alerts", icon: "notifications", href: "/alerts" },
  { label: "Settings", icon: "settings", href: "/settings" },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <nav className="hidden md:flex flex-col h-screen w-64 fixed left-0 top-0 border-r border-border-base bg-surface p-md gap-xs shadow-[0_2px_8px_rgba(23,32,29,0.08)] z-50">
      <div className="flex items-center gap-sm mb-lg px-sm pt-sm cursor-pointer">
        <div className="w-10 h-10 rounded-lg bg-primary-container flex items-center justify-center shrink-0">
          <span className="material-symbols-outlined text-on-primary-container text-[22px]">
            account_balance
          </span>
        </div>
        <div>
          <h1 className="font-section-title text-section-title text-primary">
            MahalFlow
          </h1>
          <p className="font-small text-small text-text-secondary">
            Super Admin Portal
          </p>
        </div>
      </div>

      <button className="w-full py-2 px-4 mb-md bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center justify-center gap-2 cursor-pointer active:scale-95 duration-200">
        <span className="material-symbols-outlined text-[18px]">add</span>
        New Report
      </button>

      <div className="flex-1 overflow-y-auto space-y-1 scrollbar-hide">
        {navItems.map((item) => {
          const isActive = pathname === item.href || pathname.startsWith(item.href + "/");
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-3 px-3 py-2 rounded-lg cursor-pointer active:scale-95 duration-200 transition-all group",
                isActive
                  ? "bg-primary-fixed font-bold text-on-primary-fixed-variant"
                  : "text-text-secondary hover:bg-surface-container-low hover:text-primary"
              )}
            >
              <span
                className={cn(
                  "material-symbols-outlined transition-colors",
                  isActive ? "" : "group-hover:text-primary"
                )}
              >
                {item.icon}
              </span>
              <span className="font-button text-button">{item.label}</span>
            </Link>
          );
        })}
      </div>

      <div className="mt-auto pt-4 border-t border-border-base">
        <Link
          href="/login"
          className="flex items-center gap-3 px-3 py-2 text-error hover:bg-error-bg rounded-lg cursor-pointer active:scale-95 duration-200 transition-all"
        >
          <span className="material-symbols-outlined">logout</span>
          <span className="font-button text-button">Log Out</span>
        </Link>
      </div>
    </nav>
  );
}
