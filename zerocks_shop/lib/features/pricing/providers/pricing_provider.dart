import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../providers/app_providers.dart';

final pricingConfigProvider = FutureProvider<PricingModel?>((ref) async {
  final shop = await ref.watch(shopProvider.future);
  return shop?.pricing;
});

class PricingNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> updatePricing(PricingModel newPricing) async {
    state = const AsyncLoading();
    try {
      final shop = await ref.read(shopProvider.future);
      if (shop == null) throw Exception('Shop not found');

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateShop(shop.id, {
        'pricing': newPricing.toMap(),
      });
      
      // Invalidate shopProvider so that the changes reflect
      ref.invalidate(shopProvider);
      ref.invalidate(shopStreamProvider);
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final pricingNotifierProvider = AsyncNotifierProvider<PricingNotifier, void>(PricingNotifier.new);

// Services Provider
final shopServicesProvider = StreamProvider<List<ServiceModel>>((ref) {
  final shopAsync = ref.watch(shopProvider);
  final shop = shopAsync.value;
  if (shop == null) return Stream.value([]);

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamServices(shop.id);
});

class ServicesNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addService(ServiceModel service) async {
    state = const AsyncLoading();
    try {
      final shop = ref.read(shopProvider).value;
      if (shop == null) throw Exception('No shop found');
      
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createService(shop.id, service);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateService(String serviceId, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      final shop = ref.read(shopProvider).value;
      if (shop == null) throw Exception('No shop found');
      
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateService(shop.id, serviceId, data);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteService(String serviceId) async {
    state = const AsyncLoading();
    try {
      final shop = ref.read(shopProvider).value;
      if (shop == null) throw Exception('No shop found');
      
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.deleteService(shop.id, serviceId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final servicesNotifierProvider = AsyncNotifierProvider<ServicesNotifier, void>(ServicesNotifier.new);
