import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../providers/app_providers.dart';

// Stream all shops
final allShopsProvider = StreamProvider<List<ShopModel>>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getAllShops();
});
