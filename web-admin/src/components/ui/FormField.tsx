import { cn } from "@/lib/cn";

export const inputClass =
  "h-12 px-4 rounded-lg border bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container focus:border-transparent placeholder:text-text-muted disabled:opacity-60 w-full";

export function FormField({
  label,
  htmlFor,
  error,
  hint,
  required,
  children,
  className,
}: {
  label: string;
  htmlFor: string;
  error?: string;
  hint?: string;
  required?: boolean;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <div className={cn("flex flex-col gap-sm", className)}>
      <label htmlFor={htmlFor} className="font-card-title text-card-title text-text-primary">
        {label}
        {required && <span className="text-error"> *</span>}
      </label>
      {children}
      {error ? (
        <p className="text-xs text-error" role="alert">
          {error}
        </p>
      ) : hint ? (
        <p className="text-xs text-text-muted">{hint}</p>
      ) : null}
    </div>
  );
}

export function fieldBorder(error?: string) {
  return error ? "border-error" : "border-border-base";
}
