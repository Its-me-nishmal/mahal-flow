import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ValueNotifier<int> unreadAlertsCount = ValueNotifier<int>(0);

  // Support both Physical Device via ADB / localhost and Emulator (10.0.2.2)
  static const List<String> candidateBaseUrls = [
    "http://localhost:8080/api/v1",
    "http://127.0.0.1:8080/api/v1",
    "http://10.0.2.2:8080/api/v1",
  ];

  static String activeBaseUrl = candidateBaseUrls.first;
  static const String defaultTenant = "MH_001_CALICUT";

  // Initial runtime cache
  static String cachedMemberName = "Muhammed Ameen";
  static String cachedPhone = "+91 98471 11222";
  static String cachedEmail = "muhammed@example.com";
  static String cachedAddress = "Darul Aman";

  Dio _getDio(String baseUrl) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        headers: {
          "Content-Type": "application/json",
          "X-Tenant-ID": defaultTenant,
        },
      ),
    );
  }

  Future<Response<T>?> _requestWithFallback<T>(
    Future<Response<T>> Function(Dio dio) requestFn,
  ) async {
    // 1. Try active Base URL first
    try {
      final dio = _getDio(activeBaseUrl);
      final res = await requestFn(dio);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res;
      }
    } catch (_) {}

    // 2. Try candidate fallback URLs if connection failed
    for (final url in candidateBaseUrls) {
      if (url == activeBaseUrl) continue;
      try {
        final dio = _getDio(url);
        final res = await requestFn(dio);
        if (res.statusCode == 200 || res.statusCode == 201) {
          activeBaseUrl = url; // remember working URL
          return res;
        }
      } catch (_) {}
    }
    return null;
  }

  // 1. Fetch Member Dashboard from Live MongoDB API
  Future<Map<String, dynamic>?> getMemberDashboard({String memberId = "MEM_001_9910"}) async {
    final response = await _requestWithFallback(
      (dio) => dio.get("/member/dashboard?member_id=$memberId"),
    );
    if (response != null && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      if (data["member_name"] != null) {
        cachedMemberName = data["member_name"].toString();
      }
      return data;
    }
    return null;
  }

  // 2. Initialize Dues Payment
  Future<Map<String, dynamic>?> initializeDuesPayment({
    required String memberId,
    required List<String> selectedMonths,
    required String idempotencyKey,
    String gateway = "RAZORPAY",
  }) async {
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/payments/dues/initialize",
        data: {
          "member_id": memberId,
          "selected_months": selectedMonths,
          "gateway": gateway,
          "idempotency_key": idempotencyKey,
        },
      ),
    );
    if (response != null && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // 3. Confirm Dues Payment
  Future<Map<String, dynamic>?> confirmPayment(String transactionId) async {
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/payments/dues/confirm",
        data: {"transaction_id": transactionId},
      ),
    );
    if (response != null && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // 3.1 Initialize Contribution / Donation Payment
  Future<Map<String, dynamic>?> initializeContribution({
    required String memberId,
    required double amount,
    required String fund,
    required String idempotencyKey,
  }) async {
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/payments/contribution/initialize",
        data: {
          "member_id": memberId,
          "amount": amount,
          "purpose": fund,
          "gateway": "RAZORPAY",
          "idempotency_key": idempotencyKey,
        },
      ),
    );
    if (response != null && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // 4. Update Member Profile
  Future<bool> updateMemberProfile({
    String memberId = "MEM_001_9910",
    required String name,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
  }) async {
    cachedMemberName = name;
    if (email != null && email.isNotEmpty) cachedEmail = email;
    if (address != null && address.isNotEmpty) cachedAddress = address;

    final response = await _requestWithFallback(
      (dio) => dio.put(
        "/members/profile/$memberId",
        data: {
          "name": name,
          "email": email,
          "address": address,
          "city": city,
          "state": state,
          "pincode": pincode,
        },
      ),
    );
    return response != null && response.statusCode == 200;
  }

  // 5. Get Member Profile
  Future<Map<String, dynamic>?> getMemberProfile({String memberId = "MEM_001_9910"}) async {
    final response = await _requestWithFallback(
      (dio) => dio.get("/members/profile/$memberId"),
    );
    if (response != null && response.data != null) {
      final data = response.data as Map<String, dynamic>;
      if (data["name"] != null) {
        cachedMemberName = data["name"].toString();
      }
      return data;
    }
    return null;
  }

  // 6. Get Cryptographic Receipt
  Future<Map<String, dynamic>?> getReceipt(String receiptNumber) async {
    final response = await _requestWithFallback(
      (dio) => dio.get("/receipts/$receiptNumber"),
    );
    if (response != null && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // 7. Get Member Receipts List
  Future<List<dynamic>> getMemberReceipts({String memberId = "MEM_001_9910"}) async {
    final response = await _requestWithFallback(
      (dio) => dio.get("/member/receipts?member_id=$memberId"),
    );
    if (response != null && response.data != null) {
      final map = response.data as Map<String, dynamic>;
      if (map["receipts"] is List) {
        return map["receipts"] as List<dynamic>;
      }
    }
    return [];
  }

  Future<List<dynamic>> getRecentReceipts({String memberId = "MEM_001_9910"}) =>
      getMemberReceipts(memberId: memberId);

  // 8. Alerts Live APIs
  Future<List<dynamic>> getAlerts({String memberId = "MEM_001_9910"}) async {
    final response = await _requestWithFallback(
      (dio) => dio.get("/admin/alerts?member_id=$memberId"),
    );
    if (response != null && response.data != null) {
      final map = response.data as Map<String, dynamic>;
      if (map["alerts"] is List) {
        final list = map["alerts"] as List<dynamic>;
        final unread = list.where((item) => (item as Map<String, dynamic>?)?["status"] == "ACTIVE").length;
        unreadAlertsCount.value = unread;
        return list;
      }
    }
    unreadAlertsCount.value = 0;
    return [];
  }

  Future<bool> acknowledgeAlert(String alertId) async {
    if (unreadAlertsCount.value > 0) {
      unreadAlertsCount.value--;
    }
    final response = await _requestWithFallback(
      (dio) => dio.post("/admin/alerts/$alertId/ack"),
    );
    return response != null && response.statusCode == 200;
  }

  Future<bool> dismissAlert(String alertId) async {
    if (unreadAlertsCount.value > 0) {
      unreadAlertsCount.value--;
    }
    final response = await _requestWithFallback(
      (dio) => dio.delete("/admin/alerts/$alertId"),
    );
    return response != null && response.statusCode == 200;
  }

  Future<bool> clearAllAlerts() async {
    unreadAlertsCount.value = 0;
    final response = await _requestWithFallback(
      (dio) => dio.delete("/admin/alerts"),
    );
    return response != null && response.statusCode == 200;
  }

  Future<bool> markAllAlertsRead() async {
    unreadAlertsCount.value = 0;
    final response = await _requestWithFallback(
      (dio) => dio.post("/admin/alerts/mark-all-read"),
    );
    return response != null && response.statusCode == 200;
  }

  // 9. AutoPay Mandates
  Future<Map<String, dynamic>?> createAutoPayMandate({
    String memberId = "MEM_001_9910",
    double maxAmount = 1000.0,
  }) async {
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/autopay/mandate/create",
        data: {
          "member_id": memberId,
          "max_amount": maxAmount,
        },
      ),
    );
    if (response != null && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // 10. Admin Dashboard Live API
  Future<Map<String, dynamic>?> getAdminDashboard() async {
    final response = await _requestWithFallback(
      (dio) => dio.get("/admin/dashboard"),
    );
    if (response != null && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // 11. Admin Members Live API
  Future<List<dynamic>> getAdminMembers() async {
    final response = await _requestWithFallback(
      (dio) => dio.get("/admin/members?limit=100"),
    );
    if (response != null && response.data != null) {
      final map = response.data as Map<String, dynamic>;
      if (map["members"] is List) {
        return map["members"] as List<dynamic>;
      }
    }
    return [];
  }

  // 12. Create / Broadcast Alert
  Future<Map<String, dynamic>?> createAlert({
    required String title,
    required String description,
    String severity = "INFO",
    String audience = "ALL",
  }) async {
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/admin/alerts",
        data: {
          "title": title,
          "description": description,
          "severity": severity,
          "audience": audience,
        },
      ),
    );
    if (response != null && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // 13. Get Audit Logs
  Future<List<dynamic>> getAuditLogs({int limit = 50}) async {
    final response = await _requestWithFallback(
      (dio) => dio.get("/admin/audit-logs?limit=$limit"),
    );
    if (response != null && response.data != null) {
      final map = response.data as Map<String, dynamic>;
      if (map["logs"] is List) {
        return map["logs"] as List<dynamic>;
      }
    }
    return [];
  }

  // 14. Get Financial Report (Live MongoDB)
  Future<Map<String, dynamic>?> getFinancialReport() async {
    final response = await _requestWithFallback(
      (dio) => dio.get("/admin/reports/financial"),
    );
    if (response != null && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // 15. Get Payment Gateways (Live)
  Future<List<dynamic>> getGateways() async {
    final response = await _requestWithFallback(
      (dio) => dio.get("/admin/gateways"),
    );
    if (response != null && response.data != null) {
      if (response.data is List) {
        return response.data as List<dynamic>;
      }
    }
    return [];
  }

  // 16. Create Member (Admin)
  Future<Map<String, dynamic>?> createMember({
    required String name,
    required String phone,
    String? houseName,
    double duesAmount = 500,
    String status = "ACTIVE",
  }) async {
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/admin/members",
        data: {
          "name": name,
          "phone": phone,
          "house_name": houseName ?? "Central House",
          "monthly_dues_custom_amount": duesAmount,
          "status": status,
          "family_head": true,
        },
      ),
    );
    if (response != null && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // 17. Delete Member (Admin)
  Future<bool> deleteMember(String memberId) async {
    final response = await _requestWithFallback(
      (dio) => dio.delete("/admin/members/$memberId"),
    );
    return response != null && response.statusCode == 200;
  }

  // 18. Update Member Details (Admin)
  Future<bool> updateMemberDetails({
    required String memberId,
    required String name,
    String? phone,
    String? houseName,
    double? duesAmount,
    String? status,
  }) async {
    final data = <String, dynamic>{
      "name": name,
    };
    if (phone != null && phone.isNotEmpty) data["phone"] = phone;
    if (houseName != null && houseName.isNotEmpty) data["house_name"] = houseName;
    if (duesAmount != null && duesAmount > 0) data["monthly_dues_custom_amount"] = duesAmount;
    if (status != null && status.isNotEmpty) data["status"] = status;

    final response = await _requestWithFallback(
      (dio) => dio.put(
        "/members/profile/$memberId",
        data: data,
      ),
    );
    return response != null && response.statusCode == 200;
  }

  // 19. Verify Receipt Cryptographic Integrity
  Future<Map<String, dynamic>?> verifyReceiptCryptographic(String receiptNumber) async {
    final response = await _requestWithFallback(
      (dio) => dio.get("/receipts/$receiptNumber/verify"),
    );
    if (response != null && response.data != null) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }
}

