import 'package:cloud_firestore/cloud_firestore.dart';

/// Aggregated analytics data for a shop or the platform.
/// Used for dashboard displays and reporting.
class AnalyticsModel {
  final int totalJobs;
  final int activeJobs;
  final int completedJobs;
  final int cancelledJobs;
  final double totalRevenue;
  final double avgJobDurationMinutes;
  final int totalPages;
  final Map<String, int> jobsByStatus;
  final Map<String, int> jobsByHour; // "0"-"23" → count
  final DateTime? updatedAt;

  const AnalyticsModel({
    this.totalJobs = 0,
    this.activeJobs = 0,
    this.completedJobs = 0,
    this.cancelledJobs = 0,
    this.totalRevenue = 0,
    this.avgJobDurationMinutes = 0,
    this.totalPages = 0,
    this.jobsByStatus = const {},
    this.jobsByHour = const {},
    this.updatedAt,
  });

  factory AnalyticsModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AnalyticsModel();
    return AnalyticsModel(
      totalJobs: map['totalJobs'] as int? ?? 0,
      activeJobs: map['activeJobs'] as int? ?? 0,
      completedJobs: map['completedJobs'] as int? ?? 0,
      cancelledJobs: map['cancelledJobs'] as int? ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0,
      avgJobDurationMinutes:
          (map['avgJobDurationMinutes'] as num?)?.toDouble() ?? 0,
      totalPages: map['totalPages'] as int? ?? 0,
      jobsByStatus: (map['jobsByStatus'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      jobsByHour: (map['jobsByHour'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as int),
          ) ??
          {},
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalJobs': totalJobs,
      'activeJobs': activeJobs,
      'completedJobs': completedJobs,
      'cancelledJobs': cancelledJobs,
      'totalRevenue': totalRevenue,
      'avgJobDurationMinutes': avgJobDurationMinutes,
      'totalPages': totalPages,
      'jobsByStatus': jobsByStatus,
      'jobsByHour': jobsByHour,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
