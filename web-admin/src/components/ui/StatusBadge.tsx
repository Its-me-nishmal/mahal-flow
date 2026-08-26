import { cn } from "@/lib/cn";

type StatusVariant = "ACTIVE" | "GRACE_PERIOD" | "READ_ONLY" | "SUSPENDED" | "PENDING" | "SUCCESS" | "FAILED" | "REFUNDED" | "CANCELLED";

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
};

export function StatusBadge({ status }: { status: string }) {
  const variant = (status.toUpperCase().replace(/\s+/g, "_") as StatusVariant) || "PENDING";
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
      {status}
    </span>
  );
}
