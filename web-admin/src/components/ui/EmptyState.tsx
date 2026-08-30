import React from "react";

interface EmptyStateProps {
  icon?: string;
  title: string;
  description: string;
  actionLabel?: string;
  onAction?: () => void;
  className?: string;
}

export function EmptyState({
  icon = "search_off",
  title,
  description,
  actionLabel,
  onAction,
  className = "",
}: EmptyStateProps) {
  return (
    <div className={`flex flex-col items-center justify-center p-12 text-center bg-surface border border-border-base rounded-2xl ${className}`}>
      <div className="w-16 h-16 rounded-full bg-primary-container/20 flex items-center justify-center mb-4 text-primary">
        <span className="material-symbols-outlined text-[32px]">{icon}</span>
      </div>
      <h3 className="font-card-title text-card-title text-text-primary mb-1">{title}</h3>
      <p className="font-small text-small text-text-muted max-w-sm mb-6">{description}</p>
      {actionLabel && onAction && (
        <button
          onClick={onAction}
          className="px-4 py-2 bg-primary text-on-primary font-button text-button rounded-lg hover:bg-primary-dark transition-colors shadow-sm"
        >
          {actionLabel}
        </button>
      )}
    </div>
  );
}
