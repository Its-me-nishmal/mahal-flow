"use client";

import React from "react";

interface FilterTabsProps {
  options: string[];
  selected: string;
  onSelect: (option: string) => void;
  counts?: Record<string, number>;
  className?: string;
}

export function FilterTabs({
  options,
  selected,
  onSelect,
  counts,
  className = "",
}: FilterTabsProps) {
  return (
    <div className={`flex flex-wrap items-center gap-1.5 p-1 bg-surface-container-low border border-border-base rounded-xl ${className}`}>
      {options.map((opt) => {
        const isSelected = opt === selected;
        const count = counts?.[opt];

        return (
          <button
            key={opt}
            onClick={() => onSelect(opt)}
            className={`h-8 px-3.5 rounded-lg text-xs font-semibold transition-all flex items-center gap-1.5 ${
              isSelected
                ? "bg-primary text-on-primary shadow-sm"
                : "text-text-secondary hover:text-text-primary hover:bg-surface"
            }`}
          >
            <span>{opt}</span>
            {count !== undefined && (
              <span
                className={`px-1.5 py-0.5 rounded-full text-[10px] font-bold ${
                  isSelected
                    ? "bg-white/20 text-white"
                    : "bg-surface-container-high text-text-muted"
                }`}
              >
                {count}
              </span>
            )}
          </button>
        );
      })}
    </div>
  );
}
