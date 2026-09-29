"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { useParams, useRouter } from "next/navigation";
import { PageHeader } from "@/components/ui/PageHeader";
import { ErrorState, LoadingBlock } from "@/components/ui/States";
import { FormField, inputClass, fieldBorder } from "@/components/ui/FormField";
import { useToast } from "@/components/ui/Toast";
import { ApiClient } from "@/lib/api-client";
import { cn } from "@/lib/cn";
import { EMAIL_RE, errorMessage, isIndianMobile, nationalDigits } from "@/lib/format";

const STATUSES = [
  { value: "ACTIVE", label: "Active" },
  { value: "GRACE_PERIOD", label: "Grace Period" },
  { value: "SUSPENDED", label: "Suspended" },
  { value: "INACTIVE", label: "Inactive" },
];

interface Values {
  name: string;
  phone: string;
  email: string;
  house_name: string;
  address2: string;
  city: string;
  state: string;
  pincode: string;
  monthly_dues: string;
  status: string;
  family_members_count: string;
  family_head: boolean;
}
type Errors = Partial<Record<keyof Values, string>>;

function toValues(m: any): Values {
  return {
    name: m.name || "",
    phone: nationalDigits(m.phone),
    email: m.email || "",
    house_name: m.house_name || "",
    address2: m.address2 || "",
    city: m.city || "",
    state: m.state || "",
    pincode: m.pincode || "",
    monthly_dues: m.monthly_dues_custom_amount ? String(m.monthly_dues_custom_amount) : "",
    status: m.status || "ACTIVE",
    family_members_count: m.family_members_count ? String(m.family_members_count) : "",
    family_head: !!m.family_head,
  };
}

function validate(v: Values): Errors {
  const e: Errors = {};
  if (!v.name.trim()) e.name = "Name is required.";
  if (!v.phone.trim()) e.phone = "Phone is required.";
  else if (!isIndianMobile(v.phone.trim())) e.phone = "Enter a 10-digit Indian mobile number.";
  if (v.email.trim() && !EMAIL_RE.test(v.email.trim())) e.email = "Enter a valid email address.";
  if (v.pincode.trim() && !/^\d{6}$/.test(v.pincode.trim())) e.pincode = "PIN code is 6 digits.";
  if (v.monthly_dues.trim()) {
    const d = Number(v.monthly_dues);
    if (!Number.isFinite(d) || d <= 0) e.monthly_dues = "Enter an amount above 0, or leave blank for the Mahal default.";
  }
  if (v.family_members_count.trim()) {
    const n = Number(v.family_members_count);
    if (!Number.isInteger(n) || n < 1 || n > 100) e.family_members_count = "Between 1 and 100.";
  }
  return e;
}

export default function EditMemberPage() {
  const { id } = useParams<{ id: string }>();
  const memberId = decodeURIComponent(id);
  const router = useRouter();
  const toast = useToast();
  const [member, setMember] = useState<any | null>(null);
  const [v, setV] = useState<Values | null>(null);
  const [errors, setErrors] = useState<Errors>({});
  const [loadError, setLoadError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  const load = useCallback(() => {
    setLoadError(null);
    setMember(null);
    ApiClient.getMemberProfile(memberId)
      .then((m) => {
        setMember(m);
        setV(toValues(m));
      })
      .catch((err) => setLoadError(errorMessage(err, "Could not load this member.")));
  }, [memberId]);

  useEffect(() => {
    load();
  }, [load]);

  const set = <K extends keyof Values>(k: K, val: Values[K]) => {
    setV((prev) => (prev ? { ...prev, [k]: val } : prev));
    if (errors[k]) setErrors((prev) => ({ ...prev, [k]: undefined }));
  };

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!v) return;
    const errs = validate(v);
    setErrors(errs);
    if (Object.keys(errs).length > 0) return;
    setSaving(true);
    try {
      await ApiClient.updateMemberProfile(memberId, {
        name: v.name.trim(),
        phone: v.phone.trim(),
        email: v.email.trim(),
        house_name: v.house_name.trim(),
        address2: v.address2.trim(),
        city: v.city.trim(),
        state: v.state.trim(),
        pincode: v.pincode.trim(),
        // Pending / rejected registrations change via approval, not this form.
        ...(v.status !== member.status ? { status: v.status } : {}),
        family_head: v.family_head,
        ...(v.monthly_dues.trim() ? { monthly_dues_custom_amount: Number(v.monthly_dues) } : {}),
        ...(v.family_members_count.trim() ? { family_members_count: Number(v.family_members_count) } : {}),
      });
      toast.success("Member details saved.");
      router.push(`/members/${encodeURIComponent(memberId)}`);
    } catch (err) {
      toast.error(errorMessage(err, "Could not save the changes."));
      setSaving(false);
    }
  };

  const text = (k: keyof Values, label: string, opts: { type?: string; placeholder?: string; required?: boolean; hint?: string; inputMode?: "numeric" | "decimal" | "tel" | "email" } = {}) => (
    <FormField label={label} htmlFor={`member-${k}`} error={errors[k]} required={opts.required} hint={opts.hint}>
      <input
        id={`member-${k}`}
        className={cn(inputClass, fieldBorder(errors[k]))}
        type={opts.type || "text"}
        inputMode={opts.inputMode}
        placeholder={opts.placeholder}
        value={(v?.[k] as string) ?? ""}
        disabled={saving}
        onChange={(e) => set(k, e.target.value as any)}
        aria-invalid={!!errors[k]}
      />
    </FormField>
  );

  return (
    <>
      <PageHeader title="Edit Member Details" description={member ? `${member.name} · ${member.member_code || member.id}` : memberId} />
      <div className="max-w-3xl">
        {loadError ? (
          <ErrorState message={loadError} onRetry={load} />
        ) : !member || !v ? (
          <LoadingBlock rows={8} />
        ) : (
          <form onSubmit={submit} noValidate className="bg-surface border border-border-base rounded-xl p-lg shadow-sm flex flex-col gap-lg">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-lg">
              {text("name", "Full Name", { required: true })}
              {text("phone", "Phone Number", { required: true, type: "tel", inputMode: "tel", placeholder: "10-digit mobile", hint: "Also the member's login." })}
              {text("email", "Email", { type: "email", inputMode: "email" })}
              {text("house_name", "House Name")}
              {text("address2", "Street / Area")}
              {text("city", "City")}
              {text("state", "State")}
              {text("pincode", "PIN Code", { inputMode: "numeric" })}
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-lg">
              {text("monthly_dues", "Monthly Dues (₹)", {
                type: "number",
                inputMode: "decimal",
                hint: member.dues_rate_source === "MAHAL_DEFAULT" ? "Currently the Mahal default." : undefined,
              })}
              <FormField label="Status" htmlFor="member-status">
                <select
                  id="member-status"
                  className={cn(inputClass, "border-border-base")}
                  value={v.status}
                  disabled={saving}
                  onChange={(e) => set("status", e.target.value)}
                >
                  {!STATUSES.some((s) => s.value === v.status) && <option value={v.status}>{v.status}</option>}
                  {STATUSES.map((s) => (
                    <option key={s.value} value={s.value}>
                      {s.label}
                    </option>
                  ))}
                </select>
              </FormField>
              {text("family_members_count", "Family Members", { type: "number", inputMode: "numeric" })}
            </div>
            <label className="flex items-center gap-3 p-3 border border-border-base rounded-lg cursor-pointer">
              <input
                type="checkbox"
                checked={v.family_head}
                disabled={saving}
                onChange={(e) => set("family_head", e.target.checked)}
                className="w-4 h-4 accent-[#146c5b]"
              />
              <span className="font-button text-button text-text-primary">Family head</span>
            </label>
            <div className="flex gap-3 pt-lg border-t border-border-base">
              <button
                type="submit"
                disabled={saving}
                className="h-12 px-6 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
              >
                {saving ? (
                  <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                ) : (
                  <span className="material-symbols-outlined text-[18px]">save</span>
                )}
                {saving ? "Saving..." : "Save Changes"}
              </button>
              <Link
                href={`/members/${encodeURIComponent(memberId)}`}
                className="h-12 px-6 bg-surface border border-border-base text-text-secondary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center"
              >
                Cancel
              </Link>
            </div>
          </form>
        )}
      </div>
    </>
  );
}
