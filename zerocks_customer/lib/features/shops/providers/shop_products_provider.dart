import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../providers/app_providers.dart';

final shopProductsProvider = StreamProvider.family<List<ProductModel>, String>((ref, shopId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamProducts(shopId).map((products) {
    // Only return products that are available and have stock
    return products.where((p) => p.isAvailable && p.stock > 0).toList();
  });
});

final featuredProductsProvider = FutureProvider.family<List<ProductModel>, String>((ref, shopId) async {
  // In a real scenario, this might query a specific featured flag or use an algolia index.
  // For now, we take the first 5 available products.
  final products = await ref.watch(shopProductsProvider(shopId).future);
  return products.take(5).toList();
});
