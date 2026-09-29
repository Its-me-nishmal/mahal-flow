"use client";

import { useCallback, useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { PageHeader } from "@/components/ui/PageHeader";
import { ErrorState, LoadingBlock } from "@/components/ui/States";
import { useToast } from "@/components/ui/Toast";
import { MahalForm, mahalToValues } from "@/components/mahal/MahalForm";
import { ApiClient, type Mahal, type MahalInput } from "@/lib/api-client";
import { errorMessage } from "@/lib/format";

export default function EditMahalPage() {
  const { id } = useParams<{ id: string }>();
  const mahalId = decodeURIComponent(id);
  const router = useRouter();
  const toast = useToast();
  const [mahal, setMahal] = useState<Mahal | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [superAdmin, setSuperAdmin] = useState(false);

  const load = useCallback(() => {
    setError(null);
    setMahal(null);
    ApiClient.getMahal(mahalId)
      .then(setMahal)
      .catch((err) => setError(errorMessage(err, "Could not load this Mahal.")));
  }, [mahalId]);

  useEffect(() => {
    setSuperAdmin(ApiClient.isSuperAdmin());
    load();
  }, [load]);

  const save = async (input: MahalInput) => {
    setSaving(true);
    try {
      await ApiClient.updateMahal(mahalId, input);
      toast.success("Mahal details saved.");
      router.push(`/mahals/${encodeURIComponent(mahalId)}`);
    } catch (err) {
      toast.error(errorMessage(err, "Could not save the changes."));
      setSaving(false);
    }
  };

  return (
    <>
      <PageHeader title="Edit Mahal Details" description={mahal ? `${mahal.name} · ${mahal.id}` : mahalId} />
      <div className="max-w-3xl">
        {error ? (
          <ErrorState message={error} onRetry={load} />
        ) : !mahal ? (
          <LoadingBlock rows={8} />
        ) : (
          <MahalForm
            key={mahal.updated_at}
            mode="edit"
            initial={mahalToValues(mahal)}
            withSubscription={superAdmin}
            saving={saving}
            onSubmit={save}
            cancelHref={`/mahals/${encodeURIComponent(mahalId)}`}
          />
        )}
      </div>
    </>
  );
}
