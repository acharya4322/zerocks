import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_provider.dart';
import '../../upload/providers/upload_provider.dart';

class CartScreen extends ConsumerWidget {
  final String shopId;

  const CartScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartNotifierProvider);
    final uploadState = ref.watch(uploadNotifierProvider);
    final billing = ref.watch(liveBillingProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasPrintJob = uploadState.fileName != null;
    final hasServices = cart.services.isNotEmpty;
    final hasStationery = cart.stationeryItems.isNotEmpty;

    if (!hasPrintJob && !hasServices && !hasStationery) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart Review')),
        body: const Center(child: Text('Your cart is empty.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Review & Pay')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasPrintJob) ...[
              Text(
                'Print Document',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              uploadState.fileName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildRow(
                        'Pages',
                        '${uploadState.analysis?.totalPages ?? '?'}',
                      ),
                      _buildRow('Copies', '${uploadState.copies}'),
                      _buildRow(
                        'Color Mode',
                        uploadState.isColor ? 'Color' : 'Black & White',
                      ),
                      _buildRow(
                        'Sides',
                        uploadState.isDuplex ? 'Double Sided' : 'Single Sided',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (hasServices) ...[
              Text(
                'Additional Services',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: cart.services
                      .map(
                        (item) => ListTile(
                          title: Text(item.name),
                          trailing: Text('₹${item.total.toStringAsFixed(0)}'),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (hasStationery) ...[
              Text(
                'Stationery Items',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: cart.stationeryItems
                      .map(
                        (item) => ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            'Qty: ${item.quantity} x ₹${item.unitPrice.toStringAsFixed(0)}',
                          ),
                          trailing: Text('₹${item.total.toStringAsFixed(0)}'),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Bill Summary
            Text(
              'Bill Summary',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.secondaryContainer),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (billing.printCost > 0)
                      _buildRow(
                        'Print Charges',
                        '₹${billing.printCost.toStringAsFixed(2)}',
                      ),
                    if (billing.serviceCharges > 0)
                      _buildRow(
                        'Service Charges',
                        '₹${billing.serviceCharges.toStringAsFixed(2)}',
                      ),
                    if (billing.stationeryCost > 0)
                      _buildRow(
                        'Stationery Items',
                        '₹${billing.stationeryCost.toStringAsFixed(2)}',
                      ),

                    const Divider(height: 24),

                    _buildRow(
                      'Total Amount',
                      '₹${billing.totalAmount.toStringAsFixed(2)}',
                      isTotal: true,
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            Consumer(
              builder: (context, ref, child) {
                final checkoutState = ref.watch(checkoutNotifierProvider);

                ref.listen<CheckoutState>(checkoutNotifierProvider, (
                  prev,
                  next,
                ) {
                  if (next.status == CheckoutStatus.success &&
                      next.createdOrderId != null) {
                    context.go(
                      '/order/payment-status?success=true&orderId=${next.createdOrderId}',
                    );
                  } else if (next.status == CheckoutStatus.error &&
                      next.errorMessage != null) {
                    context.go(
                      '/order/payment-status?success=false&error=${Uri.encodeComponent(next.errorMessage!)}',
                    );
                  }
                });

                final isProcessing =
                    checkoutState.status == CheckoutStatus.processing ||
                    checkoutState.status == CheckoutStatus.initializing;

                return FilledButton(
                  onPressed: isProcessing
                      ? null
                      : () {
                          ref
                              .read(checkoutNotifierProvider.notifier)
                              .startCheckout();
                        },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Proceed to Pay ₹${billing.totalAmount.toStringAsFixed(2)}',
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isTotal = false,
    TextTheme? textTheme,
    ColorScheme? colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? textTheme?.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                : null,
          ),
          Text(
            value,
            style: isTotal
                ? textTheme?.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme?.primary,
                  )
                : const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
