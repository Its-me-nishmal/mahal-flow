import type { ImportPreview } from "@/lib/api-client";

// The previewed batch is kept for this tab only, between the upload and
// preview steps. The server holds the batch itself (24h); this is just the
// preview payload so the preview page can render it.
const KEY = "mahalflow_import_preview";

export function savePreview(p: ImportPreview) {
  try {
    sessionStorage.setItem(KEY, JSON.stringify(p));
  } catch {
    /* storage unavailable: the preview page will ask for a re-upload */
  }
}

export function loadPreview(): ImportPreview | null {
  try {
    const raw = sessionStorage.getItem(KEY);
    return raw ? (JSON.parse(raw) as ImportPreview) : null;
  } catch {
    return null;
  }
}

export function clearPreview() {
  try {
    sessionStorage.removeItem(KEY);
  } catch {
    /* ignore */
  }
}
