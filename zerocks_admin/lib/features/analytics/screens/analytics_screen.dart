import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../shops/providers/shops_provider.dart';
import '../../jobs/providers/jobs_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(allShopsProvider);
    final jobsAsync = ref.watch(allJobsProvider);
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
                  icon: Icons.store_outlined,
                  label: 'Online Now',
                  value: shopsAsync.when(
                    data: (shops) =>
                        shops.where((s) => s.isOnline).length.toString(),
                    loading: () => '...',
                    error: (_, __) => '—',
                  ),
                  color: Colors.green,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.print_rounded,
                  label: 'Total Jobs',
                  value: jobsAsync.when(
                    data: (jobs) => jobs.length.toString(),
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

            // Job status breakdown
            Text(
              'Job Status Breakdown',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: jobsAsync.when(
                data: (jobs) => _StatusBreakdown(jobs: jobs),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
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

class _StatusBreakdown extends StatelessWidget {
  final List<PrintJobModel> jobs;

  const _StatusBreakdown({required this.jobs});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusCounts = <String, int>{};

    for (final job in jobs) {
      final status = job.status.label;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    if (statusCounts.isEmpty) {
      return const Center(child: Text('No job data yet'));
    }

    final statusColors = {
      'Uploaded': Colors.blue,
      'In Queue': Colors.orange,
      'Printing': Colors.amber,
      'Ready': Colors.teal,
      'Completed': Colors.green,
      'Cancelled': Colors.red,
    };

    return ListView(
      children: statusCounts.entries.map((entry) {
        final percent = jobs.isEmpty ? 0.0 : entry.value / jobs.length;
        final color = statusColors[entry.key] ?? Colors.grey;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 100,
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor:
                          colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      color: color,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${entry.value} (${(percent * 100).toStringAsFixed(0)}%)',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
