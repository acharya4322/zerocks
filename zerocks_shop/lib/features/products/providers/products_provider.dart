import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../providers/app_providers.dart';

final shopProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final shopAsync = ref.watch(shopProvider);
  final shop = shopAsync.value;
  if (shop == null) return Stream.value([]);

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamProducts(shop.id);
});

class ProductsNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addProduct(ProductModel product) async {
    state = const AsyncLoading();
    try {
      final shop = ref.read(shopProvider).value;
      if (shop == null) throw Exception('No shop found');
      
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createProduct(shop.id, product);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final shop = ref.read(shopProvider).value;
      if (shop == null) throw Exception('No shop found');
      
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateProduct(shop.id, productId, data);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteProduct(String productId) async {
    state = const AsyncLoading();
    try {
      final shop = ref.read(shopProvider).value;
      if (shop == null) throw Exception('No shop found');
      
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deleteProduct(shop.id, productId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final productsNotifierProvider = AsyncNotifierProvider<ProductsNotifier, void>(ProductsNotifier.new);
