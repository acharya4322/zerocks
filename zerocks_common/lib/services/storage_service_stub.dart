import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Stub file for conditional imports.
/// This should never be reached at runtime.
Future<String> uploadFilePlatform({
  required Reference ref,
  required String filePath,
  required String fileName,
  required SettableMetadata metadata,
}) {
  throw UnsupportedError('Platform not supported');
}

Future<Uint8List> readFileBytes(String filePath) {
  throw UnsupportedError('Platform not supported');
}
