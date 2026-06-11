import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../providers/shops_provider.dart';
import '../providers/shop_products_provider.dart';
import '../../order/providers/cart_provider.dart';
import '../../upload/providers/upload_provider.dart';

class ShopDetailScreen extends ConsumerWidget {
  final String shopId;

  const ShopDetailScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopDetailProvider(shopId));
    final positionAsync = ref.watch(currentPositionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Details'),
      ),
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load shop details',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => ref.invalidate(shopDetailProvider(shopId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (shop) {
          if (shop == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Shop not found',
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          String? distanceText;
          positionAsync.whenData((position) {
            final dist = calculateDistanceKm(
              lat1: position.latitude,
              lon1: position.longitude,
              lat2: shop.latitude,
              lon2: shop.longitude,
            );
            distanceText = dist < 1
                ? '${(dist * 1000).round()} m away'
                : '${dist.toStringAsFixed(1)} km away';
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Shop Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: shop.isOnline
                                ? const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.12)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.storefront,
                            size: 40,
                            color: shop.isOnline
                                ? const Color(0xFF4CAF50)
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          shop.name,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: shop.isOnline
                                ? const Color(0xFF4CAF50)
                                    .withValues(alpha: 0.12)
                                : const Color(0xFF9E9E9E)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: shop.isOnline
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF9E9E9E),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                shop.isOnline
                                    ? 'Currently Online'
                                    : 'Currently Offline',
                                style: textTheme.labelLarge?.copyWith(
                                  color: shop.isOnline
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFF9E9E9E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Details Card
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: shop.address,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        ),
                        Divider(
                          height: 24,
                          color: colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                        _DetailRow(
                          icon: Icons.currency_rupee,
                          label: 'Price per Page',
                          value:
                              '₹${shop.pricePerPage.toStringAsFixed(1)}',
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        ),
                        if (distanceText != null) ...[
                          Divider(
                            height: 24,
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                          _DetailRow(
                            icon: Icons.near_me_outlined,
                            label: 'Distance',
                            value: distanceText!,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: shop.isOnline
                            ? () {
                                ref.read(uploadNotifierProvider.notifier).reset();
                                context.push('/upload/${shop.id}');
                                Future.delayed(const Duration(milliseconds: 400), () {
                                  ref.read(uploadNotifierProvider.notifier).scanDocument();
                                });
                              }
                            : null,
                        icon: const Icon(Icons.document_scanner),
                        label: const Text('Scan'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: shop.isOnline
                            ? () {
                                ref.read(uploadNotifierProvider.notifier).reset();
                                context.push('/upload/${shop.id}');
                              }
                            : null,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: colorScheme.secondaryContainer,
                          foregroundColor: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!shop.isOnline) ...[
                  const SizedBox(height: 12),
                  Text(
                    'This shop is currently offline. '
                    'You can upload documents when the shop is online.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],

                const SizedBox(height: 48),

                // Products Section
                Text(
                  'Stationery & Gifts',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final productsAsync = ref.watch(shopProductsProvider(shop.id));
                    
                    return productsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error loading products: $e'),
                      data: (products) {
                        if (products.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                'No products available right now.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _ProductCard(product: product, shopId: shop.id);
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final ProductModel product;
  final String shopId;

  const _ProductCard({required this.product, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.image_outlined, color: colorScheme.onSurfaceVariant, size: 32),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () {
                      // Add to Cart
                      ref.read(cartNotifierProvider.notifier)
                         .addStationeryItem(product, 1);
                      
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart!'),
                          action: SnackBarAction(
                            label: 'VIEW CART',
                            onPressed: () => context.push('/order/cart/$shopId'),
                          ),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

