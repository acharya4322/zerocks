import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/jobs_provider.dart';

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredJobsProvider);
    final currentFilter = ref.watch(jobFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('All Print Jobs', style: textTheme.headlineLarge),
          const SizedBox(height: 20),

          // Filters
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: JobFilter.values.map((filter) {
                final isSelected = currentFilter == filter;
                final label = switch (filter) {
                  JobFilter.all => 'All Jobs',
                  JobFilter.active => 'Active',
                  JobFilter.completed => 'Completed',
                };
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => ref.read(jobFilterProvider.notifier).setFilter(filter),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          style: textTheme.labelLarge?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 50),
                Expanded(
                  flex: 3,
                  child: Text('FILE', style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 1,
                  )),
                ),
                SizedBox(
                  width: 120,
                  child: Text('SHOP ID', style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 1,
                  )),
                ),
                SizedBox(
                  width: 80,
                  child: Text('COPIES', style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 1,
                  ), textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 110,
                  child: Text('STATUS', style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 1,
                  ), textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 140,
                  child: Text('TIME', style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 1,
                  ), textAlign: TextAlign.right),
                ),
              ],
            ),
          ),

          // Jobs list
          Expanded(
            child: filteredAsync.when(
              data: (jobs) {
                if (jobs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.2)),
                        const SizedBox(height: 18),
                        Text('No jobs found', style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        )),
                      ],
                    ),
                  );
                }
                return Card(
                  margin: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: ListView.separated(
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.08),
                    ),
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      final statusColor = AppTheme.statusColor(job.status.name);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                job.fileType == 'pdf'
                                    ? Icons.picture_as_pdf_outlined
                                    : Icons.image_outlined,
                                color: statusColor, size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(job.fileName, style: textTheme.titleSmall,
                                      overflow: TextOverflow.ellipsis),
                                  Text(job.fileType.toUpperCase(), style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                                  )),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                job.shopId.length > 8 ? '${job.shopId.substring(0, 8)}...' : job.shopId,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text('${job.copies}', style: textTheme.bodyMedium,
                                  textAlign: TextAlign.center),
                            ),
                            SizedBox(
                              width: 110,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(job.status.label,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: statusColor, fontWeight: FontWeight.w600,
                                      )),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: Text(
                                DateFormat('MMM d, h:mm a').format(job.createdAt),
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
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
