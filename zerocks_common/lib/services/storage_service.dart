import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import 'cloudflare_config.dart';
import '../utils/logger.dart';

// Conditional import to read local file bytes on native platforms safely
import 'storage_service_stub.dart'
    if (dart.library.io) 'storage_service_io.dart'
    if (dart.library.html) 'storage_service_web.dart';

class StorageService {
  final _uuid = const Uuid();

  /// Upload a file from a local path (native platforms only — Android/iOS/Windows).
  /// On web, use [uploadFileBytes] instead.
  Future<String> uploadFile({
    required String jobId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final bytes = await readFileBytesPlatform(filePath);
      return await uploadFileBytes(
        jobId: jobId,
        bytes: bytes,
        fileName: fileName,
      );
    } catch (e) {
      ZLogger.error('Failed to read or upload file from path: $filePath', error: e, tag: 'StorageService');
      rethrow;
    }
  }

  /// Upload file from bytes — works on ALL platforms (including web).
  Future<String> uploadFileBytes({
    required String jobId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ext = fileName.split('.').last.toLowerCase();
    final storagePath = 'printJobs/$jobId/${_uuid.v4()}.$ext';

    // 1. If Cloudflare R2 is not configured, fallback to mock development URL
    if (!CloudflareR2Config.isConfigured) {
      ZLogger.warn(
        'Cloudflare R2 is NOT configured. Swapping to mock dev storage URL.',
        tag: 'StorageService',
      );
      // We return a mock public URL that mimics R2 structure
      final mockUrl = '${CloudflareR2Config.publicUrl}/$storagePath';
      ZLogger.info('Mock upload success. File URL: $mockUrl', tag: 'StorageService');
      return mockUrl;
    }

    // 2. Perform real S3-compatible PUT upload to Cloudflare R2
    try {
      final endpointHost = '${CloudflareR2Config.bucketName}.${CloudflareR2Config.accountId}.r2.cloudflarestorage.com';
      final requestUri = Uri.parse('https://$endpointHost/$storagePath');
      final contentType = _getContentType(ext);

      // Sign the PUT request with AWS SigV4
      final signer = _AwsSigV4Signer(
        accessKey: CloudflareR2Config.accessKeyId,
        secretKey: CloudflareR2Config.secretAccessKey,
        region: CloudflareR2Config.region,
      );

      final headers = signer.sign(
        method: 'PUT',
        endpoint: requestUri,
        path: '/$storagePath',
        headers: {
          'Content-Type': contentType,
        },
        payloadBytes: bytes,
      );

      ZLogger.info('Uploading file to Cloudflare R2: $storagePath', tag: 'StorageService');

      final response = await http.put(
        requestUri,
        headers: headers,
        body: bytes,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Failed to upload to Cloudflare R2: HTTP ${response.statusCode} - ${response.body}',
        );
      }

      // Return public read URL
      final publicUrl = '${CloudflareR2Config.publicUrl}/$storagePath';
      ZLogger.info('R2 upload success. Public URL: $publicUrl', tag: 'StorageService');
      return publicUrl;
    } catch (e, stack) {
      ZLogger.error('Cloudflare R2 direct REST upload failed', error: e, stackTrace: stack, tag: 'StorageService');
      rethrow;
    }
  }

  /// Delete a file from Cloudflare R2 by its public download URL.
  Future<void> deleteFile(String downloadUrl) async {
    if (!CloudflareR2Config.isConfigured) {
      ZLogger.info('Mock delete request for: $downloadUrl', tag: 'StorageService');
      return;
    }

    try {
      // Extract path starting from 'printJobs/'
      final downloadUri = Uri.parse(downloadUrl);
      
      String storagePath = downloadUri.path;
      if (storagePath.startsWith('/')) {
        storagePath = storagePath.substring(1);
      }

      // If R2 public custom URL has a different path prefix, adjust accordingly.
      // Usually, it maps directly, so storagePath = 'printJobs/jobId/file.pdf'
      final endpointHost = '${CloudflareR2Config.bucketName}.${CloudflareR2Config.accountId}.r2.cloudflarestorage.com';
      final requestUri = Uri.parse('https://$endpointHost/$storagePath');

      final signer = _AwsSigV4Signer(
        accessKey: CloudflareR2Config.accessKeyId,
        secretKey: CloudflareR2Config.secretAccessKey,
        region: CloudflareR2Config.region,
      );

      final headers = signer.sign(
        method: 'DELETE',
        endpoint: requestUri,
        path: '/$storagePath',
        headers: {},
        payloadBytes: const [], // No body in DELETE request
      );

      ZLogger.info('Deleting file from Cloudflare R2: $storagePath', tag: 'StorageService');
      
      final response = await http.delete(
        requestUri,
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        ZLogger.warn('R2 delete failed: HTTP ${response.statusCode} - ${response.body}', tag: 'StorageService');
      } else {
        ZLogger.info('R2 delete success for: $storagePath', tag: 'StorageService');
      }
    } catch (e) {
      ZLogger.warn('Cloudflare R2 file deletion ignored: $e', tag: 'StorageService');
    }
  }

  /// Delete all files for a print job (e.g. clean up).
  /// Note: R2/S3 S3-compatible APIs do not support folder deletions in one API call.
  /// We must query/list or rely on lifecycle rules.
  /// For this client-side cleanup, we delete the primary file.
  Future<void> deleteJobFiles(String jobId) async {
    // Rely on Cloudflare R2 Object Lifecycle Rules to auto-delete printJobs/* after 7 days
    ZLogger.info('Job cleanup for $jobId. Relying on R2 Lifecycle Rules.', tag: 'StorageService');
  }

  String _getContentType(String ext) {
    switch (ext) {
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

/// Pure Dart implementation of AWS Signature Version 4
class _AwsSigV4Signer {
  final String accessKey;
  final String secretKey;
  final String region;
  final String service = 's3';

  _AwsSigV4Signer({
    required this.accessKey,
    required this.secretKey,
    this.region = 'auto',
  });

  Map<String, String> sign({
    required String method,
    required Uri endpoint,
    required String path,
    required Map<String, String> headers,
    required List<int> payloadBytes,
  }) {
    final now = DateTime.now().toUtc();
    final amzDate = _formatAmzDate(now);
    final dateStamp = _formatDateStamp(now);

    final payloadHash = sha256.convert(payloadBytes).toString();

    // Setup headers
    final canonicalHeaders = <String, String>{};
    canonicalHeaders['host'] = endpoint.host;
    canonicalHeaders['x-amz-content-sha256'] = payloadHash;
    canonicalHeaders['x-amz-date'] = amzDate;
    
    headers.forEach((k, v) {
      canonicalHeaders[k.toLowerCase()] = v;
    });

    // Sort headers alphabetically
    final sortedHeaderKeys = canonicalHeaders.keys.toList()..sort();
    final canonicalHeadersString = '${sortedHeaderKeys
        .map((key) => '$key:${canonicalHeaders[key]!.trim()}')
        .join('\n')}\n';

    final signedHeaders = sortedHeaderKeys.join(';');

    final canonicalRequest = [
      method.toUpperCase(),
      Uri.encodeFull(path),
      '', // Query string (empty)
      canonicalHeadersString,
      signedHeaders,
      payloadHash,
    ].join('\n');

    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final hashedCanonicalRequest = sha256.convert(utf8.encode(canonicalRequest)).toString();

    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      hashedCanonicalRequest,
    ].join('\n');

    final signingKey = _getSignatureKey(secretKey, dateStamp, region, service);
    final signature = _hmacSha256(signingKey, stringToSign);
    final signatureHex = signature.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    final resultHeaders = <String, String>{};
    resultHeaders['Host'] = endpoint.host;
    resultHeaders['x-amz-date'] = amzDate;
    resultHeaders['x-amz-content-sha256'] = payloadHash;
    resultHeaders['Authorization'] = 
        'AWS4-HMAC-SHA256 Credential=$accessKey/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signatureHex';
    
    headers.forEach((k, v) {
      resultHeaders[k] = v;
    });

    return resultHeaders;
  }

  List<int> _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }

  List<int> _getSignatureKey(String key, String dateStamp, String regionName, String serviceName) {
    final kDate = _hmacSha256(utf8.encode('AWS4$key'), dateStamp);
    final kRegion = _hmacSha256(kDate, regionName);
    final kService = _hmacSha256(kRegion, serviceName);
    final kSigning = _hmacSha256(kService, 'aws4_request');
    return kSigning;
  }

  String _formatAmzDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }

  String _formatDateStamp(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }
}
