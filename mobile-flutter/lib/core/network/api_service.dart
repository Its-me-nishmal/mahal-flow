import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8080/api/v1";
  static const String defaultTenant = "MH_001_CALICUT";

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
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      // Fallback data if backend is offline
    }
    return {
      "member_id": memberId,
      "member_name": "Muhammed Ameen",
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
}
