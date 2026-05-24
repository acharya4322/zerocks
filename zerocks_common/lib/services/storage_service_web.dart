import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Web implementation of file upload.
/// Uses Uint8List bytes since dart:io is not available on web.
Future<String> uploadFilePlatform({
  required Reference ref,
  required String filePath,
  required String fileName,
  required SettableMetadata metadata,
}) async {
  // On web, filePath is not usable. This path shouldn't be reached
  // because web consumers should use uploadFileBytes() instead.
  // Throw a clear error if called incorrectly.
  throw UnsupportedError(
    'uploadFilePlatform with filePath is not supported on web. '
    'Use StorageService.uploadFileBytes() instead.',
  );
}

/// Read file bytes — not supported on web via file path.
Future<Uint8List> readFileBytes(String filePath) async {
  throw UnsupportedError(
    'readFileBytes with filePath is not supported on web.',
  );
}
