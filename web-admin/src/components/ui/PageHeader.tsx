import { cn } from "@/lib/cn";

interface PageHeaderProps {
  title: string;
  description?: string;
  actions?: React.ReactNode;
}

export function PageHeader({ title, description, actions }: PageHeaderProps) {
  return (
    <div className="flex flex-col md:flex-row md:items-end justify-between gap-4">
      <div>
        <h1 className="font-display text-display text-text-primary">{title}</h1>
        {description && (
          <p className="font-body text-body text-text-secondary mt-1">
            {description}
          </p>
        )}
      </div>
      {actions && <div className="flex gap-3">{actions}</div>}
    </div>
  );
}
