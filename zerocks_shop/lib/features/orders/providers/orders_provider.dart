import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../providers/app_providers.dart';

final shopOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final shopAsync = ref.watch(shopProvider);
  final shop = shopAsync.value;
  if (shop == null) return Stream.value([]);

  final firestoreService = ref.watch(firestoreServiceProvider);
  // We should stream active orders first
  return firestoreService.streamActiveOrdersByShop(shop.id);
});

final orderDetailProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamOrder(orderId);
});

class OrdersNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    state = const AsyncLoading();
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateOrderStatus(orderId, status);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final ordersNotifierProvider = AsyncNotifierProvider<OrdersNotifier, void>(OrdersNotifier.new);
