const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1";

const TOKEN_KEY = "mahalflow_admin_token";
const USER_KEY = "mahalflow_admin_user";

export interface ApiResponse<T> {
  data: T | null;
  error?: string;
}

export interface LoginResponse {
  token: string;
  role: "MAHAL_ADMIN" | "SUPER_ADMIN" | string;
  admin_id: string;
  name: string;
  phone: string;
  mahal_id: string;
  expires_in: number;
}

/** Thrown by [ApiClient.login]. `mahalIds` is set when the phone administers
 * several Mahals and the caller must pick one and retry with it. */
export class LoginError extends Error {
  readonly status: number;
  readonly mahalIds?: string[];
  constructor(message: string, status: number, mahalIds?: string[]) {
    super(message);
    this.name = "LoginError";
    this.status = status;
    this.mahalIds = mahalIds;
  }
}

export function getStoredToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function getStoredUser(): any | null {
  if (typeof window === "undefined") return null;
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

/** The signed-in admin's Mahal (from the login response). The backend binds
 * every token to its Mahal, so this is the only tenant a MAHAL_ADMIN can use. */
export function getCurrentTenant(): string {
  const user = getStoredUser();
  return typeof user?.mahal_id === "string" ? user.mahal_id : "";
}

function clearSession() {
  if (typeof window === "undefined") return;
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}

/** Authenticated request. Always sends the stored bearer token; `tenantId`
 * defaults to the signed-in admin's Mahal (only SUPER_ADMIN may pass another). */
export async function fetchApi<T>(
  endpoint: string,
  tenantId?: string,
  options?: RequestInit
): Promise<T> {
  const url = `${API_BASE_URL}${endpoint}`;
  const token = getStoredToken();

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "X-Tenant-ID": tenantId || getCurrentTenant(),
    ...((options?.headers as Record<string, string>) || {}),
  };

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  const res = await safeFetch(url, {
    ...options,
    headers,
    cache: "no-store",
  });

  if (res.status === 401) {
    if (typeof window !== "undefined" && !window.location.pathname.startsWith("/login")) {
      clearSession();
      window.location.href = "/login";
    }
  }

  return parseResponse<T>(res);
}

/** Non-2xx API answer. `message` is the server's `error` text when it sent one. */
export class ApiError extends Error {
  readonly status: number;
  constructor(message: string, status: number) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

async function parseResponse<T>(res: Response): Promise<T> {
  if (!res.ok) {
    const raw = await res.text().catch(() => "");
    let msg = "";
    try {
      const body = JSON.parse(raw);
      msg = typeof body?.error === "string" ? body.error : typeof body?.message === "string" ? body.message : "";
    } catch {
      msg = raw.slice(0, 200);
    }
    if (!msg) {
      msg =
        res.status === 403
          ? "You do not have permission to do this."
          : res.status === 404
          ? "Not found."
          : res.status >= 500
          ? "The server had a problem. Try again."
          : `Request failed (${res.status}).`;
    }
    throw new ApiError(msg, res.status);
  }
  return (await res.json()) as T;
}

/** Wraps network failures (server down, CORS, offline) in a readable error. */
async function safeFetch(url: string, init: RequestInit): Promise<Response> {
  try {
    return await fetch(url, init);
  } catch {
    throw new ApiError("Cannot reach the MahalFlow server. Check your connection.", 0);
  }
}

export type AdminRole = "MAHAL_ADMIN" | "SUPER_ADMIN";

/** Role of the signed-in admin, from the login response. */
export function getCurrentRole(): string {
  const user = getStoredUser();
  return typeof user?.role === "string" ? user.role : "";
}

export function isSuperAdmin(): boolean {
  return getCurrentRole() === "SUPER_ADMIN";
}

export type SubscriptionStatus = "ACTIVE" | "GRACE_PERIOD" | "READ_ONLY" | "SUSPENDED";
export const SUBSCRIPTION_STATUSES: SubscriptionStatus[] = ["ACTIVE", "GRACE_PERIOD", "READ_ONLY", "SUSPENDED"];

export interface Mahal {
  id: string;
  name: string;
  registration_number: string;
  contact: { email: string; phone: string; whatsapp?: string; address: string };
  settings: {
    currency: string;
    default_monthly_dues: number;
    dunning_enabled: boolean;
    preferred_languages: string[] | null;
    autopay_allowed: boolean;
  };
  subscription: {
    plan: string;
    monthly_fee: number;
    status: SubscriptionStatus | string;
    grace_period_ends_at?: string;
    next_billing_date: string;
  };
  created_at: string;
  updated_at: string;
}

/** Body for create / update. Omitted fields are left unchanged (update) or defaulted (create). */
export interface MahalInput {
  id?: string;
  name?: string;
  registration_number?: string;
  contact?: { email?: string; phone?: string; whatsapp?: string; address?: string };
  settings?: { default_monthly_dues?: number; dunning_enabled?: boolean; autopay_allowed?: boolean };
  /** SUPER_ADMIN only. */
  subscription?: { status?: SubscriptionStatus; plan?: string; monthly_fee?: number };
}

export interface MahalRecentPayment {
  id: string;
  member_id: string;
  member_name?: string;
  type: string;
  amount: number;
  status: string;
  gateway?: string;
  payment_mode?: string;
  receipt_id?: string;
  created_at: string;
  completed_at?: string | null;
}

export interface MahalStats {
  mahal_id: string;
  total_members: number;
  paid_members: number;
  pending_members: number;
  total_pending_dues: number;
  collected_mtd: number;
  dues_collected_mtd: number;
  donations_mtd: number;
  transactions_mtd: number;
  collected_all_time: number;
  mtd_month: string;
  timezone: string;
  recent_payments: MahalRecentPayment[];
}

export interface ImportRow {
  row: number;
  name: string;
  phone: string;
  house_name: string;
  monthly_dues: number;
  family_head: boolean;
  family_members_count: number;
  email?: string;
  code?: string;
  status: "VALID" | "DUPLICATE" | "INVALID" | string;
  errors: string[] | null;
}

export interface ImportPreview {
  batch_id: string;
  filename: string;
  total_rows: number;
  valid_rows: number;
  duplicate_rows: number;
  invalid_rows: number;
  preview_rows: ImportRow[];
  expires_at: string;
  status: string;
}

export interface ImportCommitResult {
  status: "COMPLETED" | "ALREADY_COMMITTED" | string;
  batch_id: string;
  imported: number;
  skipped: number;
}

export interface CurrentUser {
  user_id: string;
  name: string;
  role: string;
  mahal_id: string;
  mahal_name: string;
  phone?: string;
  home_mahal_id?: string;
}

export interface ReportPeriod {
  month?: string;
  from?: string;
  to?: string;
}

export interface FinancialReport {
  summary: {
    total_collected: number;
    dues_collected: number;
    donations: number;
    /** Current snapshot, not period-bound. */
    pending_dues: number;
    transaction_count?: number;
  };
  /** "YYYY-MM" | "CUSTOM" | "ALL_TIME" */
  period: string;
  from?: string | null;
  to?: string | null;
  timezone?: string;
}

export const ALERT_TYPES = ["DUES_REMINDER", "PAYMENT_RECEIVED", "ANNOUNCEMENT", "EVENT", "GENERAL"] as const;
export type AlertType = (typeof ALERT_TYPES)[number];
export type AlertAudience = "ALL" | "OVERDUE_ONLY" | "FAMILY_HEADS" | "MEMBER";

export interface Gateway {
  id: string;
  provider: string;
  display_name?: string;
  status: "ACTIVE" | "NOT_CONFIGURED" | string;
  is_primary: boolean;
  mode?: "LIVE" | "TEST" | string;
  /** Server PAYMENT_TEST_MODE: no real gateway calls. */
  simulated?: boolean;
  merchant_key_masked?: string;
  supported_methods?: string[];
  autopay_enabled?: boolean;
  si_supported?: boolean;
  managed_by?: string;
}

// Client Helper Methods for Super-Admin & Mahal Admin
export const ApiClient = {
  // 0. Auth Methods
  /** Phone + password login. The server decides the admin's Mahal and role
   * from their admin record; `mahalId` is only needed when it answers 409
   * (one phone, several Mahals). */
  login: async (phone: string, password: string, mahalId?: string): Promise<LoginResponse> => {
    let res: Response;
    try {
      res = await fetch(`${API_BASE_URL}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ phone, password, ...(mahalId ? { mahal_id: mahalId } : {}) }),
      });
    } catch {
      throw new LoginError("Cannot reach the MahalFlow server. Check your connection.", 0);
    }

    if (!res.ok) {
      const err = await res.json().catch(() => ({}) as any);
      if (res.status === 401) throw new LoginError("Invalid phone or password", 401);
      if (res.status === 429) throw new LoginError(err.error || "Too many attempts. Try again in a minute.", 429);
      throw new LoginError(err.error || "Login failed", res.status, Array.isArray(err.mahal_ids) ? err.mahal_ids : undefined);
    }

    const data = (await res.json()) as LoginResponse;
    if (typeof window !== "undefined" && data.token) {
      localStorage.setItem(TOKEN_KEY, data.token);
      localStorage.setItem(USER_KEY, JSON.stringify(data));
    }
    return data;
  },

  logout: () => {
    if (typeof window !== "undefined") {
      clearSession();
      window.location.href = "/login";
    }
  },

  getToken: getStoredToken,
  getUser: getStoredUser,
  getTenant: getCurrentTenant,
  getRole: getCurrentRole,
  isSuperAdmin,
  isAuthenticated: () => !!getStoredToken(),

  // 1. Dashboard Statistics
  getAdminDashboard: async (tenantId?: string) => {
    return fetchApi<{
      total_members: number;
      paid_members: number;
      pending_members: number;
      total_pending_dues: number;
      /** Real month-to-date collections (tenant timezone, see `timezone`). */
      total_collected_mtd: number;
      total_collected_all_time?: number;
      /** Month the MTD figure covers, "YYYY-MM". */
      mtd_month?: string;
      timezone?: string;
      subscription_status: string;
    }>("/admin/dashboard", tenantId);
  },

  // 2. Mahals Management
  getMahals: async () => {
    return fetchApi<{ mahals: any[]; total: number }>("/admin/mahals");
  },

  getMahal: async (id: string) => {
    return fetchApi<Mahal>(`/admin/mahals/${encodeURIComponent(id)}`);
  },

  /** SUPER_ADMIN only. 409 when the id is taken. */
  createMahal: async (data: MahalInput) => {
    return fetchApi<Mahal>("/admin/mahals", undefined, {
      method: "POST",
      body: JSON.stringify(data),
    });
  },

  /** SUPER_ADMIN: any Mahal. MAHAL_ADMIN: own Mahal, no subscription fields. */
  updateMahal: async (id: string, data: MahalInput) => {
    return fetchApi<Mahal>(`/admin/mahals/${encodeURIComponent(id)}`, undefined, {
      method: "PUT",
      body: JSON.stringify(data),
    });
  },

  getMahalStats: async (id: string, limit = 10) => {
    return fetchApi<MahalStats>(`/admin/mahals/${encodeURIComponent(id)}/stats?limit=${limit}`);
  },

  // 3. Members Directory & Search
  getMembers: async (tenantId?: string, page: number = 1, limit: number = 50) => {
    return fetchApi<{ members: any[]; total: number; page: number; limit: number }>(
      `/admin/members?page=${page}&limit=${limit}`,
      tenantId
    );
  },

  queryMembers: async (tenantId: string | undefined, filter: any) => {
    return fetchApi<{ members: any[]; total: number; page: number; limit: number }>(
      "/admin/members/query",
      tenantId,
      {
        method: "POST",
        body: JSON.stringify(filter),
      }
    );
  },

  createMember: async (data: any, tenantId?: string) => {
    return fetchApi<any>("/admin/members", tenantId, {
      method: "POST",
      body: JSON.stringify(data),
    });
  },

  deleteMember: async (id: string, tenantId?: string) => {
    return fetchApi<any>(`/admin/members/${id}`, tenantId, {
      method: "DELETE",
    });
  },

  getMemberProfile: async (id: string, tenantId?: string) => {
    return fetchApi<any>(`/members/profile/${encodeURIComponent(id)}`, tenantId);
  },

  updateMemberProfile: async (id: string, updates: any, tenantId?: string) => {
    return fetchApi<any>(`/members/profile/${encodeURIComponent(id)}`, tenantId, {
      method: "PUT",
      body: JSON.stringify(updates),
    });
  },

  /** A member's receipts (admin view). */
  getMemberReceipts: async (memberId: string, tenantId?: string) => {
    return fetchApi<{ receipts: any[]; total: number }>(
      `/member/receipts?member_id=${encodeURIComponent(memberId)}`,
      tenantId
    );
  },

  // Excel member import (same flow as the mobile app)
  /** Parses and validates the sheet; nothing is written until commit. */
  uploadExcelPreview: async (file: File, tenantId?: string) => {
    const form = new FormData();
    form.append("file", file);
    const headers: Record<string, string> = { "X-Tenant-ID": tenantId || getCurrentTenant() };
    const token = getStoredToken();
    if (token) headers["Authorization"] = `Bearer ${token}`;
    const res = await safeFetch(`${API_BASE_URL}/admin/excel/upload-preview`, {
      method: "POST",
      headers, // no Content-Type: the browser sets the multipart boundary
      body: form,
      cache: "no-store",
    });
    if (res.status === 401 && typeof window !== "undefined") {
      clearSession();
      window.location.href = "/login";
    }
    return parseResponse<ImportPreview>(res);
  },

  commitExcelImport: async (batchId: string, tenantId?: string) => {
    return fetchApi<ImportCommitResult>("/admin/excel/commit-import", tenantId, {
      method: "POST",
      body: JSON.stringify({ batch_id: batchId }),
    });
  },

  // Own account
  getMe: async () => fetchApi<CurrentUser>("/auth/me"),

  changePassword: async (currentPassword: string, newPassword: string) => {
    return fetchApi<{ status: string }>("/auth/change-password", undefined, {
      method: "POST",
      body: JSON.stringify({ current_password: currentPassword, new_password: newPassword }),
    });
  },

  // 4. Payments & Transactions
  getPayments: async (tenantId?: string, page: number = 1, limit: number = 50) => {
    return fetchApi<{ payments: any[]; total: number; page: number; limit: number }>(
      `/admin/payments?page=${page}&limit=${limit}`,
      tenantId
    );
  },

  getReceipt: async (number: string, tenantId?: string) => {
    return fetchApi<any>(`/receipts/${number}`, tenantId);
  },

  verifyReceipt: async (number: string, tenantId?: string) => {
    return fetchApi<any>(`/receipts/${number}/verify`, tenantId);
  },

  // 5. Subscriptions & Billing
  getSubscriptions: async () => {
    return fetchApi<{ subscriptions: any[]; total: number }>("/admin/subscriptions");
  },

  // 6. Refunds Management
  getRefunds: async (tenantId?: string) => {
    return fetchApi<{ refunds: any[]; total: number }>("/admin/refunds", tenantId);
  },

  processRefund: async (id: string, action: "APPROVE" | "REJECT", tenantId?: string) => {
    return fetchApi<any>(`/admin/refunds/${id}/action`, tenantId, {
      method: "POST",
      body: JSON.stringify({ action }),
    });
  },

  // 7. Financial Reports
  /** Period: `{ month: "YYYY-MM" }`, `{ from, to }` ("YYYY-MM-DD", inclusive,
   * IST) or nothing for all time. `pending_dues` is always a current snapshot. */
  getFinancialReports: async (period: ReportPeriod = {}, tenantId?: string) => {
    const params = new URLSearchParams();
    if (period.month) params.set("month", period.month);
    if (period.from) params.set("from", period.from);
    if (period.to) params.set("to", period.to);
    const qs = params.toString();
    return fetchApi<FinancialReport>(`/admin/reports/financial${qs ? `?${qs}` : ""}`, tenantId);
  },

  // 8. Audit Logs & System Alerts
  getAuditLogs: async (tenantId?: string, page: number = 1, limit: number = 50) => {
    return fetchApi<{ logs: any[]; total: number; page: number; limit: number }>(
      `/admin/audit-logs?page=${page}&limit=${limit}`,
      tenantId
    );
  },

  getAlerts: async (tenantId?: string) => {
    return fetchApi<{ alerts: any[]; total: number }>("/admin/alerts", tenantId);
  },

  createAlert: async (
    alert: {
      title: string;
      description: string;
      severity?: "INFO" | "WARNING" | "CRITICAL";
      audience?: AlertAudience;
      /** Required (≤500, same Mahal) when audience is MEMBER. */
      member_ids?: string[];
      type?: AlertType;
    },
    tenantId?: string
  ) => {
    return fetchApi<any>("/admin/alerts", tenantId, {
      method: "POST",
      body: JSON.stringify(alert),
    });
  },

  acknowledgeAlert: async (id: string, tenantId?: string) => {
    return fetchApi<any>(`/admin/alerts/${id}/ack`, tenantId, {
      method: "POST",
    });
  },

  // 9. Gateways
  /** Read-only: gateways are configured from server env, not via the API. */
  getGateways: async (tenantId?: string) => {
    return fetchApi<Gateway[]>("/admin/gateways", tenantId);
  },
};
