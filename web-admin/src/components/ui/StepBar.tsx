import { cn } from "@/lib/cn";

export function StepBar({ current }: { current: number }) {
  const steps = ["Upload", "Preview", "Import"];
  return (
    <ol className="flex items-center gap-3 mb-lg">
      {steps.map((step, i) => (
        <li key={step} className="flex items-center gap-2">
          <span
            className={cn(
              "w-7 h-7 rounded-full flex items-center justify-center font-button text-small",
              i === current ? "bg-primary-container text-on-primary" : i < current ? "bg-success text-white" : "bg-surface-container-high text-text-muted"
            )}
          >
            {i + 1}
          </span>
          <span className={cn("font-button text-small", i === current ? "text-text-primary" : "text-text-muted")}>{step}</span>
          {i < steps.length - 1 && <span className="w-6 h-px bg-border-base" />}
        </li>
      ))}
    </ol>
  );
}

