import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../core/constants/app_constants.dart';
import '../../shops/providers/shops_provider.dart';
import '../providers/jobs_provider.dart';
import '../widgets/status_stepper.dart';

class JobTrackingScreen extends ConsumerWidget {
  final String jobId;

  const JobTrackingScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobStreamProvider(jobId));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Tracking'),
      ),
      body: jobAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load job details',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(jobStreamProvider(jobId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (job) {
          if (job == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Job not found',
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final statusColor = AppConstants.statusColor(job.status);
          final shopAsync = ref.watch(shopDetailProvider(job.shopId));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Header Card
                Card(
                  elevation: 0,
                  color: statusColor.withValues(alpha: 0.08),
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor.withValues(alpha: 0.15),
                          ),
                          child: Icon(
                            AppConstants.statusIcon(job.status),
                            size: 32,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          job.status.label,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _statusMessage(job.status),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Status Stepper
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: StatusStepper(currentStatus: job.status),
                  ),
                ),
                const SizedBox(height: 20),

                // Details Card
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job Details',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          icon: Icons.description_outlined,
                          label: 'File Name',
                          value: job.fileName,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        ),
                        _buildDivider(colorScheme),
                        _InfoRow(
                          icon: Icons.file_copy_outlined,
                          label: 'File Type',
                          value: job.fileType.toUpperCase(),
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        ),
                        _buildDivider(colorScheme),
                        _InfoRow(
                          icon: Icons.content_copy,
                          label: 'Copies',
                          value: '${job.copies}',
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        ),
                        _buildDivider(colorScheme),
                        // Shop Info
                        shopAsync.when(
                          loading: () => _InfoRow(
                            icon: Icons.storefront_outlined,
                            label: 'Shop',
                            value: 'Loading...',
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          error: (_, __) => _InfoRow(
                            icon: Icons.storefront_outlined,
                            label: 'Shop',
                            value: job.shopId,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          data: (shop) => _InfoRow(
                            icon: Icons.storefront_outlined,
                            label: 'Shop',
                            value: shop?.name ?? job.shopId,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                        ),
                        _buildDivider(colorScheme),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Created',
                          value: DateFormat('dd MMM yyyy, hh:mm a')
                              .format(job.createdAt),
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        ),
                        if (job.completedAt != null) ...[
                          _buildDivider(colorScheme),
                          _InfoRow(
                            icon: Icons.check_circle_outline,
                            label: 'Completed',
                            value: DateFormat('dd MMM yyyy, hh:mm a')
                                .format(job.completedAt!),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Live indicator for active jobs
                if (job.isActive) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            const Color(0xFF4CAF50).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Live tracking — Updates automatically',
                          style: textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF4CAF50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Divider(
      height: 20,
      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }

  String _statusMessage(PrintJobStatus status) {
    switch (status) {
      case PrintJobStatus.uploaded:
        return 'Your document has been uploaded and is\nwaiting to be queued.';
      case PrintJobStatus.inQueue:
        return 'Your document is in the print queue.\nPlease wait for your turn.';
      case PrintJobStatus.printing:
        return 'Your document is currently being printed.';
      case PrintJobStatus.ready:
        return 'Your print is ready!\nPlease collect it from the shop.';
      case PrintJobStatus.completed:
        return 'This print job has been completed.\nThank you for using Zerocks!';
      case PrintJobStatus.cancelled:
        return 'This print job was cancelled.';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
