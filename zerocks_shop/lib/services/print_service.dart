import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:zerocks_common/zerocks_common.dart';

/// Handles document printing for the Shop app.
///
/// Security model:
/// - Files are downloaded to memory only (never saved to disk)
/// - Uses signed URLs from Cloud Functions (15-min expiry)
/// - Memory is released after printing
class PrintService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Get a temporary signed URL for a print job's file.
  /// Calls the `generateSignedUrl` Cloud Function.
  Future<String> getSignedUrl(String jobId) async {
    try {
      final result = await _functions
          .httpsCallable('generateSignedUrl')
          .call<Map<String, dynamic>>({'jobId': jobId});

      final url = result.data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('No URL returned from server');
      }
      return url;
    } on FirebaseFunctionsException catch (e) {
      ZLogger.error(
        'Failed to get signed URL for job $jobId',
        error: e,
        tag: 'PrintService',
      );
      throw Exception('Failed to access file: ${e.message}');
    }
  }

  /// Print a document from a signed URL.
  /// Downloads to memory, prints via OS dialog, then releases memory.
  /// Returns true if the print job was sent successfully.
  Future<bool> printFromUrl({
    required String signedUrl,
    required String fileName,
    required String fileType,
    required int copies,
    bool isColor = false,
    bool isDuplex = false,
  }) async {
    try {
      ZLogger.info(
        'Printing $fileName ($copies copies)',
        tag: 'PrintService',
      );

      // 1. Download file bytes (in memory — never saved to disk)
      final response = await http.get(Uri.parse(signedUrl));
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download file: HTTP ${response.statusCode}',
        );
      }

      final Uint8List bytes = response.bodyBytes;

      // 2. Convert to PDF if image
      final Uint8List pdfBytes;
      if (fileType == 'pdf') {
        pdfBytes = bytes;
      } else {
        pdfBytes = await _imageToPdf(bytes);
      }

      // 3. Send to printer
      final result = await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: fileName,
        dynamicLayout: false,
        usePrinterSettings: true,
      );

      ZLogger.info(
        'Print result for $fileName: ${result ? "success" : "cancelled"}',
        tag: 'PrintService',
      );

      return result;
    } catch (e, stack) {
      ZLogger.error(
        'Print error for $fileName',
        error: e,
        stackTrace: stack,
        tag: 'PrintService',
      );
      return false;
    }
  }

  /// Print a job end-to-end: fetch signed URL → download → print.
  /// Convenience method combining [getSignedUrl] and [printFromUrl].
  Future<bool> printJob(PrintJobModel job) async {
    final signedUrl = await getSignedUrl(job.id);
    return printFromUrl(
      signedUrl: signedUrl,
      fileName: job.fileName,
      fileType: job.fileType,
      copies: job.copies,
      isColor: job.isColor,
      isDuplex: job.isDuplex,
    );
  }

  /// List available printers on the system.
  Future<List<Printer>> getAvailablePrinters() async {
    return await Printing.listPrinters();
  }

  /// Print directly to a specific printer (skip dialog).
  Future<bool> printDirect({
    required Uint8List pdfBytes,
    required Printer printer,
    required String jobName,
  }) async {
    return await Printing.directPrintPdf(
      printer: printer,
      onLayout: (_) => pdfBytes,
      name: jobName,
      usePrinterSettings: true,
    );
  }

  /// Convert an image to a single-page PDF (A4).
  Future<Uint8List> _imageToPdf(Uint8List imageBytes) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
        ),
      ),
    );

    return pdf.save();
  }
}
