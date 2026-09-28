/// Indian mobile number helpers.
class PhoneFormat {
  PhoneFormat._();

  /// Last 10 digits of an Indian mobile ("+91 98471-23456" → "9847123456"),
  /// or the digits as-is when fewer than 10.
  static String nationalDigits(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  /// True for a 10-digit Indian mobile starting 6–9.
  static bool isValidIndianMobile(String raw) =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(nationalDigits(raw));

  /// Display form: "+91 98471 23456". Anything that is not a 10-digit number
  /// (after dropping the country code) is returned unchanged.
  static String display(String raw) {
    final national = nationalDigits(raw);
    if (national.length != 10) return raw;
    return '+91 ${national.substring(0, 5)} ${national.substring(5)}';
  }
}
