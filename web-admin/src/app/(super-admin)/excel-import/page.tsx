"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/ui/PageHeader";
import { useToast } from "@/components/ui/Toast";
import { ApiClient } from "@/lib/api-client";
import { errorMessage } from "@/lib/format";
import { savePreview } from "@/lib/import-session";
import { cn } from "@/lib/cn";
import { StepBar } from "@/components/ui/StepBar";

const MAX_BYTES = 5 * 1024 * 1024; // server limit
const COLUMNS = ["name", "phone", "house_name", "monthly_dues", "family_head", "family_members_count", "email", "member_code"];


function downloadTemplate() {
  const csv = COLUMNS.join(",") + "\n";
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "mahalflow_member_import_template.csv";
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

export default function ExcelImportPage() {
  const router = useRouter();
  const toast = useToast();
  const inputRef = useRef<HTMLInputElement>(null);
  const [file, setFile] = useState<File | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [dragging, setDragging] = useState(false);

  const pick = (f: File | null | undefined) => {
    setError(null);
    if (!f) return;
    const name = f.name.toLowerCase();
    if (!name.endsWith(".xlsx") && !name.endsWith(".csv")) {
      setFile(null);
      setError("Upload an .xlsx or .csv file. Save legacy .xls files as .xlsx first.");
      return;
    }
    if (f.size > MAX_BYTES) {
      setFile(null);
      setError("The file is larger than 5 MB.");
      return;
    }
    setFile(f);
  };

  const upload = async () => {
    if (!file) return;
    setUploading(true);
    setError(null);
    try {
      const preview = await ApiClient.uploadExcelPreview(file);
      savePreview(preview);
      toast.success(`${preview.total_rows} rows read from ${preview.filename}.`);
      router.push("/excel-import/preview");
    } catch (err) {
      setError(errorMessage(err, "Could not read the file."));
      setUploading(false);
    }
  };

  return (
    <>
      <PageHeader title="Bulk Member Import" description="Import a member roster from an Excel (.xlsx) or CSV file into this Mahal." />

      <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm max-w-2xl">
        <StepBar current={0} />

        <div
          role="button"
          tabIndex={0}
          onClick={() => !uploading && inputRef.current?.click()}
          onKeyDown={(e) => (e.key === "Enter" || e.key === " ") && inputRef.current?.click()}
          onDragOver={(e) => {
            e.preventDefault();
            setDragging(true);
          }}
          onDragLeave={() => setDragging(false)}
          onDrop={(e) => {
            e.preventDefault();
            setDragging(false);
            pick(e.dataTransfer.files?.[0]);
          }}
          className={cn(
            "border-2 border-dashed rounded-xl p-xl text-center cursor-pointer transition-colors mb-lg",
            dragging ? "border-primary bg-primary-fixed/20" : "border-border-base hover:bg-surface-container-low"
          )}
        >
          <span className="material-symbols-outlined text-[48px] text-text-muted mb-4 block">upload_file</span>
          {file ? (
            <>
              <p className="font-card-title text-card-title text-text-primary mb-1 break-all">{file.name}</p>
              <p className="font-body text-body text-text-secondary">{(file.size / 1024).toLocaleString("en-IN", { maximumFractionDigits: 1 })} KB · click to choose another</p>
            </>
          ) : (
            <>
              <p className="font-card-title text-card-title text-text-primary mb-1">Drop your file here or click to browse</p>
              <p className="font-body text-body text-text-secondary">.xlsx or .csv, up to 5 MB and 2,000 rows.</p>
            </>
          )}
          <input
            ref={inputRef}
            type="file"
            accept=".xlsx,.csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,text/csv"
            className="hidden"
            onChange={(e) => {
              pick(e.target.files?.[0]);
              e.target.value = "";
            }}
          />
        </div>

        {error && (
          <p className="text-sm text-error mb-lg" role="alert">
            {error}
          </p>
        )}

        <div className="flex flex-wrap gap-3 mb-lg">
          <button
            onClick={upload}
            disabled={!file || uploading}
            className="h-11 px-6 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors inline-flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {uploading ? (
              <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
            ) : (
              <span className="material-symbols-outlined text-[18px]">fact_check</span>
            )}
            {uploading ? "Validating..." : "Upload & Validate"}
          </button>
          <button
            onClick={downloadTemplate}
            className="h-11 px-4 bg-surface border border-border-base text-text-primary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors inline-flex items-center gap-2"
          >
            <span className="material-symbols-outlined text-[18px]">download</span>
            CSV Template
          </button>
        </div>

        <div className="bg-info-bg border border-info/20 rounded-xl p-md flex items-start gap-3">
          <span className="material-symbols-outlined text-info mt-0.5">info</span>
          <div>
            <p className="font-button text-button text-info">Expected columns</p>
            <p className="font-small text-small text-text-secondary mt-1">
              Required: <b>name</b>, <b>phone</b> (10-digit Indian mobile; +91 / 0 prefixes are accepted). Optional:
              house_name, monthly_dues (blank = Mahal default), family_head (yes/no), family_members_count, email,
              member_code. Phones already registered in this Mahal are flagged as duplicates. Nothing is saved until
              you confirm on the next step.
            </p>
          </div>
        </div>
      </div>
    </>
  );
}
