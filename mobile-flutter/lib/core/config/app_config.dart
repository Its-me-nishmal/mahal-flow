/// App-wide constants that are not design tokens. One place to change them
/// before a release.
class AppConfig {
  AppConfig._();

  // TODO(release): replace with the published legal pages.
  static const String termsUrl = 'https://mahalflow.com/terms';
  static const String privacyUrl = 'https://mahalflow.com/privacy';

  /// Seconds before "Resend code" becomes available again on the OTP screen.
  static const int otpResendCooldownSeconds = 30;
}
