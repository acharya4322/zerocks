import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:zerocks_common/zerocks_common.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';
import '../providers/queue_provider.dart';
import '../widgets/job_list_tile.dart';
import '../widgets/file_preview_dialog.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return shopAsync.when(
      data: (shop) {
        if (shop == null) {
          return Center(
            child: Text(
              'No shop found',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          );
        }
        return _QueueContent(shop: shop);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _QueueContent extends ConsumerWidget {
  final ShopModel shop;

  const _QueueContent({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredJobs = ref.watch(filteredJobsProvider(shop.id));
    final currentFilter = ref.watch(queueFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text('Print Queue', style: textTheme.headlineLarge),
              const SizedBox(width: 12),
              // Platform badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kIsWeb
                      ? Colors.blue.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      kIsWeb ? Icons.language : Icons.desktop_windows,
                      size: 14,
                      color: kIsWeb ? Colors.blue : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      kIsWeb ? 'Web' : 'Desktop',
                      style: textTheme.labelSmall?.copyWith(
                        color: kIsWeb ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Refresh indicator
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                tooltip: 'Refresh',
                onPressed: () => ref.invalidate(shopJobsProvider(shop.id)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filter tabs
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: QueueFilter.values.map((filter) {
                final isSelected = currentFilter == filter;
                final label = switch (filter) {
                  QueueFilter.all => 'All Jobs',
                  QueueFilter.active => 'Active',
                  QueueFilter.completed => 'Completed',
                  QueueFilter.cancelled => 'Cancelled',
                };

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          ref.read(queueFilterProvider.notifier).setFilter(filter),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          label,
                          style: textTheme.labelLarge?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
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
                const SizedBox(width: 58), // icon space
                Expanded(
                  flex: 3,
                  child: Text(
                    'FILE',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'COPIES',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Text(
                    'STATUS',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    'TIME',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: Text(
                    'ACTIONS',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Job list
          Expanded(
            child: filteredJobs.when(
              data: (jobs) {
                if (jobs.isEmpty) {
                  return _EmptyState(filter: currentFilter);
                }

                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return JobListTile(
                        job: job,
                        onPreview: () =>
                            FilePreviewDialog.show(context, job),
                        onPrint: () => _printJob(context, job),
                        onAdvanceStatus: () =>
                            _advanceStatus(context, ref, job),
                        onMarkComplete: () =>
                            _markComplete(context, ref, job),
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Error loading jobs: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(shopJobsProvider(shop.id)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printJob(BuildContext context, PrintJobModel job) async {
    final fileUrl = job.fileUrl;
    if (fileUrl == null || fileUrl.isEmpty) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing file for printing...'),
          duration: Duration(seconds: 2),
        ),
      );

      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode == 200) {
        await Printing.layoutPdf(
          onLayout: (_) async => response.bodyBytes,
          name: job.fileName,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download file for printing')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print error: $e')),
        );
      }
    }
  }

  Future<void> _advanceStatus(
      BuildContext context, WidgetRef ref, PrintJobModel job) async {
    final nextStatus = AppConstants.nextStatus(job.status);
    if (nextStatus == null) return;

    if (nextStatus == PrintJobStatus.completed) {
      _markComplete(context, ref, job);
      return;
    }

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateJobStatus(job.id, nextStatus);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _markComplete(
      BuildContext context, WidgetRef ref, PrintJobModel job) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Job'),
        content: Text(
          'Mark "${job.fileName}" as completed?\n\n'
          'This will also delete the uploaded file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // First delete the file from storage
      if (job.fileUrl != null && job.fileUrl!.isNotEmpty) {
        final storageService = ref.read(storageServiceProvider);
        await storageService.deleteFile(job.fileUrl!);
      }

      // Then update the job status (this also sets fileUrl to null)
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.updateJobStatus(
          job.id, PrintJobStatus.completed);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${job.fileName} marked as completed'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete job: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  final QueueFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (icon, title, subtitle) = switch (filter) {
      QueueFilter.all => (
          Icons.inbox_outlined,
          'No print jobs',
          'Jobs will appear here when customers submit them',
        ),
      QueueFilter.active => (
          Icons.check_circle_outline,
          'No active jobs',
          'All jobs have been completed',
        ),
      QueueFilter.completed => (
          Icons.history_outlined,
          'No completed jobs',
          'Completed jobs will appear here',
        ),
      QueueFilter.cancelled => (
          Icons.cancel_outlined,
          'No cancelled jobs',
          'Cancelled jobs will appear here',
        ),
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
