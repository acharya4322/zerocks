import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../providers/cart_provider.dart';
import '../../../providers/app_providers.dart';

// We'll create a simple provider to fetch shop services.
// Ideally this should be in a separate services_provider.dart, but we'll inline it for simplicity.
final shopServicesProvider = StreamProvider.family<List<ServiceModel>, String>((
  ref,
  shopId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamServices(shopId);
});

class ServicesScreen extends ConsumerWidget {
  final String shopId;

  const ServicesScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(shopServicesProvider(shopId));
    final cart = ref.watch(cartNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Ensure cart shopId is set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartNotifierProvider.notifier).setShopId(shopId);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Additional Services'),
        actions: [
          TextButton(
            onPressed: () => context.push('/order/stationery/$shopId'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (services) {
          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No additional services available at this shop.'),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.push('/order/stationery/$shopId'),
                    child: const Text('Continue to Stationery'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length + 1,
            itemBuilder: (context, index) {
              if (index == services.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: FilledButton(
                    onPressed: () => context.push('/order/stationery/$shopId'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('Continue'),
                  ),
                );
              }

              final service = services[index];
              if (!service.isAvailable) return const SizedBox.shrink();

              final isInCart = cart.services.any((s) => s.id == service.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isInCart ? colorScheme.primary : Colors.transparent,
                    width: isInCart ? 2 : 0,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    service.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('₹${service.price.toStringAsFixed(0)}'),
                  trailing: isInCart
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.add_circle_outline),
                  onTap: () {
                    ref
                        .read(cartNotifierProvider.notifier)
                        .toggleService(service);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
