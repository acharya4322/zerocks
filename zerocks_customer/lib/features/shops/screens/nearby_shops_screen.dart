import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../providers/shops_provider.dart';
import '../widgets/shop_card.dart';

class NearbyShopsScreen extends ConsumerStatefulWidget {
  const NearbyShopsScreen({super.key});

  @override
  ConsumerState<NearbyShopsScreen> createState() => _NearbyShopsScreenState();
}

class _NearbyShopsScreenState extends ConsumerState<NearbyShopsScreen> {
  GoogleMapController? _mapController;

  Set<Marker> _buildMarkers(List<ShopModel> shops) {
    return shops.map((shop) {
      return Marker(
        markerId: MarkerId(shop.id),
        position: LatLng(shop.latitude, shop.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          shop.isOnline
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: shop.name,
          snippet:
              '₹${shop.pricePerPage.toStringAsFixed(1)}/page • ${shop.isOnline ? "Online" : "Offline"}',
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);
    final shopsAsync = ref.watch(nearbyShopsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Shops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(currentPositionProvider);
              ref.invalidate(nearbyShopsProvider);
            },
          ),
        ],
      ),
      body: positionAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Getting your location...'),
            ],
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_off_outlined,
                  size: 64,
                  color: colorScheme.error.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Location Error',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(currentPositionProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (position) {
          final userLat = position.latitude;
          final userLng = position.longitude;

          // Build markers from shops data (empty set if loading/error)
          final markers = shopsAsync.whenData(
            (shops) => _buildMarkers(shops),
          );

          return Column(
            children: [
              // Map (top half) — SINGLE instance, markers update reactively
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(userLat, userLng),
                        zoom: 14,
                      ),
                      markers: markers.value ?? {},
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                    ),
                    if (shopsAsync.isLoading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
              // Divider
              Container(
                height: 4,
                color: colorScheme.surfaceContainerHighest,
              ),
              // Shops List (bottom half)
              Expanded(
                flex: 5,
                child: shopsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load shops',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  data: (shops) {
                    if (shops.isEmpty) {
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
                              'No shops nearby',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try expanding your search area',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Sort by online first, then by distance
                    final sortedShops = List<ShopModel>.from(shops);
                    sortedShops.sort((a, b) {
                      if (a.isOnline != b.isOnline) {
                        return a.isOnline ? -1 : 1;
                      }
                      final distA = calculateDistanceKm(
                        lat1: userLat,
                        lon1: userLng,
                        lat2: a.latitude,
                        lon2: a.longitude,
                      );
                      final distB = calculateDistanceKm(
                        lat1: userLat,
                        lon1: userLng,
                        lat2: b.latitude,
                        lon2: b.longitude,
                      );
                      return distA.compareTo(distB);
                    });

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: sortedShops.length,
                      itemBuilder: (context, index) {
                        return ShopCard(
                          shop: sortedShops[index],
                          userLat: userLat,
                          userLng: userLng,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
