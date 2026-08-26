"use client";

import { Sidebar } from "@/components/layout/Sidebar";
import { TopBar } from "@/components/layout/TopBar";

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
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
