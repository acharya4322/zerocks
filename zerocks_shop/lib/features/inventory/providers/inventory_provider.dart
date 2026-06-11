import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../providers/app_providers.dart';

final shopInventoryProvider = StreamProvider<List<InventoryModel>>((ref) {
  final shopAsync = ref.watch(shopProvider);
  final shop = shopAsync.value;
  if (shop == null) return Stream.value([]);

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamInventory(shop.id);
});

class InventoryNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addInventory(InventoryModel item) async {
    state = const AsyncLoading();
    try {
      final shop = ref.read(shopProvider).value;
      if (shop == null) throw Exception('No shop found');
      
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createInventory(shop.id, item);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateInventory(String itemId, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final shop = ref.read(shopProvider).value;
      if (shop == null) throw Exception('No shop found');
      
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateInventory(shop.id, itemId, data);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteInventory(String itemId) async {
    state = const AsyncLoading();
    try {
      final shop = ref.read(shopProvider).value;
      if (shop == null) throw Exception('No shop found');
      
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deleteInventory(shop.id, itemId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final inventoryNotifierProvider = AsyncNotifierProvider<InventoryNotifier, void>(InventoryNotifier.new);
