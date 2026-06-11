import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  final String status; // "created", "captured", "failed", "refunded"
  final String? method; // "upi", "card", "netbanking", "wallet"
  final DateTime? paidAt;

  const PaymentModel({
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
    required this.status,
    this.method,
    this.paidAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      razorpayOrderId: map['razorpayOrderId'] as String?,
      razorpayPaymentId: map['razorpayPaymentId'] as String?,
      razorpaySignature: map['razorpaySignature'] as String?,
      status: map['status'] as String? ?? 'created',
      method: map['method'] as String?,
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
      if (razorpayPaymentId != null) 'razorpayPaymentId': razorpayPaymentId,
      if (razorpaySignature != null) 'razorpaySignature': razorpaySignature,
      'status': status,
      if (method != null) 'method': method,
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
    };
  }
}
