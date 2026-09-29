"use client";

import { useCallback, useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { Sidebar } from "@/components/layout/Sidebar";
import { TopBar } from "@/components/layout/TopBar";
import { ToastProvider } from "@/components/ui/Toast";
import { ApiClient } from "@/lib/api-client";

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [authorized, setAuthorized] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [unreadAlerts, setUnreadAlerts] = useState(0);

  useEffect(() => {
    if (!ApiClient.isAuthenticated()) {
      router.replace("/login");
    } else {
      setAuthorized(true);
    }
  }, [router]);

  // Active (unacknowledged) admin alerts drive the bell dot and sidebar badge.
  const refreshAlerts = useCallback(() => {
    ApiClient.getAlerts()
      .then((res) => setUnreadAlerts((res?.alerts || []).filter((a: any) => a.status === "ACTIVE").length))
      .catch(() => setUnreadAlerts(0));
  }, []);

  useEffect(() => {
    window.addEventListener("mahalflow:alerts-changed", refreshAlerts);
    return () => window.removeEventListener("mahalflow:alerts-changed", refreshAlerts);
  }, [refreshAlerts]);

  useEffect(() => {
    if (authorized) refreshAlerts();
    setMobileOpen(false);
  }, [authorized, pathname, refreshAlerts]);

  if (!authorized) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-background text-text-muted text-sm font-medium">
        <span className="w-5 h-5 border-2 border-primary/30 border-t-primary rounded-full animate-spin mr-2.5" />
        Verifying admin session...
      </div>
    );
  }

  return (
    <ToastProvider>
      <div className="flex min-h-screen">
        <Sidebar unreadAlerts={unreadAlerts} mobileOpen={mobileOpen} onClose={() => setMobileOpen(false)} />
        <main className="flex-1 md:ml-64 flex flex-col min-h-screen min-w-0">
          <TopBar unreadAlerts={unreadAlerts} onMenu={() => setMobileOpen(true)} />
          <div className="p-margin-mobile md:p-margin-desktop flex-1 overflow-x-hidden space-y-xl max-w-7xl mx-auto w-full">
            {children}
          </div>
        </main>
      </div>
    </ToastProvider>
  );
}
