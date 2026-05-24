import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';

// ── Location Provider ─────────────────────────────────────

final currentPositionProvider = FutureProvider<Position>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled. Please enable them.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied. Please grant access.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception(
      'Location permission permanently denied. '
      'Please enable it in device settings.',
    );
  }

  return await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    ),
  );
});

// ── Nearby Shops Provider ─────────────────────────────────

final nearbyShopsProvider = StreamProvider<List<ShopModel>>((ref) {
  final positionAsync = ref.watch(currentPositionProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);

  return positionAsync.when(
    data: (position) => firestoreService.getNearbyShops(
      latitude: position.latitude,
      longitude: position.longitude,
      radiusKm: AppConstants.defaultSearchRadiusKm,
    ),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

// ── Shop Detail Provider ──────────────────────────────────

final shopDetailProvider =
    FutureProvider.family<ShopModel?, String>((ref, shopId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getShop(shopId);
});

// ── Distance Calculation ──────────────────────────────────

double calculateDistanceKm({
  required double lat1,
  required double lon1,
  required double lat2,
  required double lon2,
}) {
  const p = 0.017453292519943295; // pi / 180
  final a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a)); // 2 * R * asin(sqrt(a))
}
