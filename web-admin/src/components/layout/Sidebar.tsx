"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/cn";
import { ApiClient } from "@/lib/api-client";
import { MahalFlowLogo } from "@/components/ui/MahalFlowLogo";

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
  { label: "Alerts", icon: "notifications", href: "/alerts", isAlerts: true },
  { label: "Settings", icon: "settings", href: "/settings" },
];

export function Sidebar() {
  const pathname = usePathname();
  const [unreadAlerts, setUnreadAlerts] = useState<number>(0);

  useEffect(() => {
    ApiClient.getAlerts("MH_001_CALICUT")
      .then((res) => {
        if (res && res.alerts) {
          const active = res.alerts.filter((a: any) => a.status === "ACTIVE").length;
          setUnreadAlerts(active);
        }
      })
      .catch(() => {});
  }, [pathname]);

  return (
    <nav className="hidden md:flex flex-col h-screen w-64 fixed left-0 top-0 border-r border-border-base bg-surface p-md gap-xs shadow-[0_2px_8px_rgba(23,32,29,0.08)] z-50">
      <Link href="/dashboard" className="flex items-center gap-sm mb-lg px-sm pt-sm cursor-pointer hover:opacity-90 transition-opacity">
        <MahalFlowLogo size="lg" />
      </Link>

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
                "flex items-center justify-between px-3 py-2 rounded-lg cursor-pointer active:scale-95 duration-200 transition-all group",
                isActive
                  ? "bg-primary-fixed font-bold text-on-primary-fixed-variant"
                  : "text-text-secondary hover:bg-surface-container-low hover:text-primary"
              )}
            >
              <div className="flex items-center gap-3">
                <span
                  className={cn(
                    "material-symbols-outlined transition-colors",
                    isActive ? "" : "group-hover:text-primary"
                  )}
                >
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
