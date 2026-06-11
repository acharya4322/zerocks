import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentStatusScreen extends StatelessWidget {
  final bool isSuccess;
  final String? orderId;
  final String? errorMessage;

  const PaymentStatusScreen({
    super.key,
    required this.isSuccess,
    this.orderId,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: isSuccess ? Colors.green : colorScheme.error,
                size: 96,
              ),
              const SizedBox(height: 24),
              Text(
                isSuccess ? 'Payment Successful!' : 'Payment Failed',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? Colors.green : colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (isSuccess && orderId != null) ...[
                Text(
                  'Your order has been placed successfully.',
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Order ID: $orderId',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else if (!isSuccess && errorMessage != null) ...[
                Text(
                  errorMessage!,
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please try again or contact support if the issue persists.',
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 48),
              FilledButton(
                onPressed: () {
                  context.go('/home'); // Always navigate back to home
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
