import 'package:flutter/foundation.dart';

import '../../../core/network/api_service.dart';

/// Committee-wide state shared by the admin screens: the tenant's Mahal
/// record (for the header / drawer), the pending-approval count (for badges)
/// and a best-effort member directory used to put names on transactions.
///
/// Nothing here is fabricated: until the server answers, values are null /
/// empty and the UI shows "—".
class AdminContext {
  AdminContext._();

  static final ApiService _api = ApiService();

  /// GET /admin/mahals/:tenant. Null until loaded or when it failed.
  static final ValueNotifier<Map<String, dynamic>?> mahal =
      ValueNotifier<Map<String, dynamic>?>(null);

  /// Number of self-registered members waiting for approval. Null = unknown.
  static final ValueNotifier<int?> pendingCount = ValueNotifier<int?>(null);

  static String? get mahalName {
    final n = mahal.value?['name']?.toString().trim() ?? '';
    return n.isEmpty ? null : n;
  }

  static String? get registrationNumber {
    final n = mahal.value?['registration_number']?.toString().trim() ?? '';
    return n.isEmpty ? null : n;
  }

  static Future<void> loadMahal({bool force = false}) async {
    if (mahal.value != null && !force) return;
    try {
      mahal.value = await _api.getMahalOrThrow();
    } on ApiException catch (e) {
      debugPrint('[ADMIN] mahal load failed: $e');
    }
  }

  static Future<void> refreshPendingCount() async {
    try {
      pendingCount.value = (await _api.getPendingMembersOrThrow()).length;
    } on ApiException catch (e) {
      debugPrint('[ADMIN] pending count failed: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Member directory
  // -------------------------------------------------------------------------

  static const int _pageSize = 100;

  /// Safety cap: at most this many pages are walked for a full directory.
  static const int _maxPages = 30;

  static List<Map<String, dynamic>>? _members;
  static bool _membersComplete = false;
  static DateTime? _membersLoadedAt;

  /// True when the last [allMembers] call reached the end of the directory.
  static bool get membersComplete => _membersComplete;

  /// Every member (walks the paged endpoint). Cached for two minutes unless
  /// [force]. Throws [ApiException] if the first page fails; a later page
  /// failing returns what was loaded so far with [membersComplete] false.
  static Future<List<Map<String, dynamic>>> allMembers(
      {bool force = false}) async {
    final fresh = _membersLoadedAt != null &&
        DateTime.now().difference(_membersLoadedAt!) <
            const Duration(minutes: 2);
    if (!force && fresh && _members != null) return _members!;

    final out = <Map<String, dynamic>>[];
    var complete = false;
    for (var page = 1; page <= _maxPages; page++) {
      try {
        final res =
            await _api.getAdminMembersPage(page: page, limit: _pageSize);
        out.addAll(res.items.whereType<Map>().map(Map<String, dynamic>.from));
        if (!res.hasMore || res.items.isEmpty) {
          complete = true;
          break;
        }
      } on ApiException {
        if (page == 1) rethrow;
        break;
      }
    }
    _members = out;
    _membersComplete = complete;
    _membersLoadedAt = DateTime.now();
    return out;
  }

  /// member id → name, best effort (empty map on failure).
  static Future<Map<String, String>> memberNames({bool force = false}) async {
    try {
      final list = await allMembers(force: force);
      return {
        for (final m in list)
          if ((m['id'] ?? '').toString().isNotEmpty)
            m['id'].toString(): (m['name'] ?? '').toString(),
      };
    } on ApiException {
      return const {};
    }
  }

  /// Drop the cached directory after a create / edit / import.
  static void invalidateMembers() {
    _members = null;
    _membersLoadedAt = null;
  }

  /// Clear everything on sign-out.
  static void reset() {
    mahal.value = null;
    pendingCount.value = null;
    invalidateMembers();
  }
}
