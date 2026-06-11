import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class JobListTile extends StatelessWidget {
  final PrintJobModel job;
  final VoidCallback onPreview;
  final VoidCallback? onPrint;
  final VoidCallback onAdvanceStatus;
  final VoidCallback onMarkComplete;
  final VoidCallback? onViewOrder;

  const JobListTile({
    super.key,
    required this.job,
    required this.onPreview,
    this.onPrint,
    required this.onAdvanceStatus,
    required this.onMarkComplete,
    this.onViewOrder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = AppConstants.statusColor(job.status);
    final isCompleted = job.status == PrintJobStatus.completed;
    final nextStatusValue = AppConstants.nextStatus(job.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          // File type icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
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
          const SizedBox(width: 16),

          // File name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.fileName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  job.fileType.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),

          // Copies
          SizedBox(
            width: 80,
            child: Text(
              '${job.copies} ${job.copies == 1 ? 'copy' : 'copies'}',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),

          // Status badge
          SizedBox(
            width: 110,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppConstants.statusIcon(job.status),
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      job.status.label,
                      style: textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Time
          SizedBox(
            width: 120,
            child: Text(
              _formatTimestamp(job.createdAt),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Actions
          SizedBox(
            width: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Preview button
                if (job.fileUrl != null && job.fileUrl!.isNotEmpty)
                  _ActionButton(
                    icon: Icons.visibility_outlined,
                    tooltip: 'Preview File',
                    onPressed: onPreview,
                    color: colorScheme.primary,
                  ),

                if (job.orderId != null && onViewOrder != null)
                  const SizedBox(width: 6),

                if (job.orderId != null && onViewOrder != null)
                  _ActionButton(
                    icon: Icons.receipt_long_outlined,
                    tooltip: 'View Order Details',
                    onPressed: onViewOrder!,
                    color: Colors.blueAccent,
                  ),

                if (job.fileUrl != null && job.fileUrl!.isNotEmpty)
                  const SizedBox(width: 6),

                // Print button
                if (onPrint != null && job.fileUrl != null && job.fileUrl!.isNotEmpty && !isCompleted)
                  _ActionButton(
                    icon: Icons.print_outlined,
                    tooltip: 'Print',
                    onPressed: onPrint!,
                    color: AppTheme.printingColor,
                  ),

                if (onPrint != null && job.fileUrl != null && job.fileUrl!.isNotEmpty && !isCompleted)
                  const SizedBox(width: 6),

                // Advance status button
                if (!isCompleted && nextStatusValue != null)
                  _ActionButton(
                    icon: Icons.skip_next_outlined,
                    tooltip:
                        'Move to ${nextStatusValue.label}',
                    onPressed: onAdvanceStatus,
                    color: AppConstants.statusColor(nextStatusValue),
                  ),

                if (!isCompleted && nextStatusValue != null)
                  const SizedBox(width: 6),

                // Mark complete button
                if (!isCompleted)
                  _ActionButton(
                    icon: Icons.done_all,
                    tooltip: 'Mark Complete',
                    onPressed: onMarkComplete,
                    color: AppConstants.statusColor(PrintJobStatus.completed),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 2) return 'Yesterday';
    return DateFormat('MMM d, h:mm a').format(time);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          hoverColor: color.withValues(alpha: 0.1),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
