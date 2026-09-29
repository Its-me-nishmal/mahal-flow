const IST = "Asia/Kolkata";

const inr = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", minimumFractionDigits: 0, maximumFractionDigits: 2 });

/** ₹ amount in Indian grouping ("₹1,23,456"). Missing values render as "—". */
export function formatINR(amount: number | null | undefined): string {
  if (amount === null || amount === undefined || Number.isNaN(Number(amount))) return "—";
  return inr.format(Number(amount));
}

function toDate(value: string | number | Date | null | undefined): Date | null {
  if (value === null || value === undefined || value === "") return null;
  const d = value instanceof Date ? value : new Date(value);
  // Go zero time ("0001-01-01T00:00:00Z") means "not set".
  if (Number.isNaN(d.getTime()) || d.getUTCFullYear() <= 1) return null;
  return d;
}

/** "29 Sept 2026" in IST, or "—". */
export function formatDate(value: string | number | Date | null | undefined): string {
  const d = toDate(value);
  return d ? d.toLocaleDateString("en-IN", { timeZone: IST, day: "2-digit", month: "short", year: "numeric" }) : "—";
}

/** "29 Sept 2026, 3:04 pm" in IST, or "—". */
export function formatDateTime(value: string | number | Date | null | undefined): string {
  const d = toDate(value);
  return d
    ? d.toLocaleString("en-IN", { timeZone: IST, day: "2-digit", month: "short", year: "numeric", hour: "numeric", minute: "2-digit" })
    : "—";
}

/** "2026-08" -> "Aug 2026"; anything else passes through, empty -> "—". */
export function formatMonth(ym: string | null | undefined): string {
  if (!ym) return "—";
  const m = /^(\d{4})-(\d{2})$/.exec(ym);
  if (!m) return ym;
  const d = new Date(Date.UTC(Number(m[1]), Number(m[2]) - 1, 1));
  return d.toLocaleDateString("en-IN", { timeZone: "UTC", month: "short", year: "numeric" });
}

/** Up to two initials from a name ("Arangod Mahal" -> "AM"). */
export function initials(name: string | null | undefined): string {
  const parts = (name || "").trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "?";
  return parts
    .slice(0, 2)
    .map((p) => p[0])
    .join("")
    .toUpperCase();
}

/** "+919847012345" -> "+91 98470 12345". Other formats pass through. */
export function formatPhone(phone: string | null | undefined): string {
  if (!phone) return "—";
  const m = /^\+91(\d{5})(\d{5})$/.exec(phone);
  return m ? `+91 ${m[1]} ${m[2]}` : phone;
}

/** 10-digit national part of an Indian mobile, for edit forms. */
export function nationalDigits(phone: string | null | undefined): string {
  const d = (phone || "").replace(/\D/g, "");
  if (d.length === 12 && d.startsWith("91")) return d.slice(2);
  return d;
}

export function humanize(value: string | null | undefined): string {
  if (!value) return "—";
  return value
    .toLowerCase()
    .split(/[_\s]+/)
    .filter(Boolean)
    .map((w) => w[0].toUpperCase() + w.slice(1))
    .join(" ");
}

export function errorMessage(err: unknown, fallback = "Something went wrong."): string {
  if (err instanceof Error && err.message) return err.message;
  return fallback;
}

export const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
/** Indian mobile: optional +91/91/0, then 10 digits starting 6-9. */
export function isIndianMobile(raw: string): boolean {
  let d = raw.replace(/[\s\-()+.]/g, "");
  if (!/^\d+$/.test(d)) return false;
  if (d.length === 12 && d.startsWith("91")) d = d.slice(2);
  else if (d.length === 11 && d.startsWith("0")) d = d.slice(1);
  return /^[6-9]\d{9}$/.test(d);
}
/** Mobile or 10-13 digit landline, matching the server's contact-phone rule. */
export function isContactPhone(raw: string): boolean {
  if (isIndianMobile(raw)) return true;
  if (!/^[\d\s+\-()]+$/.test(raw)) return false;
  const n = raw.replace(/\D/g, "").length;
  return n >= 10 && n <= 13;
}
