import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../shops/providers/shops_provider.dart';
import '../../jobs/providers/jobs_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(allShopsProvider);
    final jobsAsync = ref.watch(allJobsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard', style: textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => context.go('/shops/create'),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Create New Shop'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Stats cards
          shopsAsync.when(
            data: (shops) {
              final onlineShops = shops.where((s) => s.isOnline).length;
              return jobsAsync.when(
                data: (jobs) {
                  final activeJobs = jobs.where((j) => j.isActive).length;
                  final today = DateTime.now();
                  final completedToday = jobs.where((j) =>
                      !j.isActive &&
                      j.completedAt != null &&
                      j.completedAt!.day == today.day &&
                      j.completedAt!.month == today.month &&
                      j.completedAt!.year == today.year).length;

                  return Row(
                    children: [
                      _StatCard(
                        icon: Icons.store,
                        title: 'Total Shops',
                        value: '${shops.length}',
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        icon: Icons.wifi,
                        title: 'Online Shops',
                        value: '$onlineShops',
                        color: AppTheme.onlineColor,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        icon: Icons.print,
                        title: 'Active Jobs',
                        value: '$activeJobs',
                        color: AppTheme.inQueueColor,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        icon: Icons.check_circle,
                        title: 'Completed Today',
                        value: '$completedToday',
                        color: AppTheme.readyColor,
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
            loading: () => const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 28),

          // Recent jobs
          Text('Recent Activity', style: textTheme.titleLarge),
          const SizedBox(height: 14),
          Expanded(
            child: jobsAsync.when(
              data: (jobs) {
                if (jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 56,
                            color: colorScheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 14),
                        Text('No jobs yet',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.4),
                            )),
                      ],
                    ),
                  );
                }
                final recentJobs = jobs.take(10).toList();
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListView.separated(
                    itemCount: recentJobs.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (context, index) {
                      final job = recentJobs[index];
                      final statusColor = AppTheme.statusColor(job.status.name);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            job.fileType == 'pdf'
                                ? Icons.picture_as_pdf_outlined
                                : Icons.image_outlined,
                            color: statusColor,
                            size: 20,
                          ),
                        ),
                        title: Text(job.fileName,
                            style: textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          'Shop: ${job.shopId.substring(0, 8)}... • ${job.copies} copies',
                          style: textTheme.bodySmall,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            job.status.label,
                            style: textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    title,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
