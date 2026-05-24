import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';
import '../../print_queue/providers/queue_provider.dart';
import '../widgets/stats_card.dart';
import '../widgets/online_toggle.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return shopAsync.when(
      data: (shop) {
        if (shop == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 64,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No shop found for this account',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please contact admin to link your shop',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }

        return _DashboardContent(shop: shop);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Error: $error', style: textTheme.bodyLarge),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(shopProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final ShopModel shop;

  const _DashboardContent({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(shopJobsProvider(shop.id));
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop.name,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Online toggle
          const OnlineToggle(),
          const SizedBox(height: 24),

          // Stats row
          jobsAsync.when(
            data: (jobs) {
              final activeJobs =
                  jobs.where((j) => j.isActive).toList();
              final completedToday = jobs.where((j) {
                if (j.status != PrintJobStatus.completed) return false;
                final now = DateTime.now();
                final completedAt = j.completedAt ?? j.createdAt;
                return completedAt.year == now.year &&
                    completedAt.month == now.month &&
                    completedAt.day == now.day;
              }).toList();

              return Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      icon: Icons.pending_actions_outlined,
                      title: 'Active Jobs',
                      count: '${activeJobs.length}',
                      accentColor: AppTheme.inQueueColor,
                    ),
                  ),
                  Expanded(
                    child: StatsCard(
                      icon: Icons.check_circle_outline,
                      title: 'Completed Today',
                      count: '${completedToday.length}',
                      accentColor: AppTheme.readyColor,
                    ),
                  ),
                  Expanded(
                    child: StatsCard(
                      icon: Icons.list_alt_outlined,
                      title: 'Total Queue',
                      count: '${jobs.length}',
                      accentColor: AppTheme.uploadedColor,
                    ),
                  ),
                ],
              );
            },
            loading: () => const Row(
              children: [
                Expanded(child: _LoadingCard()),
                Expanded(child: _LoadingCard()),
                Expanded(child: _LoadingCard()),
              ],
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 28),

          // Recent jobs section
          Text(
            'Recent Jobs',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 14),

          // Recent jobs list
          Expanded(
            child: jobsAsync.when(
              data: (jobs) {
                if (jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 56,
                          color: colorScheme.onSurface.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No print jobs yet',
                          style: textTheme.titleMedium?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Jobs will appear here when customers submit them',
                          style: textTheme.bodySmall?.copyWith(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final recentJobs = jobs.take(5).toList();
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: recentJobs.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    itemBuilder: (context, index) {
                      final job = recentJobs[index];
                      final statusColor =
                          AppConstants.statusColor(job.status);
                      final timeAgo = _formatTime(job.createdAt);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
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
                        title: Text(
                          job.fileName,
                          style: textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${job.copies} ${job.copies == 1 ? 'copy' : 'copies'} • $timeAgo',
                          style: textTheme.bodySmall,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
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
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error loading jobs: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(time);
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
    );
  }
}
