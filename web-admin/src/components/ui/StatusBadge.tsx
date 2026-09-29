import { cn } from "@/lib/cn";

type StatusVariant = "ACTIVE" | "GRACE_PERIOD" | "READ_ONLY" | "SUSPENDED" | "PENDING" | "SUCCESS" | "FAILED" | "REFUNDED" | "CANCELLED" | "REJECTED" | "PENDING_APPROVAL" | "NOT_CONFIGURED" | "INITIALIZED" | "INACTIVE" | "APPROVED" | "PROCESSED" | "VALID" | "DUPLICATE" | "INVALID";

const variantStyles: Record<StatusVariant, string> = {
  ACTIVE: "bg-success-bg text-success",
  SUCCESS: "bg-success-bg text-success",
  GRACE_PERIOD: "bg-warning-bg text-warning",
  PENDING: "bg-warning-bg text-warning",
  READ_ONLY: "bg-surface-variant text-text-secondary",
  SUSPENDED: "bg-error-bg text-error",
  FAILED: "bg-error-bg text-error",
  CANCELLED: "bg-surface-variant text-text-secondary",
  REFUNDED: "bg-info-bg text-info",
  REJECTED: "bg-error-bg text-error",
  PENDING_APPROVAL: "bg-warning-bg text-warning",
  NOT_CONFIGURED: "bg-error-bg text-error",
  INITIALIZED: "bg-warning-bg text-warning",
  INACTIVE: "bg-surface-variant text-text-secondary",
  APPROVED: "bg-success-bg text-success",
  PROCESSED: "bg-success-bg text-success",
  VALID: "bg-success-bg text-success",
  DUPLICATE: "bg-warning-bg text-warning",
  INVALID: "bg-error-bg text-error",
};

const dotStyles: Record<StatusVariant, string> = {
  ACTIVE: "bg-success",
  SUCCESS: "bg-success",
  GRACE_PERIOD: "bg-warning",
  PENDING: "bg-warning",
  READ_ONLY: "bg-text-secondary",
  SUSPENDED: "bg-error",
  FAILED: "bg-error",
  CANCELLED: "bg-text-secondary",
  REFUNDED: "bg-info",
  REJECTED: "bg-error",
  PENDING_APPROVAL: "bg-warning",
  NOT_CONFIGURED: "bg-error",
  INITIALIZED: "bg-warning",
  INACTIVE: "bg-text-secondary",
  APPROVED: "bg-success",
  PROCESSED: "bg-success",
  VALID: "bg-success",
  DUPLICATE: "bg-warning",
  INVALID: "bg-error",
};

/** "GRACE_PERIOD" -> "Grace Period". */
function statusLabel(status: string): string {
  return status
    .toLowerCase()
    .split(/[_\s]+/)
    .filter(Boolean)
    .map((w) => w[0].toUpperCase() + w.slice(1))
    .join(" ");
}

export function StatusBadge({ status }: { status?: string | null }) {
  if (!status) return <span className="text-xs text-text-muted">—</span>;
  const variant = status.toUpperCase().replace(/\s+/g, "_") as StatusVariant;
  const styles = variantStyles[variant] || "bg-surface-variant text-text-secondary";
  const dot = dotStyles[variant] || "bg-text-secondary";

  return (
    <span
      className={cn(
        "inline-flex items-center px-2 py-1 rounded-full font-small text-small gap-1",
        styles
      )}
    >
      <span className={cn("w-1.5 h-1.5 rounded-full", dot)} />
      {statusLabel(status)}
    </span>
  );
}
