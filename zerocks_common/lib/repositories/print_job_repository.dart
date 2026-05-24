import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../dtos/create_job_dto.dart';
import '../models/print_job_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';

/// Repository for print job operations.
/// Encapsulates the coordination between Firestore and Storage,
/// providing a clean API for the UI layer.
class PrintJobRepository {
  final FirestoreService _firestore;
  final StorageService _storage;
  static const _uuid = Uuid();

  PrintJobRepository(this._firestore, this._storage);

  /// Creates a new print job with file upload.
  ///
  /// 1. Generates a unique job ID
  /// 2. Creates the Firestore document (status: uploaded)
  /// 3. Uploads the file to Storage
  /// 4. Updates the job with the file URL
  ///
  /// On upload failure, performs partial cleanup.
  Future<PrintJobModel> createJobWithFile({
    required CreateJobDto dto,
    required Uint8List fileBytes,
  }) async {
    final jobId = _uuid.v4();
    ZLogger.info('Creating job $jobId for shop ${dto.shopId}', tag: 'PrintJobRepo');

    // 1. Create job document
    final job = PrintJobModel(
      id: jobId,
      userId: dto.userId,
      shopId: dto.shopId,
      fileName: dto.fileName,
      fileType: dto.fileType,
      status: PrintJobStatus.uploaded,
      copies: dto.copies,
      createdAt: DateTime.now(),
    );
    await _firestore.createPrintJob(job);

    // 2. Upload file
    try {
      final url = await _storage.uploadFileBytes(
        jobId: jobId,
        bytes: fileBytes,
        fileName: dto.fileName,
      );

      // 3. Update job with file URL
      await _firestore.updateJobFileUrl(jobId, url);
      ZLogger.info('Job $jobId created with file URL', tag: 'PrintJobRepo');
      return job.copyWith(fileUrl: url);
    } catch (e, stack) {
      // Cleanup on failure
      ZLogger.error('Upload failed for job $jobId, cleaning up',
          error: e, stackTrace: stack, tag: 'PrintJobRepo');
      await _storage.deleteJobFiles(jobId);
      rethrow;
    }
  }

  /// Creates a job with a local file path (native platforms only).
  Future<PrintJobModel> createJobFromPath({
    required CreateJobDto dto,
    required String filePath,
  }) async {
    final jobId = _uuid.v4();
    ZLogger.info('Creating job $jobId from path', tag: 'PrintJobRepo');

    final job = PrintJobModel(
      id: jobId,
      userId: dto.userId,
      shopId: dto.shopId,
      fileName: dto.fileName,
      fileType: dto.fileType,
      status: PrintJobStatus.uploaded,
      copies: dto.copies,
      createdAt: DateTime.now(),
    );
    await _firestore.createPrintJob(job);

    try {
      final url = await _storage.uploadFile(
        jobId: jobId,
        filePath: filePath,
        fileName: dto.fileName,
      );
      await _firestore.updateJobFileUrl(jobId, url);
      return job.copyWith(fileUrl: url);
    } catch (e) {
      await _storage.deleteJobFiles(jobId);
      rethrow;
    }
  }

  /// Update job status with proper state machine validation.
  Future<void> updateStatus(String jobId, PrintJobStatus newStatus) async {
    await _firestore.updateJobStatus(jobId, newStatus);
    ZLogger.info('Job $jobId → ${newStatus.name}', tag: 'PrintJobRepo');
  }

  /// Complete a job: marks status and triggers file cleanup (client side).
  /// Note: In production, file cleanup is handled by Cloud Functions.
  Future<void> completeJob(String jobId, String? fileUrl) async {
    await _firestore.updateJobStatus(jobId, PrintJobStatus.completed);
    if (fileUrl != null) {
      try {
        await _storage.deleteFile(fileUrl);
      } catch (_) {
        // Cloud Function will handle cleanup as a safety net
      }
    }
    ZLogger.info('Job $jobId completed', tag: 'PrintJobRepo');
  }

  /// Stream a single job for real-time tracking.
  Stream<PrintJobModel?> watchJob(String jobId) {
    return _firestore.streamJob(jobId);
  }

  /// Stream all jobs for a customer.
  Stream<List<PrintJobModel>> watchUserJobs(String userId) {
    return _firestore.streamJobsByUser(userId);
  }

  /// Stream all jobs for a shop.
  Stream<List<PrintJobModel>> watchShopJobs(String shopId) {
    return _firestore.streamJobsByShop(shopId);
  }
}
