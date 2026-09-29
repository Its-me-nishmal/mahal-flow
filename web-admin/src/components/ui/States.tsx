import { ShimmerSkeleton } from "@/components/ui/ShimmerSkeleton";

export function LoadingBlock({ rows = 4, label = "Loading..." }: { rows?: number; label?: string }) {
  return (
    <div className="bg-surface border border-border-base rounded-xl p-lg space-y-3" aria-busy="true" aria-label={label}>
      {Array.from({ length: rows }).map((_, i) => (
        <ShimmerSkeleton key={i} height={18} className="w-full" />
      ))}
    </div>
  );
}

export function ErrorState({
  title = "Could not load this page",
  message,
  onRetry,
}: {
  title?: string;
  message?: string;
  onRetry?: () => void;
}) {
  return (
    <div className="bg-error-bg border border-error/20 rounded-xl p-lg flex flex-col sm:flex-row sm:items-center gap-4" role="alert">
      <span className="material-symbols-outlined text-error text-[28px]">error</span>
      <div className="flex-1">
        <p className="font-button text-button text-error">{title}</p>
        {message && <p className="font-small text-small text-text-secondary mt-1 break-words">{message}</p>}
      </div>
      {onRetry && (
        <button
          onClick={onRetry}
          className="h-10 px-4 bg-surface border border-error/30 text-error rounded-lg font-button text-small hover:bg-surface-container-low transition-colors flex items-center gap-2 self-start sm:self-auto"
        >
          <span className="material-symbols-outlined text-[18px]">refresh</span>
          Retry
        </button>
      )}
    </div>
  );
}
