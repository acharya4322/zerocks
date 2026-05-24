import 'dart:math';

/// Geolocation utility functions for shop discovery and distance calculation.
class GeoUtils {
  GeoUtils._();

  static const double _earthRadiusKm = 6371.0;

  /// Calculate distance between two coordinates in kilometers (Haversine formula).
  static double distanceKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// Format distance for display.
  /// Examples: "500 m", "1.2 km", "15 km"
  static String formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }

  /// Generate a geohash for Firestore geo queries.
  /// Uses a simple geohash algorithm with configurable precision.
  /// Precision 6 ≈ ±0.6 km, Precision 7 ≈ ±0.076 km
  static String encodeGeohash(double latitude, double longitude,
      {int precision = 7}) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

    double minLat = -90, maxLat = 90;
    double minLng = -180, maxLng = 180;
    bool isEven = true;
    int bit = 0;
    int ch = 0;
    final buffer = StringBuffer();

    while (buffer.length < precision) {
      if (isEven) {
        final mid = (minLng + maxLng) / 2;
        if (longitude >= mid) {
          ch |= (1 << (4 - bit));
          minLng = mid;
        } else {
          maxLng = mid;
        }
      } else {
        final mid = (minLat + maxLat) / 2;
        if (latitude >= mid) {
          ch |= (1 << (4 - bit));
          minLat = mid;
        } else {
          maxLat = mid;
        }
      }

      isEven = !isEven;
      bit++;

      if (bit == 5) {
        buffer.write(base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return buffer.toString();
  }

  /// Get bounding box for a geohash-based range query.
  /// Returns (minHash, maxHash) for Firestore where/orderBy queries.
  static ({String minHash, String maxHash}) geohashRange(
    double latitude,
    double longitude, {
    double radiusKm = 5.0,
    int precision = 5,
  }) {
    final hash = encodeGeohash(latitude, longitude, precision: precision);
    // Replace last char with range bounds
    final minHash = hash;
    final maxHash = '$hash~'; // '~' is after 'z' in ASCII
    return (minHash: minHash, maxHash: maxHash);
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
