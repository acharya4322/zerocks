class PaymentConfig {
  /// Your Razorpay Key ID (Test or Live).
  /// Format: 'rzp_test_xxxxxxx' or 'rzp_live_xxxxxxx'.
  /// Get this key from settings on the Razorpay Dashboard.
  static const String razorpayKeyId = 'rzp_test_placeholder';

  /// Check if the configuration has been modified with an actual API key
  static bool get isConfigured {
    return razorpayKeyId != 'rzp_test_placeholder';
  }
}
