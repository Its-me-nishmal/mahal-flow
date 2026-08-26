"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/cn";

const navItems = [
  { label: "Dashboard", icon: "dashboard", href: "/dashboard" },
  { label: "Members", icon: "group", href: "/members" },
  { label: "Payments", icon: "payments", href: "/payments" },
  { label: "Subscriptions", icon: "card_membership", href: "/subscriptions" },
  { label: "Settings", icon: "settings", href: "/settings" },
];

const mobileNavItems = [
  { label: "Home", icon: "dashboard", href: "/dashboard" },
  { label: "Members", icon: "group", href: "/members" },
  { label: "Payments", icon: "payments", href: "/payments" },
  { label: "Profile", icon: "person", href: "/profile" },
];

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();

  return (
    <div className="min-h-screen bg-bg-app">
      {/* Desktop Sidebar */}
      <nav className="hidden md:flex flex-col w-72 h-screen fixed left-0 top-0 bg-surface border-r border-border-base z-50">
        <div className="px-6 pt-8 pb-6">
          <div className="flex items-center gap-3 mb-6">
            <div className="w-12 h-12 rounded-full bg-primary-container flex items-center justify-center text-on-primary font-button text-button shrink-0">
              AP
            </div>
            <div>
              <h2 className="font-card-title text-card-title text-text-primary">
                Mahal Admin
              </h2>
              <p className="font-small text-small text-text-secondary">
                System Administrator
              </p>
            </div>
          </div>
          <span className="font-small text-small text-text-muted bg-surface-container-low px-2 py-0.5 rounded">
            v1.2.0
          </span>
        </div>

        <div className="flex-1 overflow-y-auto px-3 space-y-1 scrollbar-hide">
          {navItems.map((item) => {
            const isActive =
              pathname === item.href ||
              pathname.startsWith(item.href + "/");
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "flex items-center gap-3 px-3 py-2.5 rounded-lg cursor-pointer active:scale-95 duration-200 transition-all group",
                  isActive
                    ? "bg-primary-fixed font-bold text-on-primary-fixed-variant"
                    : "text-text-secondary hover:bg-surface-container-low hover:text-primary"
                )}
              >
                <span
                  className={cn(
                    "material-symbols-outlined text-[22px] transition-colors",
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

        <div className="px-3 pb-6 mt-auto">
          <Link
            href="/login"
            className="flex items-center gap-3 px-3 py-2.5 text-error hover:bg-error-bg rounded-lg cursor-pointer active:scale-95 duration-200 transition-all"
          >
            <span className="material-symbols-outlined text-[22px]">
              logout
            </span>
            <span className="font-button text-button">Log Out</span>
          </Link>
        </div>
      </nav>

      {/* Mobile TopAppBar */}
      <header className="md:hidden fixed top-0 left-0 right-0 h-16 bg-surface border-b border-border-base flex items-center justify-between px-4 z-40">
        <button className="text-text-primary p-1 rounded-md hover:bg-surface-container-low cursor-pointer active:opacity-80 transition-colors">
          <span className="material-symbols-outlined">menu</span>
        </button>
        <h1 className="font-card-title text-card-title text-primary">
          MahalFlow Admin
        </h1>
        <div className="flex items-center gap-3">
          <button className="text-text-secondary p-1 rounded-full hover:bg-surface-container-low cursor-pointer active:opacity-80 transition-colors relative">
            <span className="material-symbols-outlined">notifications</span>
            <span className="absolute top-0.5 right-0.5 w-2 h-2 bg-error rounded-full" />
          </button>
          <div className="w-8 h-8 rounded-full bg-primary-container flex items-center justify-center text-on-primary font-button text-small overflow-hidden">
            AP
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="md:ml-72 px-4 md:px-8 pt-20 pb-24 md:pt-4 md:pb-8">
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
              <span className="font-small text-small">{item.label}</span>
            </Link>
          );
        })}
      </nav>
    </div>
  );
}
