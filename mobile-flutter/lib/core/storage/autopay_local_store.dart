import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local record of whether the member has completed AutoPay setup.
///
/// The backend exposes GET /autopay/mandate/status, but that handler is a
/// stub: it always returns status ACTIVE and is not scoped to a member
/// (backend-go/internal/api/handlers.go). Trusting it would tell every member
/// AutoPay is on when it is not. Until mandates persist server-side, the
/// dashboard nudge is gated on this local per-member flag instead.
class AutoPayLocalStore {
  AutoPayLocalStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String _key(String memberId) => 'autopay_enabled_$memberId';

  static Future<bool> isEnabled(String memberId) async {
    if (memberId.isEmpty) return false;
    try {
      return await _storage.read(key: _key(memberId)) == 'true';
    } catch (_) {
      // Keystore unavailable: show the nudge rather than hide a real action.
      return false;
    }
  }

  static Future<void> setEnabled(String memberId, bool value) async {
    if (memberId.isEmpty) return;
    try {
      await _storage.write(key: _key(memberId), value: value.toString());
    } catch (_) {
      // Non-fatal: the nudge simply reappears next launch.
    }
  }
}
