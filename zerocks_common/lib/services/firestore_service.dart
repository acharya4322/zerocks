import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/shop_model.dart';
import '../models/shop_owner_model.dart';
import '../models/print_job_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Users ──────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Update specific fields on a user document.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  /// Stream all users (admin dashboard).
  Stream<List<UserModel>> getAllUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList());
  }

  // ── Shops ──────────────────────────────────────────────

  Future<void> createShop(ShopModel shop) async {
    await _db.collection('shops').doc(shop.id).set(shop.toMap());
  }

  Future<ShopModel?> getShop(String shopId) async {
    final doc = await _db.collection('shops').doc(shopId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ShopModel.fromMap(doc.data()!, doc.id);
  }

  /// Get nearby shops using a simple bounding box query.
  /// For MVP, we filter by latitude range and then check longitude in-memory.
  Stream<List<ShopModel>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) {
    // ~0.009 degrees per km for latitude
    final latDelta = radiusKm * 0.009;
    final lngDelta = radiusKm * 0.009 / 0.7; // rough cos adjustment

    return _db
        .collection('shops')
        .where('latitude', isGreaterThan: latitude - latDelta)
        .where('latitude', isLessThan: latitude + latDelta)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ShopModel.fromMap(doc.data(), doc.id))
          .where((shop) =>
              shop.longitude >= longitude - lngDelta &&
              shop.longitude <= longitude + lngDelta)
          .toList();
    });
  }

  /// Get shop by owner ID (for shop app)
  Future<ShopModel?> getShopByOwner(String ownerId) async {
    final query = await _db
        .collection('shops')
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return ShopModel.fromMap(doc.data(), doc.id);
  }

  /// Stream shop by owner for real-time updates (replaces polling).
  Stream<ShopModel?> streamShopByOwner(String ownerId) {
    return _db
        .collection('shops')
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return ShopModel.fromMap(doc.data(), doc.id);
    });
  }

  /// Toggle shop online/offline status
  Future<void> updateShopOnlineStatus(String shopId, bool isOnline) async {
    await _db.collection('shops').doc(shopId).update({
      'isOnline': isOnline,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update shop FCM token for push notifications.
  Future<void> updateShopFcmToken(String shopId, String token) async {
    await _db.collection('shops').doc(shopId).update({
      'fcmToken': token,
    });
  }

  // ── Print Jobs ─────────────────────────────────────────

  /// Create a new print job
  Future<String> createPrintJob(PrintJobModel job) async {
    final docRef = _db.collection('printJobs').doc(job.id);
    await docRef.set(job.toMap());
    return docRef.id;
  }

  /// Update print job status
  Future<void> updateJobStatus(String jobId, PrintJobStatus status) async {
    final data = <String, dynamic>{
      'status': status.name,
    };

    // Add timestamp for specific status transitions
    switch (status) {
      case PrintJobStatus.inQueue:
        data['acceptedAt'] = FieldValue.serverTimestamp();
        break;
      case PrintJobStatus.printing:
        data['printedAt'] = FieldValue.serverTimestamp();
        break;
      case PrintJobStatus.completed:
      case PrintJobStatus.cancelled:
        data['completedAt'] = FieldValue.serverTimestamp();
        data['fileUrl'] = null; // Clear URL on completion
        break;
      default:
        break;
    }

    // Append to status history
    data['statusHistory'] = FieldValue.arrayUnion([
      {
        'status': status.name,
        'at': Timestamp.now(),
      }
    ]);

    await _db.collection('printJobs').doc(jobId).update(data);
  }

  /// Update job with file URL after upload.
  Future<void> updateJobFileUrl(String jobId, String fileUrl) async {
    await _db.collection('printJobs').doc(jobId).update({
      'fileUrl': fileUrl,
    });
  }

  /// Stream print jobs for a specific user (customer app)
  Stream<List<PrintJobModel>> streamJobsByUser(String userId) {
    return _db
        .collection('printJobs')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final jobs = snapshot.docs
          .map((doc) => PrintJobModel.fromMap(doc.data(), doc.id))
          .toList();
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return jobs;
    });
  }

  /// Stream active print jobs for a shop (shop app)
  Stream<List<PrintJobModel>> streamJobsByShop(String shopId) {
    return _db
        .collection('printJobs')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) {
      final jobs = snapshot.docs
          .map((doc) => PrintJobModel.fromMap(doc.data(), doc.id))
          .toList();
      jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return jobs;
    });
  }

  /// Stream only active jobs for a shop (excludes completed/cancelled).
  Stream<List<PrintJobModel>> streamActiveJobsByShop(String shopId) {
    return _db
        .collection('printJobs')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) {
          final activeStatuses = {'uploaded', 'inQueue', 'printing', 'ready'};
          final jobs = snapshot.docs
              .map((doc) => PrintJobModel.fromMap(doc.data(), doc.id))
              .where((job) => activeStatuses.contains(job.status.name))
              .toList();
          jobs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return jobs;
        });
  }

  /// Stream a single print job (for real-time tracking)
  Stream<PrintJobModel?> streamJob(String jobId) {
    return _db
        .collection('printJobs')
        .doc(jobId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return PrintJobModel.fromMap(doc.data()!, doc.id);
    });
  }

  // ── Admin Methods ─────────────────────────────────────

  /// Stream ALL shops (for admin dashboard)
  Stream<List<ShopModel>> getAllShops() {
    return _db
        .collection('shops')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShopModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream ALL print jobs across all shops (for admin dashboard)
  Stream<List<PrintJobModel>> getAllJobs() {
    return _db
        .collection('printJobs')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PrintJobModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Update shop details (for admin)
  Future<void> updateShop(String shopId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('shops').doc(shopId).update(data);
  }

  /// Delete a shop document (for admin)
  Future<void> deleteShop(String shopId) async {
    await _db.collection('shops').doc(shopId).delete();
  }

  // ── Shop Owners ────────────────────────────────────────

  /// Create a shop owner record.
  Future<void> createShopOwner(ShopOwnerModel owner) async {
    await _db.collection('shopOwners').doc(owner.uid).set(owner.toMap());
  }

  /// Get a shop owner by UID.
  Future<ShopOwnerModel?> getShopOwner(String uid) async {
    final doc = await _db.collection('shopOwners').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return ShopOwnerModel.fromMap(doc.data()!);
  }

  // ── Platform Config ───────────────────────────────────

  /// Get platform stats (admin dashboard).
  Stream<Map<String, dynamic>?> streamPlatformStats() {
    return _db
        .collection('platform')
        .doc('stats')
        .snapshots()
        .map((doc) => doc.data());
  }

  /// Get platform config (feature flags, limits).
  Future<Map<String, dynamic>?> getPlatformConfig() async {
    final doc = await _db.collection('platform').doc('config').get();
    return doc.data();
  }
}
