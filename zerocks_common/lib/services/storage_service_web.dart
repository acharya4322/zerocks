import 'dart:typed_data';

/// Web implementation of reading local file bytes.
/// Web consumers should use uploadFileBytes() directly.
Future<Uint8List> readFileBytesPlatform(String filePath) async {
  throw UnsupportedError(
    'readFileBytesPlatform with filePath is not supported on web. '
    'Use StorageService.uploadFileBytes() instead.',
  );
}
