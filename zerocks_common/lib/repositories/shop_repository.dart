import '../models/shop_model.dart';
import '../services/firestore_service.dart';
import '../utils/geo_utils.dart';
import '../utils/logger.dart';

/// Repository for shop operations.
/// Provides distance-enriched shop discovery and management.
class ShopRepository {
  final FirestoreService _firestore;

  ShopRepository(this._firestore);

  /// Get a shop by ID.
  Future<ShopModel?> getShop(String shopId) {
    return _firestore.getShop(shopId);
  }

  /// Get shop by owner UID.
  Future<ShopModel?> getShopByOwner(String ownerId) {
    return _firestore.getShopByOwner(ownerId);
  }

  /// Stream nearby shops with distance calculation.
  /// Enriches each shop with distance from the user's location.
  Stream<List<ShopWithDistance>> streamNearbyShops({
    required double userLat,
    required double userLng,
    double radiusKm = 5.0,
  }) {
    return _firestore
        .getNearbyShops(
          latitude: userLat,
          longitude: userLng,
          radiusKm: radiusKm,
        )
        .map((shops) {
      final enriched = shops.map((shop) {
        final distance = GeoUtils.distanceKm(
          lat1: userLat,
          lng1: userLng,
          lat2: shop.latitude,
          lng2: shop.longitude,
        );
        return ShopWithDistance(shop: shop, distanceKm: distance);
      }).toList();

      // Sort by distance
      enriched.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return enriched;
    });
  }

  /// Toggle shop online/offline status.
  Future<void> setOnlineStatus(String shopId, bool isOnline) async {
    await _firestore.updateShopOnlineStatus(shopId, isOnline);
    ZLogger.info(
      'Shop $shopId → ${isOnline ? "online" : "offline"}',
      tag: 'ShopRepo',
    );
  }

  /// Stream all shops (admin).
  Stream<List<ShopModel>> streamAllShops() {
    return _firestore.getAllShops();
  }

  /// Update shop details.
  Future<void> updateShop(String shopId, Map<String, dynamic> data) {
    return _firestore.updateShop(shopId, data);
  }

  /// Delete a shop (admin only).
  Future<void> deleteShop(String shopId) {
    return _firestore.deleteShop(shopId);
  }
}

/// A shop enriched with distance from the user's current location.
class ShopWithDistance {
  final ShopModel shop;
  final double distanceKm;

  const ShopWithDistance({
    required this.shop,
    required this.distanceKm,
  });

  /// Formatted distance string: "500 m" or "2.3 km"
  String get distanceFormatted => GeoUtils.formatDistance(distanceKm);
}
