import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../shops/providers/shops_provider.dart';
import '../../upload/providers/upload_provider.dart';

class CartState {
  final String shopId;
  final List<CartItemModel> services;
  final List<CartItemModel> stationeryItems;

  const CartState({
    required this.shopId,
    this.services = const [],
    this.stationeryItems = const [],
  });

  CartState copyWith({
    String? shopId,
    List<CartItemModel>? services,
    List<CartItemModel>? stationeryItems,
  }) {
    return CartState(
      shopId: shopId ?? this.shopId,
      services: services ?? this.services,
      stationeryItems: stationeryItems ?? this.stationeryItems,
    );
  }

  bool get isEmpty => services.isEmpty && stationeryItems.isEmpty;
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState(shopId: '');
  }

  void setShopId(String shopId) {
    if (state.shopId != shopId) {
      // Clear cart if shop changes
      state = CartState(shopId: shopId);
    }
  }

  // ── Services ───────────────────────────────────────────

  void toggleService(ServiceModel service, {int quantity = 1}) {
    final existingIndex = state.services.indexWhere((item) => item.id == service.id);
    
    if (existingIndex >= 0) {
      // Remove if it exists
      final newServices = List<CartItemModel>.from(state.services)..removeAt(existingIndex);
      state = state.copyWith(services: newServices);
    } else {
      // Add if it doesn't
      final newServices = List<CartItemModel>.from(state.services)
        ..add(CartItemModel(
          id: service.id,
          name: service.name,
          quantity: quantity,
          unitPrice: service.price,
          type: 'service',
        ));
      state = state.copyWith(services: newServices);
    }
  }

  void updateServiceQuantity(String serviceId, int quantity) {
    if (quantity <= 0) {
      final newServices = state.services.where((item) => item.id != serviceId).toList();
      state = state.copyWith(services: newServices);
      return;
    }

    final newServices = state.services.map((item) {
      if (item.id == serviceId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    
    state = state.copyWith(services: newServices);
  }

  // ── Stationery ─────────────────────────────────────────

  void addStationeryItem(ProductModel product, int quantity) {
    if (quantity <= 0) return;

    final existingIndex = state.stationeryItems.indexWhere((item) => item.id == product.id);
    final newItems = List<CartItemModel>.from(state.stationeryItems);

    if (existingIndex >= 0) {
      final existing = newItems[existingIndex];
      newItems[existingIndex] = existing.copyWith(quantity: existing.quantity + quantity);
    } else {
      newItems.add(CartItemModel(
        id: product.id,
        name: product.name,
        quantity: quantity,
        unitPrice: product.price,
        type: 'stationery',
      ));
    }

    state = state.copyWith(stationeryItems: newItems);
  }

  void updateStationeryQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      final newItems = state.stationeryItems.where((item) => item.id != productId).toList();
      state = state.copyWith(stationeryItems: newItems);
      return;
    }

    final newItems = state.stationeryItems.map((item) {
      if (item.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    
    state = state.copyWith(stationeryItems: newItems);
  }

  void removeStationeryItem(String productId) {
    final newItems = state.stationeryItems.where((item) => item.id != productId).toList();
    state = state.copyWith(stationeryItems: newItems);
  }

  void clearCart() {
    state = CartState(shopId: state.shopId);
  }
}

final cartNotifierProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

// ── Derived Providers ────────────────────────────────────

/// Provides live bill calculation
final liveBillingProvider = Provider.autoDispose<BillingModel>((ref) {
  final cart = ref.watch(cartNotifierProvider);
  if (cart.shopId.isEmpty) return BillingModel.empty;

  final shopAsync = ref.watch(shopDetailProvider(cart.shopId));
  final uploadState = ref.watch(uploadNotifierProvider);
  
  return shopAsync.when(
    data: (shop) {
      if (shop == null || shop.pricing == null) return BillingModel.empty;

      int colorPages = 0;
      int bwPages = 0;
      int copies = 1;
      PrintSettingsModel settings = const PrintSettingsModel();

      if (uploadState.fileName != null) {
        final total = uploadState.analysis?.totalPages ?? 1;
        if (uploadState.isColor) {
          colorPages = total;
          bwPages = 0;
        } else {
          bwPages = total;
          colorPages = 0;
        }
        copies = uploadState.copies;
        settings = PrintSettingsModel(
          colorMode: uploadState.isColor ? 'color' : 'bw',
          sides: uploadState.isDuplex ? 'double' : 'single',
          pageSize: uploadState.pageSize,
          copies: uploadState.copies,
        );
      }

      return BillingService.calculateBill(
        colorPages: colorPages,
        bwPages: bwPages,
        copies: copies,
        settings: settings,
        shopPricing: shop.pricing!,
        services: cart.services,
        stationeryItems: cart.stationeryItems,
        taxPercent: shop.pricing?.taxPercent ?? 0.0,
      );
    },
    loading: () => BillingModel.empty,
    error: (_, __) => BillingModel.empty,
  );
});
