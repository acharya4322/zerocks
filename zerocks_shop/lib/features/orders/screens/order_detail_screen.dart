import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../providers/orders_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) return const Center(child: Text('Order not found'));

          final printJobs = order.items.where((i) => i.type == OrderItemType.print).toList();
          final services = order.items.where((i) => i.type == OrderItemType.service).toList();
          final stationeryItems = order.items.where((i) => i.type == OrderItemType.product).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, order),
                const SizedBox(height: 24),
                if (printJobs.isNotEmpty) ...[
                  Text('Print Jobs', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...printJobs.map((job) => _buildPrintJobCard(context, job)),
                  const SizedBox(height: 24),
                ],
                if (services.isNotEmpty) ...[
                  Text('Additional Services', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildItemsCard(context, services),
                  const SizedBox(height: 24),
                ],
                if (stationeryItems.isNotEmpty) ...[
                  Text('Stationery Items', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildItemsCard(context, stationeryItems),
                  const SizedBox(height: 24),
                ],
                Text('Billing', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildBillCard(context, order.totalAmount),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, OrderModel order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.id.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Chip(
                  label: Text(order.status.label),
                  backgroundColor: _getStatusColor(order.status).withValues(alpha: 0.2),
                  side: BorderSide.none,
                ),
              ],
            ),
            const Divider(),
            _buildRow('Date', DateFormat.yMMMd().add_jm().format(order.createdAt)),
            _buildRow('Payment', order.paymentId != null ? 'Online (Paid)' : 'Pending'),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintJobCard(BuildContext context, OrderItemModel job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.picture_as_pdf),
                const SizedBox(width: 8),
                Expanded(child: Text(job.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
            const SizedBox(height: 16),
            _buildRow('Pages', '${job.pageCount ?? '?'}'),
            _buildRow('Copies', '${job.quantity}'),
            if (job.printOptions != null) ...[
              _buildRow('Color Mode', job.printOptions!['colorMode'] == 'color' ? 'Color' : 'B&W'),
              _buildRow('Sides', job.printOptions!['sides'] == 'double' ? 'Double Sided' : 'Single Sided'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(BuildContext context, List<OrderItemModel> items) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(item.name),
            subtitle: Text('${item.quantity} x ₹${item.price.toStringAsFixed(2)}'),
            trailing: Text('₹${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          );
        },
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, double totalAmount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRow(
              'Total', 
              '₹${totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isTotal ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text(value, style: isTotal ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16) : null),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.paid:
        return Colors.green;
      case OrderStatus.inQueue:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.purple;
      case OrderStatus.completed:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
