import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

// Conditional import — picks the right implementation at compile time.
import 'storage_service_stub.dart'
    if (dart.library.io) 'storage_service_io.dart'
    if (dart.library.html) 'storage_service_web.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Upload a file from a local path (native platforms only — Android/Windows).
  /// On web, use [uploadFileBytes] instead.
  Future<String> uploadFile({
    required String jobId,
    required String filePath,
    required String fileName,
  }) async {
    final ext = fileName.split('.').last;
    final storagePath = 'printJobs/$jobId/${_uuid.v4()}.$ext';
    final ref = _storage.ref().child(storagePath);

    return await uploadFilePlatform(
      ref: ref,
      filePath: filePath,
      fileName: fileName,
      metadata: SettableMetadata(
        contentType: _getContentType(ext),
        customMetadata: {
          'jobId': jobId,
          'originalName': fileName,
        },
      ),
    );
  }

  /// Upload file from bytes — works on ALL platforms (including web).
  Future<String> uploadFileBytes({
    required String jobId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ext = fileName.split('.').last;
    final storagePath = 'printJobs/$jobId/${_uuid.v4()}.$ext';
    final ref = _storage.ref().child(storagePath);

    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(
        contentType: _getContentType(ext),
        customMetadata: {
          'jobId': jobId,
          'originalName': fileName,
        },
      ),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete a file from Storage by its download URL.
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // File may already be deleted — ignore
    }
  }

  /// Delete all files for a print job.
  Future<void> deleteJobFiles(String jobId) async {
    try {
      final listResult = await _storage.ref('printJobs/$jobId').listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      // Folder may not exist — ignore
    }
  }

  String _getContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
