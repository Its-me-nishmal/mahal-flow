"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/ui/PageHeader";
import { ErrorState } from "@/components/ui/States";
import { useToast } from "@/components/ui/Toast";
import { MahalForm, emptyMahalValues } from "@/components/mahal/MahalForm";
import { ApiClient, ApiError, type MahalInput } from "@/lib/api-client";
import { errorMessage } from "@/lib/format";

export default function AddNewMahalPage() {
  const router = useRouter();
  const toast = useToast();
  const [saving, setSaving] = useState(false);
  const [superAdmin, setSuperAdmin] = useState<boolean | null>(null);

  useEffect(() => setSuperAdmin(ApiClient.isSuperAdmin()), []);

  const create = async (input: MahalInput) => {
    setSaving(true);
    try {
      const m = await ApiClient.createMahal(input);
      toast.success(`Mahal "${m.name}" created.`);
      router.push(`/mahals/${encodeURIComponent(m.id)}`);
    } catch (err) {
      toast.error(
        err instanceof ApiError && err.status === 409
          ? "That Mahal ID is already in use. Choose another or leave it blank."
          : errorMessage(err, "Could not create the Mahal.")
      );
      setSaving(false);
    }
  };

  if (superAdmin === null) return null;
  if (!superAdmin) {
    return <ErrorState title="Not allowed" message="Only a super admin can register new Mahals." />;
  }

  return (
    <>
      <PageHeader title="Add New Mahal" description="Register a new Mahal organization on the platform." />
      <div className="max-w-3xl">
        <MahalForm mode="create" initial={emptyMahalValues()} withSubscription saving={saving} onSubmit={create} cancelHref="/mahals" />
      </div>
    </>
  );
}
