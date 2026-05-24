import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';

class OnlineToggle extends ConsumerStatefulWidget {
  const OnlineToggle({super.key});

  @override
  ConsumerState<OnlineToggle> createState() => _OnlineToggleState();
}

class _OnlineToggleState extends ConsumerState<OnlineToggle> {
  bool _isUpdating = false;

  Future<void> _toggleOnlineStatus(ShopModel shop) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateShopOnlineStatus(shop.id, !shop.isOnline);
      // Refresh the shop provider to reflect changes
      ref.invalidate(shopProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(shopProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return shopAsync.when(
      data: (shop) {
        if (shop == null) {
          return const SizedBox.shrink();
        }

        final isOnline = shop.isOnline;
        final statusColor =
            isOnline ? AppTheme.onlineColor : AppTheme.offlineColor;
        final statusText = isOnline ? 'Online' : 'Offline';
        final statusSubtext = isOnline
            ? 'Your shop is visible to customers'
            : 'Your shop is hidden from customers';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: statusColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                // Status indicator dot
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Status text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shop Status: $statusText',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusSubtext,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Toggle switch
                _isUpdating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Transform.scale(
                        scale: 1.2,
                        child: Switch(
                          value: isOnline,
                          onChanged: (_) => _toggleOnlineStatus(shop),
                          activeThumbColor: AppTheme.onlineColor,
                          activeTrackColor:
                              AppTheme.onlineColor.withValues(alpha: 0.3),
                          inactiveThumbColor: AppTheme.offlineColor,
                          inactiveTrackColor:
                              AppTheme.offlineColor.withValues(alpha: 0.2),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error loading shop: $error'),
        ),
      ),
    );
  }
}
