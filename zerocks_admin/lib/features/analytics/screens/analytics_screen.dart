import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../shops/providers/shops_provider.dart';
import '../../jobs/providers/jobs_provider.dart';
import '../../jobs/providers/orders_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(allShopsProvider);
    final jobsAsync = ref.watch(allJobsProvider);
    final ordersAsync = ref.watch(allOrdersProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),

            // Stats cards
            Row(
              children: [
                _StatCard(
                  icon: Icons.store_rounded,
                  label: 'Total Shops',
                  value: shopsAsync.when(
                    data: (shops) => shops.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '—',
                  ),
                  color: Colors.blue,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.currency_rupee,
                  label: 'Total Revenue',
                  value: ordersAsync.when(
                    data: (orders) {
                      final total = orders.fold(
                        0.0,
                        (sum, order) => sum + order.totalAmount,
                      );
                      return '₹${total.toStringAsFixed(0)}';
                    },
                    loading: () => '...',
                    error: (_, __) => '—',
                  ),
                  color: Colors.green,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Total Orders',
                  value: ordersAsync.when(
                    data: (orders) => orders.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '—',
                  ),
                  color: Colors.orange,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.pending_actions_rounded,
                  label: 'Active Jobs',
                  value: jobsAsync.when(
                    data: (jobs) =>
                        jobs.where((j) => j.isActive).length.toString(),
                    loading: () => '...',
                    error: (_, __) => '—',
                  ),
                  color: Colors.purple,
                  colorScheme: colorScheme,
                ),
              ],
            ),
            const SizedBox(height: 32),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revenue Breakdown',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ordersAsync.when(
                            data: (orders) => _RevenueBreakdown(orders: orders),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Center(child: Text('Error: $e')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job Status Distribution',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: jobsAsync.when(
                            data: (jobs) => _StatusDistribution(jobs: jobs),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Center(child: Text('Error: $e')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ColorScheme colorScheme;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueBreakdown extends StatelessWidget {
  final List<OrderModel> orders;

  const _RevenueBreakdown({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('No revenue data yet'));
    }

    double printTotal = 0;
    double servicesTotal = 0;
    double stationeryTotal = 0;

    for (final order in orders) {
      for (final item in order.items) {
        if (item.type == OrderItemType.print) {
          printTotal += (item.price * item.quantity);
        } else if (item.type == OrderItemType.service) {
          servicesTotal += (item.price * item.quantity);
        } else if (item.type == OrderItemType.product) {
          stationeryTotal += (item.price * item.quantity);
        }
      }
    }

    final total = printTotal + servicesTotal + stationeryTotal;
    if (total == 0) return const Center(child: Text('No revenue data yet'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    if (printTotal > 0)
                      PieChartSectionData(
                        color: Colors.blue,
                        value: printTotal,
                        title: '${((printTotal / total) * 100).toStringAsFixed(0)}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    if (servicesTotal > 0)
                      PieChartSectionData(
                        color: Colors.purple,
                        value: servicesTotal,
                        title: '${((servicesTotal / total) * 100).toStringAsFixed(0)}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    if (stationeryTotal > 0)
                      PieChartSectionData(
                        color: Colors.orange,
                        value: stationeryTotal,
                        title: '${((stationeryTotal / total) * 100).toStringAsFixed(0)}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(color: Colors.blue, text: 'Prints (₹${printTotal.toStringAsFixed(0)})'),
                const SizedBox(height: 8),
                _LegendItem(color: Colors.purple, text: 'Services (₹${servicesTotal.toStringAsFixed(0)})'),
                const SizedBox(height: 8),
                _LegendItem(color: Colors.orange, text: 'Stationery (₹${stationeryTotal.toStringAsFixed(0)})'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDistribution extends StatelessWidget {
  final List<PrintJobModel> jobs;

  const _StatusDistribution({required this.jobs});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return const Center(child: Text('No job data yet'));
    }

    final statusCounts = <String, int>{};
    for (final job in jobs) {
      final status = job.status.label;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    final statusColors = {
      'Uploaded': Colors.blue,
      'In Queue': Colors.orange,
      'Printing': Colors.amber,
      'Ready': Colors.teal,
      'Completed': Colors.green,
      'Cancelled': Colors.red,
    };

    final maxCount = statusCounts.values.isEmpty ? 1 : statusCounts.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxCount.toDouble() + 1,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= statusCounts.length) return const SizedBox.shrink();
                    final key = statusCounts.keys.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        key,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: statusCounts.entries.map((entry) {
              final index = statusCounts.keys.toList().indexOf(entry.key);
              final color = statusColors[entry.key] ?? Colors.grey;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.toDouble(),
                    color: color,
                    width: 22,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
