import { cn } from "@/lib/cn";

interface MetricCardProps {
  icon: string;
  iconBg?: string;
  iconColor?: string;
  label: string;
  value: string;
  trend?: { value: string; positive: boolean };
  footer?: React.ReactNode;
  className?: string;
  gradient?: boolean;
}

export function MetricCard({
  icon,
  iconBg = "bg-info-bg",
  iconColor = "text-info",
  label,
  value,
  trend,
  footer,
  className,
  gradient = false,
}: MetricCardProps) {
  return (
    <div
      className={cn(
        "bg-surface rounded-xl border border-border-base p-lg flex flex-col relative overflow-hidden group hover:-translate-y-1 transition-transform duration-200",
        className
      )}
    >
      {gradient && (
        <div className="absolute inset-0 bg-gradient-to-br from-primary-fixed-dim/20 to-transparent pointer-events-none" />
      )}
      <div className="relative z-10">
        <div className="flex justify-between items-start mb-4">
          <div className={cn("p-2 rounded-lg", iconBg)}>
            <span className={cn("material-symbols-outlined text-[22px]", iconColor)}>
              {icon}
            </span>
          </div>
          {trend && (
            <span
              className={cn(
                "flex items-center gap-1 font-button text-small px-2 py-1 rounded-full",
                trend.positive
                  ? "text-success bg-success-bg"
                  : "text-warning bg-warning-bg"
              )}
            >
              <span className="material-symbols-outlined text-[14px]">
                {trend.positive ? "trending_up" : "trending_flat"}
              </span>
              {trend.value}
            </span>
          )}
        </div>
        <p className="font-small text-small text-text-secondary mb-1">{label}</p>
        <h3 className="font-amount-lg text-amount-lg text-text-primary">{value}</h3>
        {footer && (
          <div className="mt-4 pt-4 border-t border-border-base">{footer}</div>
        )}
      </div>
    </div>
  );
}
