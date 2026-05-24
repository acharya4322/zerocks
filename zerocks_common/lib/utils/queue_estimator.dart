import '../models/print_job_model.dart';

/// Estimates queue wait times for customers and shops.
class QueueEstimator {
  QueueEstimator._();

  static const double _defaultAvgMinutes = 5.0;
  static const double _bufferMultiplier = 1.2; // 20% buffer

  /// Estimate wait time based on queue position and historical averages.
  static Duration estimateWait({
    required int queuePosition,
    required double averagePrintTimeMinutes,
  }) {
    if (queuePosition <= 0) return Duration.zero;
    final minutes =
        queuePosition * averagePrintTimeMinutes * _bufferMultiplier;
    return Duration(minutes: minutes.ceil());
  }

  /// Calculate average print time from a shop's completed jobs.
  /// Falls back to a default if insufficient data.
  static double calculateAveragePrintTime(List<PrintJobModel> completedJobs) {
    if (completedJobs.isEmpty) return _defaultAvgMinutes;

    final durations = completedJobs
        .where((j) => j.completedAt != null)
        .map((j) =>
            j.completedAt!.difference(j.createdAt).inMinutes.toDouble())
        .where((d) => d > 0 && d < 120) // Filter outliers
        .toList();

    if (durations.isEmpty) return _defaultAvgMinutes;
    return durations.reduce((a, b) => a + b) / durations.length;
  }

  /// Format estimated wait as user-friendly string.
  /// Examples: "~5 min", "~1 hr", "~1 hr 30 min"
  static String formatEstimate(Duration duration) {
    if (duration.inMinutes <= 0) return 'Ready now';
    if (duration.inMinutes < 60) return '~${duration.inMinutes} min';
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    if (mins == 0) return '~$hours hr';
    return '~$hours hr $mins min';
  }

  /// Assign queue positions to a list of active jobs.
  /// Jobs must be sorted by createdAt ascending.
  static List<PrintJobModel> assignPositions(List<PrintJobModel> jobs) {
    int position = 1;
    return jobs.map((job) {
      if (job.status == PrintJobStatus.inQueue ||
          job.status == PrintJobStatus.uploaded) {
        return job.copyWith(queuePosition: position++);
      }
      return job;
    }).toList();
  }
}
