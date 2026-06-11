/// Granular pricing configuration for a print shop.
/// Stored as a map within the `shops/{shopId}` document.
class PricingModel {
  final double bwPerPage;
  final double colorPerPage;
  final double duplexDiscount; // percentage (0–100)
  final Map<int, double> bulkDiscounts; // minPages → discount%
  final double taxPercent;

  const PricingModel({
    this.bwPerPage = 2.0,
    this.colorPerPage = 10.0,
    this.duplexDiscount = 0,
    this.bulkDiscounts = const {},
    this.taxPercent = 0.0,
  });

  factory PricingModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PricingModel();
    return PricingModel(
      bwPerPage: (map['bwPerPage'] as num?)?.toDouble() ?? 2.0,
      colorPerPage: (map['colorPerPage'] as num?)?.toDouble() ?? 10.0,
      duplexDiscount: (map['duplexDiscount'] as num?)?.toDouble() ?? 0,
      taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0.0,
      bulkDiscounts: (map['bulkDiscount'] as Map<String, dynamic>?)?.map(
            (key, value) =>
                MapEntry(int.tryParse(key) ?? 0, (value as num).toDouble()),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bwPerPage': bwPerPage,
      'colorPerPage': colorPerPage,
      'duplexDiscount': duplexDiscount,
      'taxPercent': taxPercent,
      'bulkDiscount': bulkDiscounts.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }

  /// Calculate total price for a job.
  double calculatePrice({
    required int totalPages,
    required int copies,
    required bool isColor,
    required bool isDuplex,
  }) {
    final basePrice = isColor ? colorPerPage : bwPerPage;
    var pricePerPage = basePrice;

    // Apply duplex discount
    if (isDuplex && duplexDiscount > 0) {
      pricePerPage *= (1 - duplexDiscount / 100);
    }

    final totalSheets = totalPages * copies;
    var total = pricePerPage * totalSheets;

    // Apply bulk discount (use the highest qualifying tier)
    double bestDiscount = 0;
    for (final entry in bulkDiscounts.entries) {
      if (totalSheets >= entry.key && entry.value > bestDiscount) {
        bestDiscount = entry.value;
      }
    }
    if (bestDiscount > 0) {
      total *= (1 - bestDiscount / 100);
    }

    return double.parse(total.toStringAsFixed(2));
  }

  PricingModel copyWith({
    double? bwPerPage,
    double? colorPerPage,
    double? duplexDiscount,
    Map<int, double>? bulkDiscounts,
  }) {
    return PricingModel(
      bwPerPage: bwPerPage ?? this.bwPerPage,
      colorPerPage: colorPerPage ?? this.colorPerPage,
      duplexDiscount: duplexDiscount ?? this.duplexDiscount,
      bulkDiscounts: bulkDiscounts ?? this.bulkDiscounts,
    );
  }
}
