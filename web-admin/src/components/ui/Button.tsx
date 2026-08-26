import { cn } from "@/lib/cn";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "danger" | "ghost";
  size?: "sm" | "md" | "lg";
  icon?: string;
  children: React.ReactNode;
}

export function Button({
  variant = "primary",
  size = "md",
  icon,
  children,
  className,
  ...props
}: ButtonProps) {
  const variants = {
    primary:
      "bg-primary-container text-on-primary hover:bg-primary active:bg-primary",
    secondary:
      "bg-surface border border-primary text-primary hover:bg-surface-container-low",
    danger: "bg-error text-on-error hover:bg-error/90",
    ghost: "bg-transparent text-text-secondary hover:bg-surface-container-low",
  };

  const sizes = {
    sm: "h-8 px-3 text-small",
    md: "h-11 px-4 text-button",
    lg: "h-12 px-6 text-button",
  };

  return (
    <button
      className={cn(
        "font-button rounded-lg transition-colors flex items-center justify-center gap-2 cursor-pointer active:scale-95 duration-200 disabled:opacity-50 disabled:cursor-not-allowed",
        variants[variant],
        sizes[size],
        className
      )}
      {...props}
    >
      {icon && (
        <span className="material-symbols-outlined text-[18px]">{icon}</span>
      )}
      {children}
    </button>
  );
}
