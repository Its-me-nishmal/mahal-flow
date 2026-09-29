"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";
import { EmptyState } from "@/components/ui/EmptyState";
import { FilterTabs } from "@/components/ui/FilterTabs";
import { StepBar } from "@/components/ui/StepBar";
import { useToast } from "@/components/ui/Toast";
import { ApiClient, ApiError, type ImportCommitResult, type ImportPreview } from "@/lib/api-client";
import { errorMessage, formatDateTime, formatINR, formatPhone } from "@/lib/format";
import { clearPreview, loadPreview } from "@/lib/import-session";

const FILTERS = ["All", "Valid", "Duplicate", "Invalid"];

function Count({ label, value, tone }: { label: string; value: number; tone: string }) {
  return (
    <div className="bg-surface rounded-xl border border-border-base p-lg text-center">
      <p className="font-small text-small text-text-muted">{label}</p>
      <h3 className={`font-amount-lg text-amount-lg ${tone}`}>{value.toLocaleString("en-IN")}</h3>
    </div>
  );
}

export default function ExcelImportPreviewPage() {
  const router = useRouter();
  const toast = useToast();
  const [preview, setPreview] = useState<ImportPreview | null | undefined>(undefined);
  const [filter, setFilter] = useState("All");
  const [committing, setCommitting] = useState(false);
  const [result, setResult] = useState<ImportCommitResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => setPreview(loadPreview()), []);

  if (preview === undefined) return null;

  if (result) {
    return (
      <>
        <PageHeader title="Import Complete" description={preview?.filename} />
        <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm max-w-2xl">
          <StepBar current={3} />
          <div className="flex items-start gap-3 mb-lg">
            <span className="material-symbols-outlined text-success text-[32px]">check_circle</span>
            <div>
              <p className="font-card-title text-card-title text-text-primary">
                {result.imported.toLocaleString("en-IN")} member{result.imported === 1 ? "" : "s"} imported
              </p>
              <p className="font-body text-body text-text-secondary">
                {result.skipped.toLocaleString("en-IN")} row{result.skipped === 1 ? "" : "s"} skipped
                {result.status === "ALREADY_COMMITTED" ? " (this file had already been imported)" : ""}.
              </p>
            </div>
          </div>
          <div className="flex gap-3">
            <Link href="/members" className="h-11 px-6 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors inline-flex items-center gap-2">
              <span className="material-symbols-outlined text-[18px]">group</span>
              View Members
            </Link>
            <Link href="/excel-import" className="h-11 px-6 bg-surface border border-border-base text-text-secondary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors inline-flex items-center">
              Import Another File
            </Link>
          </div>
        </div>
      </>
    );
  }

  if (!preview) {
    return (
      <>
        <PageHeader title="Import Preview" description="Review rows before importing." />
        <EmptyState
          icon="upload_file"
          title="No file uploaded"
          description="Upload a member sheet first; its rows are validated and shown here before anything is saved."
          actionLabel="Upload a File"
          onAction={() => router.push("/excel-import")}
        />
      </>
    );
  }

  const expired = preview.expires_at ? new Date(preview.expires_at).getTime() < Date.now() : false;
  const rows = preview.preview_rows.filter((r) => filter === "All" || r.status === filter.toUpperCase());

  const commit = async () => {
    setCommitting(true);
    setError(null);
    try {
      const res = await ApiClient.commitExcelImport(preview.batch_id);
      clearPreview();
      setResult(res);
      toast.success(`${res.imported} members imported.`);
    } catch (err) {
      const msg =
        err instanceof ApiError && err.status === 404
          ? "This upload has expired. Upload the file again."
          : errorMessage(err, "The import failed.");
      setError(msg);
      toast.error(msg);
      setCommitting(false);
    }
  };

  return (
    <>
      <PageHeader title="Import Preview" description={`${preview.filename} · validated against this Mahal's members`} />

      <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
        <StepBar current={1} />
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Count label="Total Rows" value={preview.total_rows} tone="text-text-primary" />
          <Count label="Valid" value={preview.valid_rows} tone="text-success" />
          <Count label="Duplicates" value={preview.duplicate_rows} tone="text-warning" />
          <Count label="Invalid" value={preview.invalid_rows} tone="text-error" />
        </div>
        <p className="text-xs text-text-muted mt-3">
          Only valid rows are imported. Upload expires {formatDateTime(preview.expires_at)}.
        </p>
      </div>

      {expired && (
        <div className="bg-warning-bg border border-warning/20 rounded-xl p-md text-sm text-warning">
          This upload has expired on the server. Upload the file again to import it.
        </div>
      )}

      <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm">
        <div className="p-md border-b border-border-base">
          <FilterTabs
            options={FILTERS}
            selected={filter}
            onSelect={setFilter}
            counts={{ All: preview.total_rows, Valid: preview.valid_rows, Duplicate: preview.duplicate_rows, Invalid: preview.invalid_rows }}
          />
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low border-b border-border-base">
                {["ROW", "NAME", "PHONE", "HOUSE", "DUES", "FAMILY HEAD", "STATUS", "ISSUES"].map((h) => (
                  <th key={h} className="font-small text-small text-text-secondary py-3 px-lg font-semibold whitespace-nowrap">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base">
              {rows.map((row) => (
                <tr
                  key={row.row}
                  className={
                    row.status === "INVALID" ? "bg-error-bg/30" : row.status === "DUPLICATE" ? "bg-warning-bg/30" : "hover:bg-surface-bright"
                  }
                >
                  <td className="py-3 px-lg text-text-muted">{row.row}</td>
                  <td className="py-3 px-lg text-text-primary">{row.name || <span className="text-error italic">Missing</span>}</td>
                  <td className="py-3 px-lg text-text-primary font-mono text-small whitespace-nowrap">{row.phone ? formatPhone(row.phone) : "—"}</td>
                  <td className="py-3 px-lg text-text-primary">{row.house_name || "—"}</td>
                  <td className="py-3 px-lg text-text-primary whitespace-nowrap">{row.monthly_dues > 0 ? formatINR(row.monthly_dues) : "Default"}</td>
                  <td className="py-3 px-lg text-text-primary">{row.family_head ? "Yes" : "No"}</td>
                  <td className="py-3 px-lg">
                    <StatusBadge status={row.status} />
                  </td>
                  <td className="py-3 px-lg text-xs text-text-secondary">{(row.errors || []).join("; ") || "—"}</td>
                </tr>
              ))}
              {rows.length === 0 && (
                <tr>
                  <td colSpan={8} className="py-8 text-center text-text-muted">
                    No {filter.toLowerCase()} rows.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {error && (
        <p className="text-sm text-error" role="alert">
          {error}
        </p>
      )}

      <div className="flex flex-wrap gap-3">
        <button
          onClick={commit}
          disabled={committing || expired || preview.valid_rows === 0}
          className="h-12 px-6 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {committing ? (
            <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
          ) : (
            <span className="material-symbols-outlined text-[18px]">check_circle</span>
          )}
          {committing
            ? "Importing..."
            : `Import ${preview.valid_rows.toLocaleString("en-IN")} Valid Member${preview.valid_rows === 1 ? "" : "s"}`}
        </button>
        <Link
          href="/excel-import"
          onClick={() => clearPreview()}
          className="h-12 px-6 bg-surface border border-border-base text-text-secondary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center"
        >
          Upload Different File
        </Link>
      </div>
    </>
  );
}
