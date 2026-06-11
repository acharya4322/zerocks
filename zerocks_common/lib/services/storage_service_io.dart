import 'dart:io';
import 'dart:typed_data';

/// Native (Android/Windows/iOS) implementation of reading local file bytes.
Future<Uint8List> readFileBytesPlatform(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) {
    throw FileSystemException('File does not exist: $filePath');
  }
  return await file.readAsBytes();
}
