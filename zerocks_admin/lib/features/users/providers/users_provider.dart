import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../providers/app_providers.dart';

/// Streams all users for the admin dashboard.
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getAllUsers();
});
