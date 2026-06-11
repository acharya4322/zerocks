import '../models/billing_model.dart';
import '../models/cart_item_model.dart';
import '../models/pricing_model.dart';
import '../models/print_settings_model.dart';

class BillingService {
  /// Calculate the complete bill for an order
  static BillingModel calculateBill({
    required int colorPages,
    required int bwPages,
    required int copies,
    required PrintSettingsModel settings,
    required PricingModel shopPricing,
    required List<CartItemModel> services,
    required List<CartItemModel> stationeryItems,
    double taxPercent = 0.0,
  }) {
    // 1. Calculate print cost
    double printCost = 0;
    
    // If quality is not mixed, we might override color/bw pages based on user selection
    int effectiveColorPages = colorPages;
    int effectiveBwPages = bwPages;

    if (settings.colorMode == 'bw') {
      effectiveBwPages = colorPages + bwPages;
      effectiveColorPages = 0;
    } else if (settings.colorMode == 'color') {
      // In color mode, we charge color price for all pages
      effectiveColorPages = colorPages + bwPages;
      effectiveBwPages = 0;
    }

    // Calculate base price using the shop's calculatePrice method for each type
    // This isn't perfect since duplex/bulk discount applies to the total sheets, 
    // so let's do it manually here for better accuracy with mixed pages.
    
    final bool isDuplex = settings.sides == 'double';
    
    double bwPricePerPage = shopPricing.bwPerPage;
    double colorPricePerPage = shopPricing.colorPerPage;
    
    if (isDuplex && shopPricing.duplexDiscount > 0) {
      bwPricePerPage *= (1 - shopPricing.duplexDiscount / 100);
      colorPricePerPage *= (1 - shopPricing.duplexDiscount / 100);
    }
    
    printCost = (effectiveBwPages * bwPricePerPage + effectiveColorPages * colorPricePerPage) * copies;
    
    // Apply bulk discount to print cost
    final totalSheets = (effectiveBwPages + effectiveColorPages) * copies;
    double bestDiscount = 0;
    for (final entry in shopPricing.bulkDiscounts.entries) {
      if (totalSheets >= entry.key && entry.value > bestDiscount) {
        bestDiscount = entry.value;
      }
    }
    
    if (bestDiscount > 0) {
      printCost *= (1 - bestDiscount / 100);
    }

    // 2. Calculate services cost
    double serviceCharges = 0;
    for (var service in services) {
      serviceCharges += service.total;
    }

    // 3. Calculate stationery cost
    double stationeryCost = 0;
    for (var item in stationeryItems) {
      stationeryCost += item.total;
    }

    // 4. Calculate subtotal and tax
    final double subtotal = printCost + serviceCharges + stationeryCost;
    final double taxAmount = subtotal * (taxPercent / 100);
    final double totalAmount = subtotal + taxAmount;

    return BillingModel(
      printCost: _round(printCost),
      serviceCharges: _round(serviceCharges),
      stationeryCost: _round(stationeryCost),
      subtotal: _round(subtotal),
      taxPercent: taxPercent,
      taxAmount: _round(taxAmount),
      totalAmount: _round(totalAmount),
    );
  }

  static double _round(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}
