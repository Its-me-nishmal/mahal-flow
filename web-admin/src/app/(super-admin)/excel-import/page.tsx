import { PageHeader } from "@/components/ui/PageHeader";

export default function ExcelImportPage() {
  return (
    <>
      <PageHeader
        title="Bulk Excel Import"
        description="Import member rosters from Excel or CSV files."
      />

      <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm max-w-2xl">
        <div className="flex items-center gap-3 mb-lg">
          {["1. Upload", "2. Validate", "3. Preview", "4. Confirm", "5. Done"].map((step, i) => (
            <div key={step} className="flex items-center gap-2">
              <div
                className={`w-7 h-7 rounded-full flex items-center justify-center font-button text-small ${
                  i === 0
                    ? "bg-primary-container text-on-primary"
                    : "bg-surface-container-high text-text-muted"
                }`}
              >
                {i + 1}
              </div>
              <span
                className={`font-button text-small hidden sm:inline ${
                  i === 0 ? "text-text-primary" : "text-text-muted"
                }`}
              >
                {step.split(". ")[1]}
              </span>
              {i < 4 && <div className="w-4 h-px bg-border-base hidden sm:block" />}
            </div>
          ))}
        </div>

        <div className="border-2 border-dashed border-border-base rounded-xl p-xl text-center hover:bg-surface-container-low cursor-pointer transition-colors mb-lg">
          <span className="material-symbols-outlined text-[48px] text-text-muted mb-4 block">
            upload_file
          </span>
          <p className="font-card-title text-card-title text-text-primary mb-1">
            Drop your file here or click to browse
          </p>
          <p className="font-body text-body text-text-secondary mb-4">
            Supports .xlsx and .csv files. Max 10MB.
          </p>
          <button className="h-11 px-6 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors inline-flex items-center gap-2">
            <span className="material-symbols-outlined text-[18px]">folder_open</span>
            Choose File
          </button>
        </div>

        <div className="bg-info-bg border border-info/20 rounded-xl p-md flex items-start gap-3">
          <span className="material-symbols-outlined text-info mt-0.5">info</span>
          <div>
            <p className="font-button text-button text-info">Expected Format</p>
            <p className="font-small text-small text-text-secondary mt-1">
              Your file should include columns: Name, Phone, House Name, Family Head (yes/no),
              Monthly Dues Amount. Phone numbers will be auto-sanitized to E.164 format.
            </p>
          </div>
        </div>
      </div>
    </>
  );
}
