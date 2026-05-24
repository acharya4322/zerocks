import 'package:flutter/material.dart';
import 'package:zerocks_common/zerocks_common.dart';

class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────
  static const String appName = 'Zerocks';
  static const String appTagline = 'Secure Printing, Simplified';

  // ── Search Defaults ──────────────────────────────────────
  static const double defaultSearchRadiusKm = 5.0;

  // ── File Upload ──────────────────────────────────────────
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const double maxFileSizeMB = 10.0;
  static const List<String> allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
  ];

  // ── Copies ───────────────────────────────────────────────
  static const int minCopies = 1;
  static const int maxCopies = 10;

  // ── OTP ──────────────────────────────────────────────────
  static const int otpLength = 6;
  static const int otpResendSeconds = 60;

  // ── Status Colors ────────────────────────────────────────
  static Color statusColor(PrintJobStatus status) {
    switch (status) {
      case PrintJobStatus.uploaded:
        return const Color(0xFF2196F3); // Blue
      case PrintJobStatus.inQueue:
        return const Color(0xFFFF9800); // Orange
      case PrintJobStatus.printing:
        return const Color(0xFFFFC107); // Amber
      case PrintJobStatus.ready:
        return const Color(0xFF4CAF50); // Green
      case PrintJobStatus.completed:
        return const Color(0xFF9E9E9E); // Grey
      case PrintJobStatus.cancelled:
        return const Color(0xFFF44336); // Red
    }
  }

  // ── Status Icons ─────────────────────────────────────────
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
}
