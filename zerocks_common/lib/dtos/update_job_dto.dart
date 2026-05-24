import '../models/print_job_model.dart';

/// Data Transfer Object for updating an existing print job.
class UpdateJobDto {
  final String jobId;
  final PrintJobStatus? status;
  final String? fileUrl;
  final int? queuePosition;
  final DateTime? estimatedReadyAt;

  const UpdateJobDto({
    required this.jobId,
    this.status,
    this.fileUrl,
    this.queuePosition,
    this.estimatedReadyAt,
  });

  /// Converts to a Firestore-compatible map with only non-null fields.
  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{};
    if (status != null) map['status'] = status!.name;
    if (fileUrl != null) map['fileUrl'] = fileUrl;
    if (queuePosition != null) map['queuePosition'] = queuePosition;
    if (estimatedReadyAt != null) {
      map['estimatedReadyAt'] = estimatedReadyAt;
    }
    return map;
  }
}
