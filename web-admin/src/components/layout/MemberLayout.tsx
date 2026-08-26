"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/cn";

const mobileNavItems = [
  { label: "Home", icon: "home", href: "/dashboard" },
  { label: "Payments", icon: "payments", href: "/payments" },
  { label: "Receipts", icon: "receipt_long", href: "/receipts" },
  { label: "Alerts", icon: "notifications", href: "/alerts", badge: true },
  { label: "Profile", icon: "person", href: "/profile" },
];

const desktopNavItems = [
  { label: "Home", href: "/dashboard" },
  { label: "Payments", href: "/payments" },
  { label: "Receipts", href: "/receipts" },
  { label: "Alerts", href: "/alerts" },
];

export default function MemberLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();

  return (
    <div className="min-h-screen bg-bg-app">
      {/* Mobile TopAppBar */}
      <header className="md:hidden fixed top-0 left-0 right-0 h-16 bg-surface border-b border-border-base flex items-center justify-between px-4 z-40">
        <button className="text-text-primary p-1 rounded-md hover:bg-surface-container-low cursor-pointer active:opacity-80 transition-colors">
          <span className="material-symbols-outlined">menu</span>
        </button>
        <h1 className="font-card-title text-card-title text-primary">
          MahalFlow
        </h1>
        <div className="flex items-center gap-3">
          <button className="text-text-secondary p-1 rounded-full hover:bg-surface-container-low cursor-pointer active:opacity-80 transition-colors relative">
            <span className="material-symbols-outlined">notifications</span>
            <span className="absolute top-0.5 right-0.5 w-2 h-2 bg-error rounded-full" />
          </button>
          <div className="w-8 h-8 rounded-full bg-primary-container flex items-center justify-center text-on-primary font-button text-small overflow-hidden">
            M
          </div>
        </div>
      </header>

      {/* Desktop Top Header */}
      <header className="hidden md:flex fixed top-0 left-0 right-0 h-16 bg-surface border-b border-border-base items-center justify-between px-8 z-40">
        <div className="flex items-center gap-8">
          <h1 className="font-card-title text-card-title text-primary">
            MahalFlow
          </h1>
          <nav className="flex items-center gap-6">
            {desktopNavItems.map((item) => {
              const isActive =
                pathname === item.href ||
                pathname.startsWith(item.href + "/");
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "font-button text-button py-5 border-b-2 transition-colors cursor-pointer",
                    isActive
                      ? "text-text-primary border-primary"
                      : "text-text-muted border-transparent hover:text-text-secondary"
                  )}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>
        </div>
        <div className="flex items-center gap-4">
          <button className="text-text-secondary p-2 rounded-full hover:bg-surface-container-low cursor-pointer active:opacity-80 transition-colors relative">
            <span className="material-symbols-outlined">notifications</span>
            <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-error rounded-full border border-surface" />
          </button>
          <div className="flex items-center gap-2 cursor-pointer">
            <div className="w-8 h-8 rounded-full bg-primary-container flex items-center justify-center text-on-primary font-button text-small overflow-hidden">
              M
            </div>
            <span className="font-button text-button text-text-primary">
              Muhammed
            </span>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="px-4 md:px-8 pt-20 pb-24 md:pt-20 md:pb-8">
        {children}
      </main>

      {/* Mobile Bottom Nav */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 h-16 bg-surface border-t border-border-base flex items-center justify-around z-40">
        {mobileNavItems.map((item) => {
          const isActive =
            pathname === item.href ||
            pathname.startsWith(item.href + "/");
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex flex-col items-center justify-center gap-0.5 relative w-full py-1 cursor-pointer transition-colors",
                isActive ? "text-text-primary" : "text-text-muted"
              )}
            >
              {isActive && (
                <span className="absolute top-0 left-1/2 -translate-x-1/2 w-8 h-0.5 bg-primary rounded-full" />
              )}
              <span className="material-symbols-outlined text-[22px]">
                {item.icon}
              </span>
              {item.badge && (
                <span className="absolute top-1 right-1/2 translate-x-3 w-2 h-2 bg-error rounded-full" />
              )}
              <span className="font-small text-small">{item.label}</span>
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
