import React from "react";

interface ShimmerSkeletonProps {
  className?: string;
  width?: string | number;
  height?: string | number;
}

export function ShimmerSkeleton({ className = "", width, height }: ShimmerSkeletonProps) {
  return (
    <div
      className={`animate-pulse bg-surface-container-high/60 rounded-lg ${className}`}
      style={{
        width: typeof width === "number" ? `${width}px` : width,
        height: typeof height === "number" ? `${height}px` : height,
      }}
    />
  );
}

export function ShimmerCardSkeleton() {
  return (
    <div className="bg-surface border border-border-base rounded-xl p-lg space-y-4 animate-pulse">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-surface-container-high" />
          <div className="space-y-2">
            <div className="w-28 h-4 bg-surface-container-high rounded" />
            <div className="w-20 h-3 bg-surface-container-high rounded" />
          </div>
        </div>
        <div className="w-16 h-6 bg-surface-container-high rounded-full" />
      </div>
      <div className="space-y-2 border-t border-border-base pt-3">
        <div className="w-full h-3 bg-surface-container-high rounded" />
        <div className="w-3/4 h-3 bg-surface-container-high rounded" />
      </div>
    </div>
  );
}
