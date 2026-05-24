import '../models/user_model.dart';
import '../services/firestore_service.dart';

/// Repository for user profile management.
class UserRepository {
  final FirestoreService _firestore;

  UserRepository(this._firestore);

  /// Get a user profile.
  Future<UserModel?> getUser(String uid) {
    return _firestore.getUser(uid);
  }

  /// Create a new user profile.
  Future<void> createUser(UserModel user) {
    return _firestore.createUser(user);
  }

  /// Update user's FCM token for push notifications.
  Future<void> updateFcmToken(String uid, String token) {
    return _firestore.updateUser(uid, {'fcmToken': token});
  }

  /// Update last login timestamp.
  Future<void> updateLastLogin(String uid) {
    return _firestore.updateUser(uid, {
      'lastLoginAt': DateTime.now(),
    });
  }

  /// Update display name.
  Future<void> updateDisplayName(String uid, String name) {
    return _firestore.updateUser(uid, {'displayName': name});
  }
}
