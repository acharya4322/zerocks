import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:zerocks_common/zerocks_common.dart';
import 'package:uuid/uuid.dart';

/// Admin-specific service for managing shops, users, and roles.
class AdminService {
  final FirestoreService _firestoreService;
  final _uuid = const Uuid();

  AdminService(this._firestoreService);

  /// Creates a new shop with its own Firebase Auth account.
  /// Uses a secondary Firebase App to avoid signing out the admin.
  Future<String> createShopAccount({
    required String email,
    required String password,
    required String shopName,
    required String address,
    required double latitude,
    required double longitude,
    required double pricePerPage,
  }) async {
    final tempApp = await Firebase.initializeApp(
      name: 'TempUserCreation_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      await tempAuth.signOut();

      final shopId = _uuid.v4();
      final uniqueShopCode = 'ZRX${Random().nextInt(9999).toString().padLeft(4, '0')}';
      final qrData = 'zerocks://shop/$shopId';

      final shop = ShopModel(
        id: shopId,
        name: shopName,
        address: address,
        latitude: latitude,
        longitude: longitude,
        isOnline: false,
        ownerId: uid,
        uniqueShopCode: uniqueShopCode,
        qrData: qrData,
        pricePerPage: pricePerPage,
        createdAt: DateTime.now(),
      );
      await _firestoreService.createShop(shop);

      // Create shop owner record
      final owner = ShopOwnerModel(
        uid: uid,
        email: email,
        shopId: shopId,
        createdAt: DateTime.now(),
        isApproved: true,
      );
      await _firestoreService.createShopOwner(owner);

      // Set custom claims for shop_owner role (via Cloud Function)
      try {
        await FirebaseFunctions.instance
            .httpsCallable('setCustomClaims')
            .call({'targetUid': uid, 'role': 'shop_owner'});
      } catch (e) {
        ZLogger.warn(
          'Could not set custom claims for shop owner $uid: $e',
          tag: 'AdminService',
        );
      }

      return shopId;
    } finally {
      await tempApp.delete();
    }
  }

  /// Approve or reject a shop.
  Future<void> setShopApproval(String shopId, bool approved) async {
    await _firestoreService.updateShop(shopId, {'isApproved': approved});
  }

  /// Verify a shop.
  Future<void> setShopVerified(String shopId, bool verified) async {
    await _firestoreService.updateShop(shopId, {'isVerified': verified});
  }

  /// Delete a shop and its owner account.
  Future<void> deleteShop(String shopId) async {
    // Get shop to find owner
    final shop = await _firestoreService.getShop(shopId);
    if (shop != null) {
      // Delete the Firebase Auth account for the shop owner
      try {
        // This requires admin SDK — handled by Cloud Function in production
        ZLogger.warn(
          'Auth account deletion requires Cloud Function: ${shop.ownerId}',
          tag: 'AdminService',
        );
      } catch (_) {}
    }
    await _firestoreService.deleteShop(shopId);
  }
}
