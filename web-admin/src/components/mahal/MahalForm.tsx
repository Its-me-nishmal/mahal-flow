"use client";

import { useState } from "react";
import Link from "next/link";
import { FormField, inputClass, fieldBorder } from "@/components/ui/FormField";
import { cn } from "@/lib/cn";
import { EMAIL_RE, isContactPhone, humanize } from "@/lib/format";
import { SUBSCRIPTION_STATUSES, type Mahal, type MahalInput, type SubscriptionStatus } from "@/lib/api-client";

export interface MahalFormValues {
  id: string;
  name: string;
  registration_number: string;
  email: string;
  phone: string;
  whatsapp: string;
  address: string;
  default_monthly_dues: string;
  dunning_enabled: boolean;
  autopay_allowed: boolean;
  sub_status: SubscriptionStatus;
  sub_plan: string;
  sub_fee: string;
}

export function emptyMahalValues(): MahalFormValues {
  return {
    id: "",
    name: "",
    registration_number: "",
    email: "",
    phone: "",
    whatsapp: "",
    address: "",
    default_monthly_dues: "",
    dunning_enabled: false,
    autopay_allowed: false,
    sub_status: "ACTIVE",
    sub_plan: "",
    sub_fee: "",
  };
}

export function mahalToValues(m: Mahal): MahalFormValues {
  const status = SUBSCRIPTION_STATUSES.includes(m.subscription?.status as SubscriptionStatus)
    ? (m.subscription.status as SubscriptionStatus)
    : "ACTIVE";
  return {
    id: m.id,
    name: m.name || "",
    registration_number: m.registration_number || "",
    email: m.contact?.email || "",
    phone: m.contact?.phone || "",
    whatsapp: m.contact?.whatsapp || "",
    address: m.contact?.address || "",
    default_monthly_dues: m.settings?.default_monthly_dues != null ? String(m.settings.default_monthly_dues) : "",
    dunning_enabled: !!m.settings?.dunning_enabled,
    autopay_allowed: !!m.settings?.autopay_allowed,
    sub_status: status,
    sub_plan: m.subscription?.plan || "",
    sub_fee: m.subscription?.monthly_fee != null ? String(m.subscription.monthly_fee) : "",
  };
}

type Errors = Partial<Record<keyof MahalFormValues, string>>;

const ID_RE = /^[A-Z0-9][A-Z0-9_-]{2,39}$/;

export function validateMahal(v: MahalFormValues, mode: "create" | "edit", withSubscription: boolean): Errors {
  const e: Errors = {};
  if (mode === "create" && v.id.trim() && !ID_RE.test(v.id.trim().toUpperCase())) {
    e.id = "3-40 characters: letters, digits, '_' or '-'.";
  }
  if (!v.name.trim()) e.name = "Name is required.";
  else if (v.name.trim().length > 120) e.name = "At most 120 characters.";
  if (v.registration_number.trim().length > 64) e.registration_number = "At most 64 characters.";
  if (v.email.trim() && !EMAIL_RE.test(v.email.trim())) e.email = "Enter a valid email address.";
  if (v.phone.trim() && !isContactPhone(v.phone.trim())) e.phone = "Enter a valid phone number.";
  if (v.whatsapp.trim() && !isContactPhone(v.whatsapp.trim())) e.whatsapp = "Enter a valid phone number.";
  if (v.address.trim().length > 500) e.address = "At most 500 characters.";
  if (v.default_monthly_dues.trim() !== "") {
    const d = Number(v.default_monthly_dues);
    if (!Number.isFinite(d) || d < 0) e.default_monthly_dues = "Must be 0 or more.";
    else if (d > 1_000_000) e.default_monthly_dues = "Too large.";
  }
  if (withSubscription) {
    if (v.sub_plan.trim().length > 40) e.sub_plan = "At most 40 characters.";
    if (v.sub_fee.trim() !== "") {
      const f = Number(v.sub_fee);
      if (!Number.isFinite(f) || f < 0) e.sub_fee = "Must be 0 or more.";
    }
  }
  return e;
}

export function valuesToInput(v: MahalFormValues, mode: "create" | "edit", withSubscription: boolean): MahalInput {
  const input: MahalInput = {
    name: v.name.trim(),
    registration_number: v.registration_number.trim(),
    contact: {
      email: v.email.trim(),
      phone: v.phone.trim(),
      whatsapp: v.whatsapp.trim(),
      address: v.address.trim(),
    },
    settings: {
      dunning_enabled: v.dunning_enabled,
      autopay_allowed: v.autopay_allowed,
      ...(v.default_monthly_dues.trim() !== "" ? { default_monthly_dues: Number(v.default_monthly_dues) } : {}),
    },
  };
  if (mode === "create" && v.id.trim()) input.id = v.id.trim().toUpperCase();
  if (withSubscription) {
    input.subscription = {
      status: v.sub_status,
      plan: v.sub_plan.trim(),
      ...(v.sub_fee.trim() !== "" ? { monthly_fee: Number(v.sub_fee) } : {}),
    };
  }
  return input;
}

function Toggle({
  id,
  label,
  hint,
  checked,
  onChange,
  disabled,
}: {
  id: string;
  label: string;
  hint: string;
  checked: boolean;
  onChange: (v: boolean) => void;
  disabled?: boolean;
}) {
  return (
    <label htmlFor={id} className="flex items-start gap-3 p-3 border border-border-base rounded-lg cursor-pointer">
      <input
        id={id}
        type="checkbox"
        checked={checked}
        disabled={disabled}
        onChange={(e) => onChange(e.target.checked)}
        className="mt-1 w-4 h-4 accent-[#146c5b]"
      />
      <span>
        <span className="block font-button text-button text-text-primary">{label}</span>
        <span className="block text-xs text-text-muted">{hint}</span>
      </span>
    </label>
  );
}

export function MahalForm({
  mode,
  initial,
  withSubscription,
  saving,
  onSubmit,
  cancelHref,
}: {
  mode: "create" | "edit";
  initial: MahalFormValues;
  /** Show subscription fields (SUPER_ADMIN only). */
  withSubscription: boolean;
  saving: boolean;
  onSubmit: (input: MahalInput) => void;
  cancelHref: string;
}) {
  const [v, setV] = useState<MahalFormValues>(initial);
  const [errors, setErrors] = useState<Errors>({});

  const set = <K extends keyof MahalFormValues>(k: K, val: MahalFormValues[K]) => {
    setV((prev) => ({ ...prev, [k]: val }));
    if (errors[k]) setErrors((prev) => ({ ...prev, [k]: undefined }));
  };

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    const errs = validateMahal(v, mode, withSubscription);
    setErrors(errs);
    if (Object.keys(errs).length > 0) return;
    onSubmit(valuesToInput(v, mode, withSubscription));
  };

  const text = (k: keyof MahalFormValues, label: string, opts: { type?: string; placeholder?: string; required?: boolean; hint?: string; inputMode?: "numeric" | "decimal" | "tel" | "email" } = {}) => (
    <FormField label={label} htmlFor={`mahal-${k}`} error={errors[k]} required={opts.required} hint={opts.hint}>
      <input
        id={`mahal-${k}`}
        className={cn(inputClass, fieldBorder(errors[k]))}
        type={opts.type || "text"}
        inputMode={opts.inputMode}
        placeholder={opts.placeholder}
        value={v[k] as string}
        disabled={saving}
        onChange={(e) => set(k, e.target.value as any)}
        aria-invalid={!!errors[k]}
      />
    </FormField>
  );

  return (
    <form onSubmit={submit} noValidate className="flex flex-col gap-lg">
      <section className="bg-surface border border-border-base rounded-xl p-lg shadow-sm flex flex-col gap-lg">
        <h3 className="font-section-title text-section-title text-text-primary">Organization</h3>
        {mode === "create" &&
          text("id", "Mahal ID", {
            placeholder: "Leave blank to generate",
            hint: "Permanent tenant ID used for login. Letters, digits, '_' or '-'.",
          })}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-lg">
          {text("name", "Mahal Name", { required: true, placeholder: "Registered name" })}
          {text("registration_number", "Registration Number", { placeholder: "Waqf / society registration" })}
        </div>
      </section>

      <section className="bg-surface border border-border-base rounded-xl p-lg shadow-sm flex flex-col gap-lg">
        <h3 className="font-section-title text-section-title text-text-primary">Contact</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-lg">
          {text("email", "Contact Email", { type: "email", inputMode: "email", placeholder: "office@example.org" })}
          {text("phone", "Contact Phone", { type: "tel", inputMode: "tel", placeholder: "10-digit mobile or landline" })}
          {text("whatsapp", "WhatsApp Number", { type: "tel", inputMode: "tel", placeholder: "If different from phone" })}
        </div>
        <FormField label="Address" htmlFor="mahal-address" error={errors.address}>
          <textarea
            id="mahal-address"
            className={cn(
              "px-4 py-3 rounded-lg border bg-surface-container-lowest text-text-primary font-body text-body focus:outline-none focus:ring-2 focus:ring-primary-container focus:border-transparent placeholder:text-text-muted min-h-[80px] resize-y disabled:opacity-60",
              fieldBorder(errors.address)
            )}
            placeholder="Full postal address"
            value={v.address}
            disabled={saving}
            onChange={(e) => set("address", e.target.value)}
          />
        </FormField>
      </section>

      <section className="bg-surface border border-border-base rounded-xl p-lg shadow-sm flex flex-col gap-lg">
        <h3 className="font-section-title text-section-title text-text-primary">Dues &amp; Collections</h3>
        {text("default_monthly_dues", "Default Monthly Dues (₹, INR)", {
          type: "number",
          inputMode: "decimal",
          placeholder: "0",
          hint: "Applied to members without a custom amount.",
        })}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-lg">
          <Toggle
            id="mahal-dunning"
            label="Dunning reminders"
            hint="Send automatic reminders to members with overdue dues."
            checked={v.dunning_enabled}
            disabled={saving}
            onChange={(val) => set("dunning_enabled", val)}
          />
          <Toggle
            id="mahal-autopay"
            label="AutoPay allowed"
            hint="Members may set up recurring debit mandates."
            checked={v.autopay_allowed}
            disabled={saving}
            onChange={(val) => set("autopay_allowed", val)}
          />
        </div>
      </section>

      {withSubscription && (
        <section className="bg-surface border border-border-base rounded-xl p-lg shadow-sm flex flex-col gap-lg">
          <h3 className="font-section-title text-section-title text-text-primary">Platform Subscription</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-lg">
            <FormField label="Status" htmlFor="mahal-sub-status">
              <select
                id="mahal-sub-status"
                className={cn(inputClass, "border-border-base")}
                value={v.sub_status}
                disabled={saving}
                onChange={(e) => set("sub_status", e.target.value as SubscriptionStatus)}
              >
                {SUBSCRIPTION_STATUSES.map((s) => (
                  <option key={s} value={s}>
                    {humanize(s)}
                  </option>
                ))}
              </select>
            </FormField>
            {text("sub_plan", "Plan", { placeholder: "Plan name" })}
            {text("sub_fee", "Monthly Fee (₹)", { type: "number", inputMode: "decimal", placeholder: "0" })}
          </div>
        </section>
      )}

      <div className="flex gap-3">
        <button
          type="submit"
          disabled={saving}
          className="h-12 px-6 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
        >
          {saving ? (
            <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
          ) : (
            <span className="material-symbols-outlined text-[18px]">{mode === "create" ? "add" : "save"}</span>
          )}
          {saving ? "Saving..." : mode === "create" ? "Create Mahal" : "Save Changes"}
        </button>
        <Link
          href={cancelHref}
          className="h-12 px-6 bg-surface border border-border-base text-text-secondary font-button text-button rounded-lg hover:bg-surface-container-low transition-colors flex items-center"
        >
          Cancel
        </Link>
      </div>
    </form>
  );
}
