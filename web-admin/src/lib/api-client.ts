import { mockMahals, mockMembers } from "./mock-data";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8080/api/v1";

export interface ApiResponse<T> {
  data: T;
  source: "mongodb" | "fallback_mock";
  error?: string;
}

export async function fetchWithFallback<T>(
  endpoint: string,
  tenantId: string = "MH_001_CALICUT",
  fallbackData: T,
  options?: RequestInit
): Promise<ApiResponse<T>> {
  try {
    const res = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers: {
        "Content-Type": "application/json",
        "X-Tenant-ID": tenantId,
        ...(options?.headers || {}),
      },
      next: { revalidate: 0 },
    });

    if (!res.ok) {
      throw new Error(`API returned HTTP ${res.status}`);
    }

    const json = await res.json();
    return {
      data: json as T,
      source: "mongodb",
    };
  } catch (err: any) {
    // Graceful fallback to mock data
    return {
      data: fallbackData,
      source: "fallback_mock",
      error: err.message,
    };
  }
}

// Client Helper Methods
export const ApiClient = {
  getAdminDashboard: async (tenantId: string = "MH_001_CALICUT") => {
    return fetchWithFallback("/admin/dashboard", tenantId, {
      total_members: mockMembers.length,
      paid_members: 171,
      pending_members: 24,
      total_pending_dues: 12000,
      total_collected_mtd: 85500,
      subscription_status: "ACTIVE",
    });
  },

  getMembers: async (tenantId: string = "MH_001_CALICUT") => {
    return fetchWithFallback("/admin/members", tenantId, {
      members: mockMembers,
      total: mockMembers.length,
      page: 1,
      limit: 50,
    });
  },

  getMemberDashboard: async (tenantId: string = "MH_001_CALICUT", memberId: string = "MEM_001_9910") => {
    return fetchWithFallback(`/member/dashboard?member_id=${memberId}`, tenantId, {
      member_id: "MEM_001_9910",
      member_name: "Muhammed Ameen",
      mahal_name: "Central Juma Masjid Mahal",
      outstanding_balance: 1500,
      last_paid_month: "2026-05",
      latest_payment: {
        receipt_number: "GV1MH00120260515R00001",
        amount: 500,
        paid_months: ["2026-05"],
      },
    });
  },
};
