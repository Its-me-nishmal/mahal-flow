const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1";

export interface ApiResponse<T> {
  data: T | null;
  error?: string;
}

export async function fetchApi<T>(
  endpoint: string,
  tenantId: string = "MH_001_CALICUT",
  options?: RequestInit
): Promise<T> {
  const url = `${API_BASE_URL}${endpoint}`;
  const res = await fetch(url, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      "X-Tenant-ID": tenantId,
      ...(options?.headers || {}),
    },
    cache: "no-store",
  });

  if (!res.ok) {
    const errorBody = await res.text().catch(() => "");
    throw new Error(`API Error ${res.status}: ${errorBody || res.statusText}`);
  }

  return (await res.json()) as T;
}

// Client Helper Methods for Super-Admin & Mahal Admin
export const ApiClient = {
  // 1. Dashboard Statistics
  getAdminDashboard: async (tenantId: string = "MH_001_CALICUT") => {
    return fetchApi<{
      total_members: number;
      paid_members: number;
      pending_members: number;
      total_pending_dues: number;
      total_collected_mtd: number;
      subscription_status: string;
    }>("/admin/dashboard", tenantId);
  },

  // 2. Mahals Management
  getMahals: async () => {
    return fetchApi<{ mahals: any[]; total: number }>("/admin/mahals", "SUPER_ADMIN");
  },

  getMahal: async (id: string) => {
    return fetchApi<any>(`/admin/mahals/${id}`, "SUPER_ADMIN");
  },

  createMahal: async (data: any) => {
    return fetchApi<any>("/admin/mahals", "SUPER_ADMIN", {
      method: "POST",
      body: JSON.stringify(data),
    });
  },

  // 3. Members Directory & Search
  getMembers: async (tenantId: string = "MH_001_CALICUT", page: number = 1, limit: number = 50) => {
    return fetchApi<{ members: any[]; total: number; page: number; limit: number }>(
      `/admin/members?page=${page}&limit=${limit}`,
      tenantId
    );
  },

  queryMembers: async (tenantId: string = "MH_001_CALICUT", filter: any) => {
    return fetchApi<{ members: any[]; total: number; page: number; limit: number }>(
      "/admin/members/query",
      tenantId,
      {
        method: "POST",
        body: JSON.stringify(filter),
      }
    );
  },

  createMember: async (data: any, tenantId: string = "MH_001_CALICUT") => {
    return fetchApi<any>("/admin/members", tenantId, {
      method: "POST",
      body: JSON.stringify(data),
    });
  },

  deleteMember: async (id: string, tenantId: string = "MH_001_CALICUT") => {
    return fetchApi<any>(`/admin/members/${id}`, tenantId, {
      method: "DELETE",
    });
  },

  getMemberProfile: async (id: string, tenantId: string = "MH_001_CALICUT") => {
    return fetchApi<any>(`/members/profile/${id}`, tenantId);
  },

  updateMemberProfile: async (id: string, updates: any, tenantId: string = "MH_001_CALICUT") => {
    return fetchApi<any>(`/members/profile/${id}`, tenantId, {
      method: "PUT",
      body: JSON.stringify(updates),
    });
  },

  // 4. Payments & Transactions
  getPayments: async (tenantId: string = "MH_001_CALICUT", page: number = 1, limit: number = 50) => {
    return fetchApi<{ payments: any[]; total: number; page: number; limit: number }>(
      `/admin/payments?page=${page}&limit=${limit}`,
      tenantId
    );
  },

  getReceipt: async (number: string, tenantId: string = "MH_001_CALICUT") => {
    return fetchApi<any>(`/receipts/${number}`, tenantId);
  },

  verifyReceipt: async (number: string, tenantId: string = "MH_001_CALICUT") => {
    return fetchApi<any>(`/receipts/${number}/verify`, tenantId);
  },

  // 5. Subscriptions & Billing
  getSubscriptions: async () => {
    return fetchApi<{ subscriptions: any[]; total: number }>("/admin/subscriptions", "SUPER_ADMIN");
  },

  // 6. Refunds Management
  getRefunds: async (tenantId: string = "MH_001_CALICUT") => {
    return fetchApi<{ refunds: any[]; total: number }>("/admin/refunds", tenantId);
  },

  processRefund: async (id: string, action: "APPROVE" | "REJECT", tenantId: string = "MH_001_CALICUT") => {
    return fetchApi<any>(`/admin/refunds/${id}/action`, tenantId, {
      method: "POST",
      body: JSON.stringify({ action }),
    });
  },

  // 7. Financial Reports
  getFinancialReports: async (tenantId: string = "MH_001_CALICUT") => {
    return fetchApi<{
      summary: {
        total_collected: number;
        dues_collected: number;
        donations: number;
        pending_dues: number;
      };
      period: string;
    }>("/admin/reports/financial", tenantId);
  },

  // 8. Audit Logs & System Alerts
  getAuditLogs: async (tenantId: string = "MH_001_CALICUT", page: number = 1, limit: number = 50) => {
    return fetchApi<{ logs: any[]; total: number; page: number; limit: number }>(
      `/admin/audit-logs?page=${page}&limit=${limit}`,
      tenantId
    );
  },

  getAlerts: async (tenantId: string = "MH_001_CALICUT") => {
    return fetchApi<{ alerts: any[]; total: number }>("/admin/alerts", tenantId);
  },

  createAlert: async (
    alert: { title: string; description: string; severity?: "INFO" | "WARNING" | "CRITICAL" },
    tenantId: string = "MH_001_CALICUT"
  ) => {
    return fetchApi<any>("/admin/alerts", tenantId, {
      method: "POST",
      body: JSON.stringify(alert),
    });
  },

  acknowledgeAlert: async (id: string, tenantId: string = "MH_001_CALICUT") => {
    return fetchApi<any>(`/admin/alerts/${id}/ack`, tenantId, {
      method: "POST",
    });
  },

  // 9. Gateways
  getGateways: async (tenantId: string = "MH_001_CALICUT") => {
    return fetchApi<any[]>("/admin/gateways", tenantId);
  },
};
