import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a shop owner or operator account.
/// Stored in the `shopOwners` Firestore collection, separate from customers.
class ShopOwnerModel {
  final String uid;
  final String email;
  final String? displayName;
  final String shopId;
  final String role; // 'owner' | 'operator'
  final DateTime createdAt;
  final bool isApproved;

  const ShopOwnerModel({
    required this.uid,
    required this.email,
    this.displayName,
    required this.shopId,
    this.role = 'owner',
    required this.createdAt,
    this.isApproved = false,
  });

  factory ShopOwnerModel.fromMap(Map<String, dynamic> map) {
    return ShopOwnerModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      shopId: map['shopId'] as String,
      role: map['role'] as String? ?? 'owner',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isApproved: map['isApproved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'shopId': shopId,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'isApproved': isApproved,
    };
  }

  ShopOwnerModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? shopId,
    String? role,
    DateTime? createdAt,
    bool? isApproved,
  }) {
    return ShopOwnerModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      shopId: shopId ?? this.shopId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isApproved: isApproved ?? this.isApproved,
    );
  }
}
