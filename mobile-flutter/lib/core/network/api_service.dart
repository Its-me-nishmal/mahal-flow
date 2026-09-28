import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../l10n/l10n.dart';
import '../storage/app_prefs.dart';
import 'api_exception.dart';

export 'api_exception.dart';

/// HTTP client for the MahalFlow Go backend.
///
/// ## Failure vs empty
/// Every read the screens use comes in two forms:
///
/// * `xxxOrThrow(...)` — returns the data (an empty list is a real "nothing
///   here") and throws [ApiException] on any failure. New screen code should
///   use these and render an error state from [ApiException.userMessage].
/// * `xxx(...)` — the legacy form: returns `null` / `[]` on failure. Kept so
///   existing screens compile; it cannot tell "failed" from "empty".
///
/// Paged admin listings ([getAdminMembersPage], [queryAdminMembersPage],
/// [getAdminPayments], [getAuditLogsPage]) only exist in the throwing form
/// and return a [PagedResult].
class ApiService {
  static final ValueNotifier<int> unreadAlertsCount = ValueNotifier<int>(0);

  /// Bearer token for /admin/* routes. Set by [login] / [resolveLogin],
  /// restored on launch by [restoreSession], and injected into every request in
  /// [_getDio]. Null = unauthenticated (member-only routes still work; admin
  /// routes 401).
  static String? authToken;

  /// The signed-in member's id, set after phone resolve and restored on launch.
  /// Member-scoped calls default to this so each user sees their own data.
  static String? sessionMemberId;

  /// The signed-in member's id, or null when nobody is signed in as a member
  /// (signed out, or signed in as a committee admin). There is deliberately
  /// no seed fallback: defaulting to a demo id would attribute payments and
  /// profile edits to the wrong person.
  static String? get currentMemberId => sessionMemberId;

  /// [currentMemberId] or throw [ApiErrorKind.noSession].
  static String requireMemberId() {
    final id = sessionMemberId;
    if (id == null || id.isEmpty) {
      throw const ApiException(ApiErrorKind.noSession);
    }
    return id;
  }

  /// PayU `user_credential` — identifies the payer for saved cards / UPI
  /// handles. PayU's format is `"<merchantKey>:<memberId>"`. Returns null when
  /// either part is missing so callers can omit the param instead of sending
  /// someone else's id.
  static String? payuUserCredential(String? merchantKey, {String? memberId}) {
    final key = merchantKey?.trim() ?? '';
    final member = (memberId ?? sessionMemberId)?.trim() ?? '';
    if (key.isEmpty || member.isEmpty) return null;
    return '$key:$member';
  }

  // Support both Physical Device via ADB / localhost and Emulator (10.0.2.2)
  static const List<String> candidateBaseUrls = [
    "http://localhost:8080/api/v1",
    "http://127.0.0.1:8080/api/v1",
    "http://10.0.2.2:8080/api/v1",
  ];

  static String activeBaseUrl = candidateBaseUrls.first;
  static const String defaultTenant = "MH_001_CALICUT";

  // Runtime cache of the signed-in member, filled from API responses. Empty
  // until then — never seeded with sample data.
  static String cachedMemberName = "";
  static String cachedPhone = "";
  static String cachedEmail = "";
  static String cachedAddress = "";

  Dio _getDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        headers: {
          "Content-Type": "application/json",
          "X-Tenant-ID": defaultTenant,
          if (authToken != null && authToken!.isNotEmpty)
            "Authorization": "Bearer $authToken",
        },
      ),
    );
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => debugPrint("[DIO_API] $obj"),
    ));
    return dio;
  }

  /// Sends a request, trying each candidate base URL only while the failure is
  /// a connection problem. An HTTP error response means a server answered, so
  /// it is surfaced immediately as an [ApiException] instead of retried.
  Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function(Dio dio) requestFn,
  ) async {
    final urls = [
      activeBaseUrl,
      ...candidateBaseUrls.where((u) => u != activeBaseUrl),
    ];
    Object? lastError;
    for (final url in urls) {
      try {
        debugPrint("[API_SERVICE] Requesting via: $url");
        final res = await requestFn(_getDio(url));
        final code = res.statusCode ?? 0;
        if (code >= 200 && code < 300) {
          if (url != activeBaseUrl) {
            activeBaseUrl = url; // remember working URL
            debugPrint("[API_SERVICE] Fallback success: $url");
          }
          return res;
        }
        throw _fromStatus(code, res.data, null);
      } on ApiException {
        rethrow;
      } on DioException catch (e) {
        final response = e.response;
        if (response != null && response.statusCode != null) {
          throw _fromStatus(response.statusCode!, response.data, e);
        }
        debugPrint("[API_SERVICE] Failed via $url: $e");
        lastError = e;
      } catch (e) {
        debugPrint("[API_SERVICE] Failed via $url: $e");
        lastError = e;
      }
    }
    throw ApiException(ApiErrorKind.network, cause: lastError);
  }

  static ApiException _fromStatus(int code, dynamic body, Object? cause) {
    String? message;
    if (body is Map && body["error"] != null) {
      message = body["error"].toString();
    } else if (body is Map && body["message"] != null) {
      message = body["message"].toString();
    }
    final ApiErrorKind kind;
    if (code == 401) {
      kind = ApiErrorKind.unauthorized;
    } else if (code == 403) {
      kind = ApiErrorKind.forbidden;
    } else if (code == 404) {
      kind = ApiErrorKind.notFound;
    } else if (code >= 500) {
      kind = ApiErrorKind.server;
    } else if (code >= 400) {
      kind = ApiErrorKind.badRequest;
    } else {
      kind = ApiErrorKind.badResponse;
    }
    return ApiException(kind,
        statusCode: code, serverMessage: message, cause: cause);
  }

  /// Legacy wrapper: the response, or null on any failure.
  Future<Response<dynamic>?> _requestWithFallback(
    Future<Response<dynamic>> Function(Dio dio) requestFn,
  ) async {
    try {
      return await _send(requestFn);
    } on ApiException catch (e) {
      debugPrint("[API_SERVICE] $e");
      return null;
    }
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException(ApiErrorKind.badResponse, cause: data);
  }

  /// Pulls `key` out of a map body as a list. A missing/null key is treated as
  /// an empty list (Go encodes an empty slice as null in some handlers).
  static List<dynamic> _listField(dynamic data, String key) {
    final map = _asMap(data);
    final value = map[key];
    if (value == null) return const [];
    if (value is List) return value;
    throw ApiException(ApiErrorKind.badResponse, cause: data);
  }

  static PagedResult<dynamic> _paged(
    dynamic data,
    String key, {
    required int page,
    required int limit,
  }) {
    final map = _asMap(data);
    final items = _listField(map, key);
    int readInt(String k, int fallback) {
      final v = map[k];
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    return PagedResult<dynamic>(
      items: items,
      total: readInt("total", items.length),
      page: readInt("page", page),
      limit: readInt("limit", limit),
    );
  }

  static Future<T?> _orNull<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on ApiException catch (e) {
      debugPrint("[API_SERVICE] $e");
      return null;
    }
  }

  static Future<List<dynamic>> _orEmpty(
    Future<List<dynamic>> Function() fn,
  ) async {
    try {
      return await fn();
    } on ApiException catch (e) {
      debugPrint("[API_SERVICE] $e");
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Auth / session
  // ---------------------------------------------------------------------------

  /// Exchange a phone (and optional mahal) for a JWT and cache it in memory and
  /// secure storage. Returns true on success. The backend issues a MAHAL_ADMIN
  /// token; the password field is currently ignored server-side.
  Future<bool> login({
    required String phone,
    String mahalId = defaultTenant,
  }) async {
    final response = await _requestWithFallback(
      (dio) => dio.post("/auth/login", data: {
        "phone": phone,
        "mahal_id": mahalId,
      }),
    );
    final data = response?.data;
    if (data is Map<String, dynamic> && data["token"] is String) {
      authToken = data["token"] as String;
      await AppPrefs.setAuthToken(authToken!);
      return true;
    }
    return false;
  }

  /// Restore a persisted token + member session into memory on app launch.
  static Future<void> restoreSession() async {
    authToken = await AppPrefs.authToken();
    sessionMemberId = await AppPrefs.memberId();
  }

  /// True when a session token or member id was restored / issued.
  static bool get hasSession =>
      (authToken != null && authToken!.isNotEmpty) ||
      (sessionMemberId != null && sessionMemberId!.isNotEmpty);

  /// Drop the token + member session from memory and storage on sign-out.
  static Future<void> logout() async {
    authToken = null;
    sessionMemberId = null;
    await AppPrefs.clearSession();
  }

  /// Resolve an OTP-verified phone to an identity within the tenant. Returns the
  /// raw map: {status: ALLOWED|PENDING|UNREGISTERED, role, member_id, name, token}.
  /// Null = the server could not be reached.
  Future<Map<String, dynamic>?> resolveLogin(String phone) =>
      _orNull(() => resolveLoginOrThrow(phone));

  Future<Map<String, dynamic>> resolveLoginOrThrow(String phone) async {
    final response = await _send(
      (dio) => dio.post("/auth/resolve", data: {"phone": phone}),
    );
    final data = _asMap(response.data);
    if (data["status"] == "ALLOWED") {
      if (data["token"] is String) {
        authToken = data["token"] as String;
        await AppPrefs.setAuthToken(authToken!);
      }
      if (data["member_id"] is String) {
        sessionMemberId = data["member_id"] as String;
        await AppPrefs.setMemberSession(
          sessionMemberId!,
          data["name"]?.toString() ?? "",
        );
      } else {
        // Admin identities carry no member id; drop any stale member session
        // so member-scoped calls cannot act on a previous user's behalf.
        sessionMemberId = null;
        await AppPrefs.clearMemberSession();
      }
    }
    return data;
  }

  /// Self-register an unregistered phone as a PENDING member. Returns the raw
  /// map: {status: PENDING|ALLOWED, member_id, name} or {error}.
  Future<Map<String, dynamic>?> registerSelf({
    required String phone,
    required String mahalId,
    required String name,
  }) async {
    try {
      final response = await _send(
        (dio) => dio.post("/auth/register", data: {
          "phone": phone,
          "mahal_id": mahalId,
          "name": name,
        }),
      );
      return _asMap(response.data);
    } on ApiException catch (e) {
      // A 4xx carries a useful reason ("Mahal not found"); surface it the
      // same way the success body would.
      if (e.serverMessage != null && e.kind != ApiErrorKind.network) {
        return {"error": e.serverMessage};
      }
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Admin: pending member approvals
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getPendingMembers() =>
      _orEmpty(getPendingMembersOrThrow);

  Future<List<dynamic>> getPendingMembersOrThrow() async {
    final response = await _send((dio) => dio.get("/admin/members/pending"));
    return _listField(response.data, "pending");
  }

  Future<bool> approveMember(String memberId) async {
    final response = await _requestWithFallback(
      (dio) => dio.post("/admin/members/$memberId/approve"),
    );
    return response != null;
  }

  Future<bool> rejectMember(String memberId) async {
    final response = await _requestWithFallback(
      (dio) => dio.post("/admin/members/$memberId/reject"),
    );
    return response != null;
  }

  // ---------------------------------------------------------------------------
  // Member dashboard / payments
  // ---------------------------------------------------------------------------

  // 1. Fetch Member Dashboard from Live MongoDB API
  Future<Map<String, dynamic>?> getMemberDashboard({String? memberId}) =>
      _orNull(() => getMemberDashboardOrThrow(memberId: memberId));

  Future<Map<String, dynamic>> getMemberDashboardOrThrow({
    String? memberId,
  }) async {
    final id = memberId ?? requireMemberId();
    final response = await _send(
      (dio) => dio.get("/member/dashboard", queryParameters: {"member_id": id}),
    );
    final data = _asMap(response.data);
    if (data["member_name"] != null) {
      cachedMemberName = data["member_name"].toString();
    }
    return data;
  }

  // 2. Initialize Dues Payment
  Future<Map<String, dynamic>?> initializeDuesPayment({
    required String memberId,
    required List<String> selectedMonths,
    required String idempotencyKey,
    String gateway = "PAYU",
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
    if (response != null && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // 3. Confirm Dues Payment
  Future<Map<String, dynamic>?> confirmPayment(
    String transactionId, {
    String? gatewayPaymentId,
  }) async {
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/payments/dues/confirm",
        data: {
          "transaction_id": transactionId,
          if (gatewayPaymentId != null && gatewayPaymentId.isNotEmpty)
            "gateway_payment_id": gatewayPaymentId,
        },
      ),
    );
    if (response != null && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // 3.01 Reconcile / Check Payment Gateway Status
  Future<Map<String, dynamic>?> checkPaymentStatus(String transactionId) =>
      _orNull(() => checkPaymentStatusOrThrow(transactionId));

  Future<Map<String, dynamic>> checkPaymentStatusOrThrow(
    String transactionId,
  ) async {
    final response =
        await _send((dio) => dio.get("/payments/$transactionId/status"));
    return _asMap(response.data);
  }

  // 3.02 Fetch PayU Parameters and SHA-512 Hash for Native SDK
  Future<Map<String, dynamic>?> getPayUCheckoutData(String orderId) =>
      _orNull(() => getPayUCheckoutDataOrThrow(orderId));

  Future<Map<String, dynamic>> getPayUCheckoutDataOrThrow(
    String orderId,
  ) async {
    final response = await _send(
      (dio) => dio.get("/payments/payu-checkout-data/$orderId"),
    );
    return _asMap(response.data);
  }

  // 3.03 Dynamically generate PayU hash from backend
  Future<String?> generatePayUHash({
    required String hashName,
    required String hashString,
    String? hashType,
    String? postSalt,
  }) async {
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/payments/payu-generate-hash",
        data: {
          "hash_name": hashName,
          "hash_string": hashString,
          "hash_type": hashType ?? "",
          "post_salt": postSalt ?? "",
        },
      ),
    );
    final data = response?.data;
    if (data is Map) {
      return data["hash"]?.toString();
    }
    return null;
  }

  // 3.1 Initialize Contribution / Donation Payment
  /// [note] is an optional free-text message from the member ("In memory
  /// of…"). It is sent as `note`; the current backend ignores unknown fields,
  /// so it is only persisted once the server stores it.
  Future<Map<String, dynamic>?> initializeContribution({
    required String memberId,
    required double amount,
    required String fund,
    required String idempotencyKey,
    String? note,
  }) async {
    final trimmedNote = note?.trim();
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/payments/contribution/initialize",
        data: {
          "member_id": memberId,
          "amount": amount,
          "purpose": fund,
          "gateway": "PAYU",
          "idempotency_key": idempotencyKey,
          if (trimmedNote != null && trimmedNote.isNotEmpty)
            "note": trimmedNote,
        },
      ),
    );
    if (response != null && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Member profile
  // ---------------------------------------------------------------------------

  // 4. Update Member Profile — defaults to the signed-in member. Returns false
  // (and sends nothing) when there is no member session.
  Future<bool> updateMemberProfile({
    String? memberId,
    required String name,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? address2,
  }) async {
    final id = memberId ?? currentMemberId;
    if (id == null || id.isEmpty) return false;

    final response = await _requestWithFallback(
      (dio) => dio.put(
        "/members/profile/$id",
        data: {
          "name": name,
          "email": email,
          "address": address,
          "city": city,
          "state": state,
          "pincode": pincode,
          if (address2 != null) "address2": address2,
        },
      ),
    );
    final ok = response != null && response.statusCode == 200;
    if (ok) {
      // Only cache what the server accepted.
      cachedMemberName = name;
      if (email != null && email.isNotEmpty) cachedEmail = email;
      if (address != null && address.isNotEmpty) cachedAddress = address;
    }
    return ok;
  }

  // 5. Get Member Profile
  Future<Map<String, dynamic>?> getMemberProfile({String? memberId}) =>
      _orNull(() => getMemberProfileOrThrow(memberId: memberId));

  Future<Map<String, dynamic>> getMemberProfileOrThrow({
    String? memberId,
  }) async {
    final id = memberId ?? requireMemberId();
    final response = await _send((dio) => dio.get("/members/profile/$id"));
    final data = _asMap(response.data);
    if (data["name"] != null) {
      cachedMemberName = data["name"].toString();
    }
    return data;
  }

  // ---------------------------------------------------------------------------
  // Receipts
  // ---------------------------------------------------------------------------

  // 6. Get Cryptographic Receipt
  Future<Map<String, dynamic>?> getReceipt(String receiptNumber) =>
      _orNull(() => getReceiptOrThrow(receiptNumber));

  Future<Map<String, dynamic>> getReceiptOrThrow(String receiptNumber) async {
    final response = await _send((dio) => dio.get("/receipts/$receiptNumber"));
    return _asMap(response.data);
  }

  // 7. Get Member Receipts List
  Future<List<dynamic>> getMemberReceipts({String? memberId}) =>
      _orEmpty(() => getMemberReceiptsOrThrow(memberId: memberId));

  Future<List<dynamic>> getMemberReceiptsOrThrow({String? memberId}) async {
    final id = memberId ?? requireMemberId();
    final response = await _send(
      (dio) => dio.get("/member/receipts", queryParameters: {"member_id": id}),
    );
    return _listField(response.data, "receipts");
  }

  Future<List<dynamic>> getRecentReceipts({String? memberId}) =>
      getMemberReceipts(memberId: memberId);

  // 19. Verify Receipt Cryptographic Integrity
  Future<Map<String, dynamic>?> verifyReceiptCryptographic(
    String receiptNumber,
  ) =>
      _orNull(() => verifyReceiptCryptographicOrThrow(receiptNumber));

  Future<Map<String, dynamic>> verifyReceiptCryptographicOrThrow(
    String receiptNumber,
  ) async {
    final response =
        await _send((dio) => dio.get("/receipts/$receiptNumber/verify"));
    return _asMap(response.data);
  }

  // ---------------------------------------------------------------------------
  // Alerts
  // ---------------------------------------------------------------------------

  // 8. Alerts Live APIs. Also refreshes [unreadAlertsCount] on success; a
  // failed fetch leaves the badge as it was.
  Future<List<dynamic>> getAlerts({String? memberId}) =>
      _orEmpty(() => getAlertsOrThrow(memberId: memberId));

  Future<List<dynamic>> getAlertsOrThrow({String? memberId}) async {
    final id = memberId ?? requireMemberId();
    final response = await _send(
      (dio) => dio.get("/member/alerts", queryParameters: {"member_id": id}),
    );
    final list = _listField(response.data, "alerts");
    unreadAlertsCount.value =
        list.where((item) => item is Map && item["status"] == "ACTIVE").length;
    return list;
  }

  /// Mark one alert read. Pass [wasUnread] = true only when the alert was
  /// unread before this call, so the badge count is not decremented twice.
  Future<bool> acknowledgeAlert(String alertId,
      {bool wasUnread = false}) async {
    if (wasUnread && unreadAlertsCount.value > 0) {
      unreadAlertsCount.value--;
    }
    final response = await _requestWithFallback(
      (dio) => dio.post("/admin/alerts/$alertId/ack"),
    );
    return response != null && response.statusCode == 200;
  }

  /// Remove one alert. [wasUnread] as for [acknowledgeAlert].
  Future<bool> dismissAlert(String alertId, {bool wasUnread = false}) async {
    if (wasUnread && unreadAlertsCount.value > 0) {
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
    if (response != null && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Admin dashboard / members / payments / audit / reports
  // ---------------------------------------------------------------------------

  // 10. Admin Dashboard Live API
  Future<Map<String, dynamic>?> getAdminDashboard() =>
      _orNull(getAdminDashboardOrThrow);

  Future<Map<String, dynamic>> getAdminDashboardOrThrow() async {
    final response = await _send((dio) => dio.get("/admin/dashboard"));
    return _asMap(response.data);
  }

  // 11. Admin Members Live API (legacy: one big page).
  Future<List<dynamic>> getAdminMembers({int page = 1, int limit = 100}) =>
      _orEmpty(() async =>
          (await getAdminMembersPage(page: page, limit: limit)).items);

  /// GET /admin/members?page=&limit= → {members, total, page, limit}.
  /// Server defaults: page 1, limit 50. Sorted server-side.
  Future<PagedResult<dynamic>> getAdminMembersPage({
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _send(
      (dio) => dio.get("/admin/members",
          queryParameters: {"page": page, "limit": limit}),
    );
    return _paged(response.data, "members", page: page, limit: limit);
  }

  /// POST /admin/members/query → {members, total, page, limit, applied_filter}.
  ///
  /// NOTE: the Go handler currently parses these filters and echoes them back
  /// as `applied_filter` but only applies [page]/[limit] — filter client-side
  /// until the server honours them.
  Future<PagedResult<dynamic>> queryAdminMembersPage({
    String? status,
    bool overdueOnly = false,
    bool familyHeadOnly = false,
    List<String>? houseNames,
    double? minOverdueAmount,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _send(
      (dio) => dio.post("/admin/members/query", data: {
        if (status != null && status.isNotEmpty) "status": status,
        "overdue_only": overdueOnly,
        "family_head_only": familyHeadOnly,
        if (houseNames != null && houseNames.isNotEmpty)
          "house_names": houseNames,
        if (minOverdueAmount != null) "min_overdue_amount": minOverdueAmount,
        "page": page,
        "limit": limit,
      }),
    );
    return _paged(response.data, "members", page: page, limit: limit);
  }

  /// GET /admin/payments?page=&limit= → {payments, total, page, limit}.
  /// All tenant transactions, newest first (`created_at` desc). Each item:
  /// {id, mahal_id, member_id, idempotency_key, type (MONTHLY_DUES |
  /// CONTRIBUTION), amount, currency, selected_months?, gateway,
  /// gateway_order_id?, gateway_payment_id?, status, failure_reason?,
  /// receipt_id?, created_at, completed_at?}. The server supports no filters
  /// beyond paging. Throws [ApiException].
  Future<PagedResult<dynamic>> getAdminPayments({
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _send(
      (dio) => dio.get("/admin/payments",
          queryParameters: {"page": page, "limit": limit}),
    );
    return _paged(response.data, "payments", page: page, limit: limit);
  }

  // 13. Get Audit Logs (legacy: first page only).
  Future<List<dynamic>> getAuditLogs({int limit = 50, int page = 1}) =>
      _orEmpty(
          () async => (await getAuditLogsPage(page: page, limit: limit)).items);

  /// GET /admin/audit-logs?page=&limit= → {logs, total, page, limit}.
  Future<PagedResult<dynamic>> getAuditLogsPage({
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _send(
      (dio) => dio.get("/admin/audit-logs",
          queryParameters: {"page": page, "limit": limit}),
    );
    return _paged(response.data, "logs", page: page, limit: limit);
  }

  // 14. Get Financial Report (Live MongoDB)
  Future<Map<String, dynamic>?> getFinancialReport() =>
      _orNull(getFinancialReportOrThrow);

  Future<Map<String, dynamic>> getFinancialReportOrThrow() async {
    final response = await _send((dio) => dio.get("/admin/reports/financial"));
    return _asMap(response.data);
  }

  // 15. Get Payment Gateways (Live)
  Future<List<dynamic>> getGateways() => _orEmpty(getGatewaysOrThrow);

  Future<List<dynamic>> getGatewaysOrThrow() async {
    final response = await _send((dio) => dio.get("/admin/gateways"));
    final data = response.data;
    if (data is List) return data;
    if (data == null) return const [];
    throw ApiException(ApiErrorKind.badResponse, cause: data);
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
    if (response != null && response.data is Map<String, dynamic>) {
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
    if (houseName != null && houseName.isNotEmpty) {
      data["house_name"] = houseName;
    }
    if (duesAmount != null && duesAmount > 0) {
      data["monthly_dues_custom_amount"] = duesAmount;
    }
    if (status != null && status.isNotEmpty) data["status"] = status;

    final response = await _requestWithFallback(
      (dio) => dio.put(
        "/members/profile/$memberId",
        data: data,
      ),
    );
    return response != null && response.statusCode == 200;
  }

  // ---------------------------------------------------------------------------
  // AutoPay mandates (PayU Recurring / e-Mandate)
  // ---------------------------------------------------------------------------

  // 20. Create a mandate for the signed-in member (or [memberId]). Null when
  // there is no member session or the call fails.
  Future<Map<String, dynamic>?> createAutoPayMandate({
    String? memberId,
    double maxAmount = 1000.0,
    double? debitAmount,
    String frequency = "MONTHLY",
    String mode = "UPI",
  }) async {
    final id = memberId ?? currentMemberId;
    if (id == null) return null;
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/autopay/mandate/create",
        data: {
          "member_id": id,
          "max_amount": maxAmount,
          "debit_amount": debitAmount ?? maxAmount,
          "frequency": frequency,
          "mode": mode,
        },
      ),
    );
    if (response != null && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // Activate a mandate after the member approves the SI at the gateway.
  Future<Map<String, dynamic>?> confirmAutoPayMandate({
    required String mandateId,
    String? gatewayPaymentId,
  }) async {
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/autopay/mandate/confirm",
        data: {
          "mandate_id": mandateId,
          if (gatewayPaymentId != null && gatewayPaymentId.isNotEmpty)
            "gateway_payment_id": gatewayPaymentId,
        },
      ),
    );
    if (response != null && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  // Stop a mandate so the backend scheduler no longer debits it.
  Future<Map<String, dynamic>?> cancelAutoPayMandate({
    String? mandateId,
    String? memberId,
    String reason = "Cancelled by member",
  }) async {
    final id = memberId ?? currentMemberId;
    if (id == null && (mandateId == null || mandateId.isEmpty)) return null;
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/autopay/mandate/cancel",
        data: {
          if (mandateId != null && mandateId.isNotEmpty)
            "mandate_id": mandateId,
          if (id != null) "member_id": id,
          "reason": reason,
        },
      ),
    );
    if (response != null && response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getAutoPayStatus({String? memberId}) =>
      _orNull(() => getAutoPayStatusOrThrow(memberId: memberId));

  Future<Map<String, dynamic>> getAutoPayStatusOrThrow({
    String? memberId,
  }) async {
    final id = memberId ?? requireMemberId();
    final response = await _send(
      (dio) => dio
          .get("/autopay/mandate/status", queryParameters: {"member_id": id}),
    );
    return _asMap(response.data);
  }

  // ---------------------------------------------------------------------------
  // Push notifications
  // ---------------------------------------------------------------------------

  // Register this device's FCM token so the backend can send push
  // notifications. Skipped (false) when no member is signed in, so a token is
  // never bound to someone else's id.
  Future<bool> registerDeviceToken(
    String token, {
    String? memberId,
    String platform = "android",
  }) async {
    final id = memberId ?? currentMemberId;
    if (id == null) return false;
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/notifications/register-token",
        data: {
          "token": token,
          "member_id": id,
          "platform": platform,
        },
      ),
    );
    return response != null;
  }

  // Stop push to this device (sign-out).
  Future<bool> unregisterDeviceToken(String token) async {
    final response = await _requestWithFallback(
      (dio) => dio.post(
        "/notifications/unregister-token",
        data: {"token": token},
      ),
    );
    return response != null;
  }

  // ---------------------------------------------------------------------------
  // Admin: throwing variants used by the committee screens. Each returns the
  // server's body on 2xx and throws [ApiException] otherwise, so a screen can
  // show the server's reason and never report success it did not get.
  // ---------------------------------------------------------------------------

  /// GET /admin/mahals/:id → the Mahal record (name, registration_number,
  /// contact, settings, subscription). Defaults to the request tenant.
  Future<Map<String, dynamic>> getMahalOrThrow([String? mahalId]) async {
    final id = (mahalId == null || mahalId.isEmpty) ? defaultTenant : mahalId;
    final response = await _send((dio) => dio.get("/admin/mahals/$id"));
    return _asMap(response.data);
  }

  /// GET /members/profile/:id → the raw member record. Unlike
  /// [getMemberProfileOrThrow] this does not touch the signed-in member's
  /// cached name, so an admin can read any member.
  Future<Map<String, dynamic>> getAdminMemberOrThrow(String memberId) async {
    final response =
        await _send((dio) => dio.get("/members/profile/$memberId"));
    return _asMap(response.data);
  }

  /// POST /admin/members → the created member.
  Future<Map<String, dynamic>> createMemberOrThrow({
    required String name,
    required String phone,
    String? houseName,
    required double duesAmount,
    String status = "ACTIVE",
    bool familyHead = true,
  }) async {
    final response = await _send(
      (dio) => dio.post("/admin/members", data: {
        "name": name,
        "phone": phone,
        "house_name": houseName ?? "",
        "monthly_dues_custom_amount": duesAmount,
        "status": status,
        "family_head": familyHead,
      }),
    );
    return _asMap(response.data);
  }

  /// PUT /members/profile/:id with only the given fields.
  Future<Map<String, dynamic>> updateMemberDetailsOrThrow({
    required String memberId,
    String? name,
    String? phone,
    String? houseName,
    double? duesAmount,
    String? status,
  }) async {
    final data = <String, dynamic>{
      if (name != null && name.isNotEmpty) "name": name,
      if (phone != null && phone.isNotEmpty) "phone": phone,
      if (houseName != null && houseName.isNotEmpty) "house_name": houseName,
      if (duesAmount != null && duesAmount > 0)
        "monthly_dues_custom_amount": duesAmount,
      if (status != null && status.isNotEmpty) "status": status,
    };
    final response = await _send(
      (dio) => dio.put("/members/profile/$memberId", data: data),
    );
    return _asMap(response.data);
  }

  /// POST /admin/members/:id/approve.
  Future<void> approveMemberOrThrow(String memberId) async {
    await _send((dio) => dio.post("/admin/members/$memberId/approve"));
  }

  /// POST /admin/members/:id/reject.
  Future<void> rejectMemberOrThrow(String memberId) async {
    await _send((dio) => dio.post("/admin/members/$memberId/reject"));
  }

  /// POST /admin/alerts → {status, alert, audience}. [audience] is one of
  /// ALL | OVERDUE_ONLY | FAMILY_HEADS (the server has no per-member target).
  Future<Map<String, dynamic>> createAlertOrThrow({
    required String title,
    required String description,
    String severity = "INFO",
    String audience = "ALL",
  }) async {
    final response = await _send(
      (dio) => dio.post("/admin/alerts", data: {
        "title": title,
        "description": description,
        "severity": severity,
        "audience": audience,
      }),
    );
    return _asMap(response.data);
  }

  /// Records dues collected in cash: POST /payments/dues/initialize with
  /// gateway CASH, which the server commits immediately and answers with
  /// `{status: SUCCESS, receipt: {...}}`. Any other answer (e.g. the commit
  /// failed and a plain pending transaction came back) throws, because no
  /// receipt was issued. [selectedMonths] must start right after the member's
  /// `last_paid_month` — the server rejects gaps with a 422 whose message is
  /// in [ApiException.serverMessage].
  Future<Map<String, dynamic>> recordCashDuesPaymentOrThrow({
    required String memberId,
    required List<String> selectedMonths,
    required String idempotencyKey,
  }) async {
    final response = await _send(
      (dio) => dio.post("/payments/dues/initialize", data: {
        "member_id": memberId,
        "selected_months": selectedMonths,
        "gateway": "CASH",
        "idempotency_key": idempotencyKey,
      }),
    );
    final data = _asMap(response.data);
    final receipt = data["receipt"];
    if (data["status"] != "SUCCESS" || receipt is! Map) {
      throw ApiException(
        ApiErrorKind.badResponse,
        serverMessage: "The payment was not committed; no receipt was issued.",
        cause: data,
      );
    }
    return data;
  }

  /// POST /admin/excel/upload-preview (multipart, field `file`) → the
  /// server's validation preview: {filename, total_rows, valid_rows,
  /// duplicate_rows, preview_rows: [...]}. Pass either [path] or [bytes].
  Future<Map<String, dynamic>> uploadExcelPreviewOrThrow({
    required String fileName,
    String? path,
    List<int>? bytes,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    if ((path == null || path.isEmpty) && bytes == null) {
      throw ApiException(ApiErrorKind.badRequest,
          serverMessage: L10n.current.errorNoFileSelected);
    }
    final response = await _send((dio) async {
      final file = (path != null && path.isNotEmpty)
          ? await MultipartFile.fromFile(path, filename: fileName)
          : MultipartFile.fromBytes(bytes!, filename: fileName);
      return dio.post(
        "/admin/excel/upload-preview",
        data: FormData.fromMap({"file": file}),
        onSendProgress: onSendProgress,
        options: Options(sendTimeout: const Duration(seconds: 60)),
      );
    });
    return _asMap(response.data);
  }

  /// POST /admin/excel/commit-import → {status, imported_count,
  /// skipped_count, ingestion_batch}.
  Future<Map<String, dynamic>> commitExcelImportOrThrow({
    required String fileName,
    String? uploadId,
  }) async {
    final response = await _send(
      (dio) => dio.post("/admin/excel/commit-import", data: {
        "filename": fileName,
        if (uploadId != null && uploadId.isNotEmpty) "upload_id": uploadId,
      }),
    );
    return _asMap(response.data);
  }
}
