import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8080/api/v1";
  static const String defaultTenant = "MH_001_CALICUT";

  // In-memory cache synced across all app tabs
  static String cachedMemberName = "Muhammed Ameen";
  static String cachedPhone = "+91 98471 11222";
  static String cachedEmail = "muhammed@example.com";
  static String cachedAddress = "Darul Aman";

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        "Content-Type": "application/json",
        "X-Tenant-ID": defaultTenant,
      },
    ),
  );

  // 1. Fetch Member Dashboard
  Future<Map<String, dynamic>> getMemberDashboard({String memberId = "MEM_001_9910"}) async {
    try {
      final response = await _dio.get("/member/dashboard?member_id=$memberId");
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data["member_name"] != null) {
          cachedMemberName = data["member_name"].toString();
        }
        return data;
      }
    } catch (e) {
      // Fallback data if backend is offline
    }
    return {
      "member_id": memberId,
      "member_name": cachedMemberName,
      "mahal_name": "Central Juma Masjid Mahal",
      "outstanding_balance": 1500.0,
      "last_paid_month": "2026-05",
      "latest_payment": {
        "receipt_number": "GV1MH00120260515R00001",
        "amount": 500.0,
        "paid_months": ["2026-05"],
        "created_at": "2026-05-15T10:00:00Z",
      },
    };
  }

  // 2. Initialize Dues Payment
  Future<Map<String, dynamic>?> initializeDuesPayment({
    required String memberId,
    required List<String> selectedMonths,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post(
        "/payments/dues/initialize",
        data: {
          "member_id": memberId,
          "selected_months": selectedMonths,
          "gateway": "RAZORPAY",
          "idempotency_key": idempotencyKey,
        },
      );
      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // 3. Confirm Dues Payment
  Future<Map<String, dynamic>?> confirmPayment(String transactionId) async {
    try {
      final response = await _dio.post(
        "/payments/dues/confirm",
        data: {"transaction_id": transactionId},
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      return null;
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
    // Immediately update in-memory cache
    cachedMemberName = name;
    if (email != null && email.isNotEmpty) cachedEmail = email;
    if (address != null && address.isNotEmpty) cachedAddress = address;

    try {
      final response = await _dio.put(
        "/members/profile/$memberId",
        data: {
          "name": name,
          "email": email,
          "address": address,
          "city": city,
          "state": state,
          "pincode": pincode,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 5. Get Member Profile
  Future<Map<String, dynamic>?> getMemberProfile({String memberId = "MEM_001_9910"}) async {
    try {
      final response = await _dio.get("/members/profile/$memberId");
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data["name"] != null) {
          cachedMemberName = data["name"].toString();
        }
        return data;
      }
    } catch (e) {
      // Fallback
    }
    return {
      "name": cachedMemberName,
      "phone": cachedPhone,
      "email": cachedEmail,
      "address": cachedAddress,
    };
  }
}
