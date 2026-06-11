import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../providers/app_providers.dart';

final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAllOrders();
});
