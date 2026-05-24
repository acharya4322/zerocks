import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';
import '../providers/shops_provider.dart';

class ShopsScreen extends ConsumerWidget {
  const ShopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(allShopsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('Shops', style: textTheme.headlineLarge),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.go('/shops/create'),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Create New Shop'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 50),
                _headerCell('SHOP NAME', flex: 3, textTheme: textTheme),
                _headerCell('ADDRESS', flex: 3, textTheme: textTheme),
                _headerCell('STATUS', width: 100, textTheme: textTheme),
                _headerCell('PRICE/PAGE', width: 100, textTheme: textTheme),
                _headerCell('CREATED', width: 120, textTheme: textTheme),
                _headerCell('ACTIONS', width: 120, textTheme: textTheme, align: TextAlign.right),
              ],
            ),
          ),

          // Shop list
          Expanded(
            child: shopsAsync.when(
              data: (shops) {
                if (shops.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_outlined, size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 18),
                        Text('No shops yet', style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        )),
                        const SizedBox(height: 8),
                        Text('Create your first shop to get started',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                            )),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => context.go('/shops/create'),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Shop'),
                        ),
                      ],
                    ),
                  );
                }

                return Card(
                  margin: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: ListView.separated(
                    itemCount: shops.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.08),
                    ),
                    itemBuilder: (context, index) {
                      final shop = shops[index];
                      return _ShopRow(shop: shop);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int? flex, double? width, required TextTheme textTheme, TextAlign? align}) {
    final child = Text(
      text,
      style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1),
      textAlign: align ?? TextAlign.left,
    );
    if (flex != null) return Expanded(flex: flex, child: child);
    return SizedBox(width: width, child: child);
  }
}

class _ShopRow extends ConsumerWidget {
  final ShopModel shop;

  const _ShopRow({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = shop.isOnline ? AppTheme.onlineColor : AppTheme.offlineColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.store, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 10),

          // Name
          Expanded(
            flex: 3,
            child: Text(shop.name, style: textTheme.titleSmall, overflow: TextOverflow.ellipsis),
          ),

          // Address
          Expanded(
            flex: 3,
            child: Text(shop.address, style: textTheme.bodySmall, overflow: TextOverflow.ellipsis),
          ),

          // Status
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    shop.isOnline ? 'Online' : 'Offline',
                    style: textTheme.labelSmall?.copyWith(
                      color: statusColor, fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Price
          SizedBox(
            width: 100,
            child: Text('₹${shop.pricePerPage.toStringAsFixed(1)}',
                style: textTheme.bodyMedium, textAlign: TextAlign.center),
          ),

          // Created
          SizedBox(
            width: 120,
            child: Text(
              DateFormat('MMM d, yyyy').format(shop.createdAt),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),

          // Actions
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Tooltip(
                  message: shop.isOnline ? 'Set Offline' : 'Set Online',
                  child: IconButton(
                    icon: Icon(
                      shop.isOnline ? Icons.toggle_on : Icons.toggle_off,
                      color: statusColor,
                      size: 28,
                    ),
                    onPressed: () async {
                      final firestoreService = ref.read(firestoreServiceProvider);
                      await firestoreService.updateShopOnlineStatus(shop.id, !shop.isOnline);
                    },
                  ),
                ),
                Tooltip(
                  message: 'Delete Shop',
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Shop'),
        content: Text('Are you sure you want to delete "${shop.name}"?\n\nThis will not delete the Firebase Auth account — only the shop document.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deleteShop(shop.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${shop.name} deleted')),
        );
      }
    }
  }
}
