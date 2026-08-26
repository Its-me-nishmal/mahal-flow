import { PageHeader } from "@/components/ui/PageHeader";
import { StatusBadge } from "@/components/ui/StatusBadge";

export default function ExcelImportPreviewPage() {
  const previewData = [
    { row: 1, name: "Ahmed Khan", phone: "+919876543210", house: "Khan Villa", familyHead: "Yes", status: "Valid" },
    { row: 2, name: "Fatima Begum", phone: "+919123456789", house: "Begum House", familyHead: "No", status: "Valid" },
    { row: 3, name: "Mohammed Raza", phone: "9876512345", house: "Raza Manzil", familyHead: "Yes", status: "Valid" },
    { row: 4, name: "Duplicate Entry", phone: "+919876543210", house: "Khan Villa", familyHead: "No", status: "Duplicate" },
    { row: 5, name: "", phone: "123", house: "Unknown", familyHead: "No", status: "Invalid" },
  ];

  return (
    <>
      <PageHeader
        title="Import Preview"
        description="Review and validate data before importing."
      />

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-lg">
        <div className="bg-surface rounded-xl border border-border-base p-lg text-center">
          <p className="font-small text-small text-text-muted">Total Rows</p>
          <h3 className="font-amount-lg text-amount-lg text-text-primary">5</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg text-center">
          <p className="font-small text-small text-text-muted">Valid</p>
          <h3 className="font-amount-lg text-amount-lg text-success">3</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg text-center">
          <p className="font-small text-small text-text-muted">Duplicates</p>
          <h3 className="font-amount-lg text-amount-lg text-warning">1</h3>
        </div>
        <div className="bg-surface rounded-xl border border-border-base p-lg text-center">
          <p className="font-small text-small text-text-muted">Invalid</p>
          <h3 className="font-amount-lg text-amount-lg text-error">1</h3>
        </div>
      </div>

      <div className="bg-surface border border-border-base rounded-xl overflow-hidden shadow-sm mb-lg">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-surface-container-low border-b border-border-base">
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">ROW</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">NAME</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">PHONE</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">HOUSE</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">FAMILY HEAD</th>
                <th className="font-small text-small text-text-secondary py-3 px-lg font-semibold">STATUS</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border-base">
              {previewData.map((row) => (
                <tr key={row.row} className={`transition-colors ${row.status === "Invalid" ? "bg-error-bg/30" : row.status === "Duplicate" ? "bg-warning-bg/30" : "hover:bg-surface-bright"}`}>
                  <td className="py-4 px-lg font-body text-body text-text-muted">{row.row}</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">{row.name || <span className="text-error italic">Missing</span>}</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary font-mono text-small">{row.phone}</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">{row.house}</td>
                  <td className="py-4 px-lg font-body text-body text-text-primary">{row.familyHead}</td>
                  <td className="py-4 px-lg"><StatusBadge status={row.status} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="flex gap-3">
        <button className="h-12 px-6 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center gap-2">
          <span className="material-symbols-outlined text-[18px]">check_circle</span>
          Import 3 Valid Members
        </button>
        <a
          href="/excel-import"
          className="h-12 px-6 bg-surface border border-border-base text-text-secondary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center"
        >
          Upload Different File
        </a>
      </div>
    </>
  );
}
