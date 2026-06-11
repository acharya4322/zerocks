class BillingModel {
  final double printCost;
  final double serviceCharges;
  final double stationeryCost;
  final double subtotal;
  final double taxPercent;
  final double taxAmount;
  final double totalAmount;

  const BillingModel({
    required this.printCost,
    required this.serviceCharges,
    required this.stationeryCost,
    required this.subtotal,
    this.taxPercent = 0.0,
    required this.taxAmount,
    required this.totalAmount,
  });

  factory BillingModel.fromMap(Map<String, dynamic> map) {
    return BillingModel(
      printCost: (map['printCost'] as num?)?.toDouble() ?? 0.0,
      serviceCharges: (map['serviceCharges'] as num?)?.toDouble() ?? 0.0,
      stationeryCost: (map['stationeryCost'] as num?)?.toDouble() ?? 0.0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'printCost': printCost,
      'serviceCharges': serviceCharges,
      'stationeryCost': stationeryCost,
      'subtotal': subtotal,
      'taxPercent': taxPercent,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
    };
  }

  static const BillingModel empty = BillingModel(
    printCost: 0,
    serviceCharges: 0,
    stationeryCost: 0,
    subtotal: 0,
    taxAmount: 0,
    totalAmount: 0,
  );
}
