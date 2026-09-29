"use client";

import { useCallback, useEffect, useState } from "react";
import Link from "next/link";
import { PageHeader } from "@/components/ui/PageHeader";
import { ErrorState, LoadingBlock } from "@/components/ui/States";
import { FormField, inputClass, fieldBorder } from "@/components/ui/FormField";
import { useToast } from "@/components/ui/Toast";
import { ApiClient, type CurrentUser } from "@/lib/api-client";
import { cn } from "@/lib/cn";
import { errorMessage, formatPhone, humanize, initials } from "@/lib/format";

const MIN_PASSWORD = 10; // server MinPasswordLength

function Row({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex justify-between gap-4 py-2 border-b border-border-base last:border-0">
      <span className="font-body text-body text-text-secondary">{label}</span>
      <span className="font-body text-body text-text-primary font-medium text-right break-all">{value}</span>
    </div>
  );
}

function ChangePasswordCard() {
  const toast = useToast();
  const [current, setCurrent] = useState("");
  const [next, setNext] = useState("");
  const [confirm, setConfirm] = useState("");
  const [show, setShow] = useState(false);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState<{ current?: string; next?: string; confirm?: string }>({});

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    const errs: typeof errors = {};
    if (!current) errs.current = "Enter your current password.";
    if (next.length < MIN_PASSWORD) errs.next = `At least ${MIN_PASSWORD} characters.`;
    else if (next.length > 72) errs.next = "At most 72 characters.";
    else if (next === current) errs.next = "Must differ from the current password.";
    if (confirm !== next) errs.confirm = "Passwords do not match.";
    setErrors(errs);
    if (Object.keys(errs).length) return;

    setSaving(true);
    try {
      await ApiClient.changePassword(current, next);
      toast.success("Password changed. Use the new password next time you sign in.");
      setCurrent("");
      setNext("");
      setConfirm("");
    } catch (err) {
      const msg = errorMessage(err, "Could not change the password.");
      if (/current password/i.test(msg)) setErrors({ current: msg });
      toast.error(msg);
    } finally {
      setSaving(false);
    }
  };

  const type = show ? "text" : "password";
  return (
    <form onSubmit={submit} noValidate className="bg-surface border border-border-base rounded-xl p-lg shadow-sm flex flex-col gap-lg">
      <h3 className="font-section-title text-section-title text-text-primary">Change Password</h3>
      <FormField label="Current password" htmlFor="pw-current" error={errors.current}>
        <input id="pw-current" type={type} autoComplete="current-password" className={cn(inputClass, fieldBorder(errors.current))} value={current} disabled={saving} onChange={(e) => setCurrent(e.target.value)} />
      </FormField>
      <FormField label="New password" htmlFor="pw-new" error={errors.next} hint={`At least ${MIN_PASSWORD} characters.`}>
        <input id="pw-new" type={type} autoComplete="new-password" className={cn(inputClass, fieldBorder(errors.next))} value={next} disabled={saving} onChange={(e) => setNext(e.target.value)} />
      </FormField>
      <FormField label="Confirm new password" htmlFor="pw-confirm" error={errors.confirm}>
        <input id="pw-confirm" type={type} autoComplete="new-password" className={cn(inputClass, fieldBorder(errors.confirm))} value={confirm} disabled={saving} onChange={(e) => setConfirm(e.target.value)} />
      </FormField>
      <label className="flex items-center gap-2 text-sm text-text-secondary">
        <input type="checkbox" checked={show} onChange={(e) => setShow(e.target.checked)} className="accent-[#146c5b]" />
        Show passwords
      </label>
      <div>
        <button
          type="submit"
          disabled={saving}
          className="h-11 px-6 bg-primary-container text-on-primary font-button text-button rounded-lg hover:bg-primary transition-colors flex items-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
        >
          {saving ? <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" /> : <span className="material-symbols-outlined text-[18px]">lock_reset</span>}
          {saving ? "Updating..." : "Update Password"}
        </button>
      </div>
    </form>
  );
}

export default function SettingsPage() {
  const [me, setMe] = useState<CurrentUser | null>(null);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(() => {
    setError(null);
    setMe(null);
    ApiClient.getMe()
      .then(setMe)
      .catch((err) => setError(errorMessage(err, "Could not load your profile.")));
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const mahalId = me?.home_mahal_id || me?.mahal_id || "";

  return (
    <>
      <PageHeader title="Settings" description="Your admin account and Mahal configuration." />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-lg items-start">
        <div className="bg-surface border border-border-base rounded-xl p-lg shadow-sm">
          <h3 className="font-section-title text-section-title text-text-primary mb-lg">My Account</h3>
          {error ? (
            <ErrorState message={error} onRetry={load} />
          ) : !me ? (
            <LoadingBlock rows={4} />
          ) : (
            <>
              <div className="flex items-center gap-3 mb-lg">
                <div className="w-12 h-12 rounded-full bg-primary-container flex items-center justify-center text-on-primary font-button text-button">
                  {initials(me.name)}
                </div>
                <div>
                  <p className="font-card-title text-card-title text-text-primary">{me.name}</p>
                  <p className="font-small text-small text-text-muted">{humanize(me.role)}</p>
                </div>
              </div>
              <Row label="Phone" value={formatPhone(me.phone)} />
              <Row label="Admin ID" value={me.user_id} />
              <Row label="Mahal" value={`${me.mahal_name} (${me.mahal_id})`} />
              <div className="flex flex-wrap gap-2 mt-lg">
                {mahalId && (
                  <Link
                    href={`/mahals/${encodeURIComponent(mahalId)}/edit`}
                    className="h-10 px-4 bg-surface border border-primary text-primary font-button text-small rounded-lg hover:bg-surface-container-low transition-colors inline-flex items-center gap-2"
                  >
                    <span className="material-symbols-outlined text-[18px]">tune</span>
                    Mahal Settings (dues, dunning, AutoPay)
                  </Link>
                )}
                <Link
                  href="/gateways"
                  className="h-10 px-4 bg-surface border border-border-base text-text-primary font-button text-small rounded-lg hover:bg-surface-container-low transition-colors inline-flex items-center gap-2"
                >
                  <span className="material-symbols-outlined text-[18px]">account_balance_wallet</span>
                  Payment Gateways
                </Link>
              </div>
            </>
          )}
        </div>

        <ChangePasswordCard />
      </div>
    </>
  );
}
