"use client";

import { useState } from "react";

export function TopBar({ title }: { title?: string }) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <header className="sticky top-0 z-40 flex justify-between items-center px-lg w-full h-16 bg-surface border-b border-border-base shadow-sm md:shadow-none md:border-none">
      <div className="flex items-center gap-4">
        <button
          className="md:hidden text-text-primary p-1 rounded-md hover:bg-surface-container-low cursor-pointer active:opacity-80 transition-colors"
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
        >
          <span className="material-symbols-outlined">menu</span>
        </button>
        {title && (
          <h2 className="font-page-title text-page-title text-primary md:hidden">
            {title}
          </h2>
        )}
        <div className="hidden md:flex items-center bg-surface-container-low rounded-full px-4 py-2 w-64 border border-border-base focus-within:border-primary transition-colors">
          <span className="material-symbols-outlined text-text-muted mr-2 text-[18px]">
            search
          </span>
          <input
            className="bg-transparent border-none outline-none text-body font-body text-text-primary w-full placeholder-text-muted focus:ring-0 p-0"
            placeholder="Search Mahals, transactions..."
            type="text"
          />
        </div>
      </div>
      <div className="flex items-center gap-4">
        <button className="text-text-secondary hover:bg-surface-container-low p-2 rounded-full cursor-pointer active:opacity-80 transition-colors relative">
          <span className="material-symbols-outlined">notifications</span>
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-error rounded-full border border-surface" />
        </button>
        <button className="hidden md:flex items-center gap-2 text-text-secondary font-button text-button hover:text-primary transition-colors cursor-pointer">
          <span className="material-symbols-outlined text-[20px]">
            help_outline
          </span>
          Support
        </button>
        <div className="w-8 h-8 rounded-full bg-primary-container flex items-center justify-center cursor-pointer border border-border-base ml-2 overflow-hidden text-on-primary font-button text-button">
          SA
        </div>
      </div>
    </header>
  );
}
