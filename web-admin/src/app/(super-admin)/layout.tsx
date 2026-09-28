"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Sidebar } from "@/components/layout/Sidebar";
import { TopBar } from "@/components/layout/TopBar";
import { ApiClient } from "@/lib/api-client";

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const [authorized, setAuthorized] = useState(false);

  useEffect(() => {
    if (!ApiClient.isAuthenticated()) {
      router.replace("/login");
    } else {
      setAuthorized(true);
    }
  }, [router]);

  if (!authorized) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-background text-text-muted text-sm font-medium">
        <span className="w-5 h-5 border-2 border-primary/30 border-t-primary rounded-full animate-spin mr-2.5" />
        Verifying admin session...
      </div>
    );
  }

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 md:ml-64 flex flex-col min-h-screen">
        <TopBar />
        <div className="p-margin-mobile md:p-margin-desktop flex-1 overflow-x-hidden space-y-xl max-w-7xl mx-auto w-full">
          {children}
        </div>
      </main>
    </div>
  );
}
