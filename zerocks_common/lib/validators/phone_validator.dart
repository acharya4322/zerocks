/// Validates and formats Indian phone numbers for Firebase Phone Auth.
class PhoneValidator {
  static const String indiaCountryCode = '+91';
  static const int indianNumberLength = 10;

  /// Validate an Indian phone number (10 digits, starting with 6–9).
  static ValidationResult validate(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Strip country code if present
    String digits = cleaned;
    if (digits.startsWith('+91')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length != indianNumberLength) {
      return ValidationResult.error(
        'Please enter a valid 10-digit phone number.',
      );
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return ValidationResult.error(
        'Indian mobile numbers must start with 6, 7, 8, or 9.',
      );
    }

    return ValidationResult.ok();
  }

  /// Format a phone number to E.164 format for Firebase.
  /// Example: "9876543210" → "+919876543210"
  static String toE164(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    String digits = cleaned;

    if (digits.startsWith('+91')) return digits;
    if (digits.startsWith('91') && digits.length == 12) {
      return '+$digits';
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return '$indiaCountryCode$digits';
  }

  /// Format for display: "+91 98765 43210"
  static String toDisplay(String phone) {
    final e164 = toE164(phone);
    if (e164.length != 13) return e164;
    return '${e164.substring(0, 3)} ${e164.substring(3, 8)} ${e164.substring(8)}';
  }
}

/// Reuse the same validation result type.
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._({required this.isValid, this.errorMessage});

  factory ValidationResult.ok() =>
      const ValidationResult._(isValid: true);

  factory ValidationResult.error(String message) =>
      ValidationResult._(isValid: false, errorMessage: message);
}
