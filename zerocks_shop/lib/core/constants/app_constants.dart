import 'package:flutter/material.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../theme/app_theme.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Zerocks Shop';
  static const String appTagline = 'Print Shop Management';

  // Window constraints
  static const double minWindowWidth = 1024;
  static const double minWindowHeight = 680;

  // Sidebar
  static const double sidebarWidth = 80;
  static const double sidebarExpandedWidth = 220;

  // Padding
  static const double pagePadding = 28;
  static const double cardPadding = 20;

  // Status labels
  static const Map<PrintJobStatus, String> statusLabels = {
    PrintJobStatus.uploaded: 'Uploaded',
    PrintJobStatus.inQueue: 'In Queue',
    PrintJobStatus.printing: 'Printing',
    PrintJobStatus.ready: 'Ready',
    PrintJobStatus.completed: 'Completed',
    PrintJobStatus.cancelled: 'Cancelled',
  };

  // Status colors
  static Color statusColor(PrintJobStatus status) {
    switch (status) {
      case PrintJobStatus.uploaded:
        return AppTheme.uploadedColor;
      case PrintJobStatus.inQueue:
        return AppTheme.inQueueColor;
      case PrintJobStatus.printing:
        return AppTheme.printingColor;
      case PrintJobStatus.ready:
        return AppTheme.readyColor;
      case PrintJobStatus.completed:
        return AppTheme.completedColor;
      case PrintJobStatus.cancelled:
        return const Color(0xFFF44336);
    }
  }

  // Status icons
  static IconData statusIcon(PrintJobStatus status) {
    switch (status) {
      case PrintJobStatus.uploaded:
        return Icons.cloud_upload_outlined;
      case PrintJobStatus.inQueue:
        return Icons.queue_outlined;
      case PrintJobStatus.printing:
        return Icons.print_outlined;
      case PrintJobStatus.ready:
        return Icons.check_circle_outline;
      case PrintJobStatus.completed:
        return Icons.done_all;
      case PrintJobStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  // Next status mapping
  static PrintJobStatus? nextStatus(PrintJobStatus current) {
    switch (current) {
      case PrintJobStatus.uploaded:
        return PrintJobStatus.inQueue;
      case PrintJobStatus.inQueue:
        return PrintJobStatus.printing;
      case PrintJobStatus.printing:
        return PrintJobStatus.ready;
      case PrintJobStatus.ready:
        return PrintJobStatus.completed;
      case PrintJobStatus.completed:
        return null;
      case PrintJobStatus.cancelled:
        return null;
    }
  }
}
