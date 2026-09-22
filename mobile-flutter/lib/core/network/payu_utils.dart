import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Pulls PayU's `mihpayid` (the gateway payment id) out of the native SDK's
/// success payload so the backend can persist it for later refunds.
///
/// The SDK hands back different shapes across platforms/versions: a flat map
/// with `mihpayid`, or a nested `payuResponse` that is itself either a map or a
/// JSON string. This walks all of those and returns an empty string if none
/// carry the id — the server then resolves it from the gateway as a fallback.
String extractMihpayid(dynamic response) {
  try {
    dynamic root = response;
    if (root is String) {
      root = jsonDecode(root);
    }
    if (root is! Map) return "";

    final direct = root["mihpayid"];
    if (direct != null && direct.toString().isNotEmpty) {
      return direct.toString();
    }

    for (final key in ["payuResponse", "merchantResponse", "result"]) {
      var nested = root[key];
      if (nested == null) continue;
      if (nested is String) {
        if (nested.trim().isEmpty) continue;
        try {
          nested = jsonDecode(nested);
        } catch (_) {
          continue;
        }
      }
      if (nested is Map && nested["mihpayid"] != null) {
        final id = nested["mihpayid"].toString();
        if (id.isNotEmpty) return id;
      }
    }
  } catch (e) {
    debugPrint("[PAYU_MIHPAYID_PARSE_ERROR] $e");
  }
  return "";
}
