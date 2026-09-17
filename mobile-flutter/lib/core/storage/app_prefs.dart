import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-level app preferences that survive restarts.
///
/// Uses the same secure store as [AutoPayLocalStore] rather than adding a
/// second persistence dependency. Every read is defensive: if the keystore is
/// unavailable the app must still open, so failures fall back to a safe value.
class AppPrefs {
  AppPrefs._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _kOnboardingSeen = 'onboarding_completed_v1';
  static const String _kLastRole = 'last_signed_in_role';

  /// True once the member has finished (or skipped) the welcome carousel.
  /// The carousel is a first-run introduction; showing it again on every
  /// launch reads as a bug, so this gate is checked from the splash screen.
  static Future<bool> hasSeenOnboarding() async {
    try {
      return await _storage.read(key: _kOnboardingSeen) == 'true';
    } catch (_) {
      // Keystore unavailable: show the welcome rather than a blank start.
      return false;
    }
  }

  static Future<void> setOnboardingSeen() async {
    try {
      await _storage.write(key: _kOnboardingSeen, value: 'true');
    } catch (_) {
      // Non-fatal: the welcome simply appears once more next launch.
    }
  }

  /// Development helper — lets the profile screen offer "Replay welcome".
  static Future<void> resetOnboarding() async {
    try {
      await _storage.delete(key: _kOnboardingSeen);
    } catch (_) {
      // Non-fatal.
    }
  }

  /// 'member' or 'admin'. Remembered only to pre-select the sign-in mode.
  static Future<String?> lastRole() async {
    try {
      return await _storage.read(key: _kLastRole);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setLastRole(String role) async {
    try {
      await _storage.write(key: _kLastRole, value: role);
    } catch (_) {
      // Non-fatal.
    }
  }
}
