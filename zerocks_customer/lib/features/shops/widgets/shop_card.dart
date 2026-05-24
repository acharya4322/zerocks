import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../providers/shops_provider.dart';

class ShopCard extends StatelessWidget {
  final ShopModel shop;
  final double? userLat;
  final double? userLng;

  const ShopCard({
    super.key,
    required this.shop,
    this.userLat,
    this.userLng,
  });

  String? get _distanceText {
    if (userLat == null || userLng == null) return null;
    final distKm = calculateDistanceKm(
      lat1: userLat!,
      lon1: userLng!,
      lat2: shop.latitude,
      lon2: shop.longitude,
    );
    if (distKm < 1) {
      return '${(distKm * 1000).round()} m';
    }
    return '${distKm.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: () => context.push('/shop/${shop.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Shop Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: shop.isOnline
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.12)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.storefront,
                  color: shop.isOnline
                      ? const Color(0xFF4CAF50)
                      : colorScheme.onSurfaceVariant,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            shop.name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Status dot
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
                        const SizedBox(width: 4),
                        Text(
                          shop.isOnline ? 'Online' : 'Offline',
                          style: textTheme.labelSmall?.copyWith(
                            color: shop.isOnline
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF9E9E9E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.address,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.currency_rupee,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                        Text(
                          '${shop.pricePerPage.toStringAsFixed(1)}/page',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_distanceText != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _distanceText!,
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
