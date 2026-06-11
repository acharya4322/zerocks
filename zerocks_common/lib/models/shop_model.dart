import 'package:cloud_firestore/cloud_firestore.dart';
import 'pricing_model.dart';

class ShopModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? geohash;
  final bool isOnline;
  final bool isVerified;
  final bool isApproved;
  final String ownerId;
  final String? uniqueShopCode;
  final String? qrData;
  final double pricePerPage;
  final PricingModel? pricing;

  // Capabilities
  final bool hasColor;
  final bool hasDuplex;
  final bool hasA3;
  final bool hasScanning;
  final bool hasBinding;

  // Operating hours: { "monday": { "open": "09:00", "close": "21:00" }, ... }
  final Map<String, Map<String, String>>? operatingHours;

  // Denormalized stats
  final int totalJobs;
  final int activeJobs;
  final double avgRating;
  final int todayJobs;

  // Push notification
  final String? fcmToken;

  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ShopModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.geohash,
    required this.isOnline,
    this.isVerified = false,
    this.isApproved = true,
    required this.ownerId,
    this.uniqueShopCode,
    this.qrData,
    required this.pricePerPage,
    this.pricing,
    this.hasColor = false,
    this.hasDuplex = false,
    this.hasA3 = false,
    this.hasScanning = false,
    this.hasBinding = false,
    this.operatingHours,
    this.totalJobs = 0,
    this.activeJobs = 0,
    this.avgRating = 0,
    this.todayJobs = 0,
    this.fcmToken,
    required this.createdAt,
    this.updatedAt,
  });

  factory ShopModel.fromMap(Map<String, dynamic> map, String docId) {
    final capabilities = map['capabilities'] as Map<String, dynamic>?;
    final stats = map['stats'] as Map<String, dynamic>?;
    final hours = map['operatingHours'] as Map<String, dynamic>?;

    return ShopModel(
      id: docId,
      name: map['name'] as String,
      address: map['address'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      geohash: map['geohash'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      isVerified: map['isVerified'] as bool? ?? false,
      isApproved: map['isApproved'] as bool? ?? true,
      ownerId: map['ownerId'] as String,
      uniqueShopCode: map['uniqueShopCode'] as String?,
      qrData: map['qrData'] as String?,
      pricePerPage: (map['pricePerPage'] as num).toDouble(),
      pricing: map['pricing'] != null
          ? PricingModel.fromMap(map['pricing'] as Map<String, dynamic>)
          : null,
      // Capabilities
      hasColor: capabilities?['color'] as bool? ?? false,
      hasDuplex: capabilities?['duplex'] as bool? ?? false,
      hasA3: capabilities?['a3'] as bool? ?? false,
      hasScanning: capabilities?['scanning'] as bool? ?? false,
      hasBinding: capabilities?['binding'] as bool? ?? false,
      // Operating hours
      operatingHours: hours?.map((key, value) => MapEntry(
            key,
            (value as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v as String),
            ),
          )),
      // Stats
      totalJobs: stats?['totalJobs'] as int? ?? 0,
      activeJobs: stats?['activeJobs'] as int? ?? 0,
      avgRating: (stats?['avgRating'] as num?)?.toDouble() ?? 0,
      todayJobs: stats?['todayJobs'] as int? ?? 0,
      // FCM
      fcmToken: map['fcmToken'] as String?,
      // Timestamps
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'geohash': geohash,
      'isOnline': isOnline,
      'isVerified': isVerified,
      'isApproved': isApproved,
      'ownerId': ownerId,
      'uniqueShopCode': uniqueShopCode,
      'qrData': qrData,
      'pricePerPage': pricePerPage,
      'pricing': pricing?.toMap(),
      'capabilities': {
        'color': hasColor,
        'duplex': hasDuplex,
        'a3': hasA3,
        'scanning': hasScanning,
        'binding': hasBinding,
      },
      'operatingHours': operatingHours,
      'stats': {
        'totalJobs': totalJobs,
        'activeJobs': activeJobs,
        'avgRating': avgRating,
        'todayJobs': todayJobs,
      },
      'fcmToken': fcmToken,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ShopModel copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? geohash,
    bool? isOnline,
    bool? isVerified,
    bool? isApproved,
    String? ownerId,
    String? uniqueShopCode,
    String? qrData,
    double? pricePerPage,
    PricingModel? pricing,
    bool? hasColor,
    bool? hasDuplex,
    bool? hasA3,
    bool? hasScanning,
    bool? hasBinding,
    Map<String, Map<String, String>>? operatingHours,
    int? totalJobs,
    int? activeJobs,
    double? avgRating,
    int? todayJobs,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geohash: geohash ?? this.geohash,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      isApproved: isApproved ?? this.isApproved,
      ownerId: ownerId ?? this.ownerId,
      uniqueShopCode: uniqueShopCode ?? this.uniqueShopCode,
      qrData: qrData ?? this.qrData,
      pricePerPage: pricePerPage ?? this.pricePerPage,
      pricing: pricing ?? this.pricing,
      hasColor: hasColor ?? this.hasColor,
      hasDuplex: hasDuplex ?? this.hasDuplex,
      hasA3: hasA3 ?? this.hasA3,
      hasScanning: hasScanning ?? this.hasScanning,
      hasBinding: hasBinding ?? this.hasBinding,
      operatingHours: operatingHours ?? this.operatingHours,
      totalJobs: totalJobs ?? this.totalJobs,
      activeJobs: activeJobs ?? this.activeJobs,
      avgRating: avgRating ?? this.avgRating,
      todayJobs: todayJobs ?? this.todayJobs,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
