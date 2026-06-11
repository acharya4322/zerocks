import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../providers/cart_provider.dart';
import '../../../providers/app_providers.dart';

final shopProductsProvider = StreamProvider.family<List<ProductModel>, String>((ref, shopId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamProducts(shopId);
});

class StationeryScreen extends ConsumerWidget {
  final String shopId;

  const StationeryScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(shopProductsProvider(shopId));
    final cart = ref.watch(cartNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stationery & Items'),
        actions: [
          TextButton(
            onPressed: () => context.push('/order/cart/$shopId'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No stationery items available at this shop.'),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.push('/order/cart/$shopId'),
                    child: const Text('Go to Cart'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    if (!product.isAvailable) return const SizedBox.shrink();

                    final cartItem = cart.stationeryItems
                        .where((item) => item.id == product.id)
                        .firstOrNull;
                    final quantityInCart = cartItem?.quantity ?? 0;

                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: product.imageUrl != null
                                ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                                : Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: Icon(Icons.inventory_2_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text('₹${product.price.toStringAsFixed(0)}'),
                                const SizedBox(height: 8),
                                if (quantityInCart > 0)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton.filledTonal(
                                        onPressed: () => ref.read(cartNotifierProvider.notifier).updateStationeryQuantity(product.id, quantityInCart - 1),
                                        icon: const Icon(Icons.remove, size: 16),
                                        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                                        padding: EdgeInsets.zero,
                                      ),
                                      Text('$quantityInCart', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton.filledTonal(
                                        onPressed: () => ref.read(cartNotifierProvider.notifier).addStationeryItem(product, 1),
                                        icon: const Icon(Icons.add, size: 16),
                                        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  )
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () => ref.read(cartNotifierProvider.notifier).addStationeryItem(product, 1),
                                      child: const Text('Add'),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: () => context.push('/order/cart/$shopId'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text('Review Cart'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
