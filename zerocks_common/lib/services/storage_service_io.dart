import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Native (Android/Windows) implementation of file upload.
/// Uses dart:io File for local file access.
Future<String> uploadFilePlatform({
  required Reference ref,
  required String filePath,
  required String fileName,
  required SettableMetadata metadata,
}) async {
  final file = File(filePath);
  final uploadTask = ref.putFile(file, metadata);
  final snapshot = await uploadTask;
  return await snapshot.ref.getDownloadURL();
}

/// Read file bytes from a local file path (native only).
Future<Uint8List> readFileBytes(String filePath) async {
  return await File(filePath).readAsBytes();
}
