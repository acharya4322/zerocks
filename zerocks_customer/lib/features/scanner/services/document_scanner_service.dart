import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class DocumentScannerService {
  /// Launches the device camera to scan documents and returns a list of local file paths (images)
  Future<List<String>> scanDocuments() async {
    try {
      final pictures = await CunningDocumentScanner.getPictures(); 
      return pictures ?? [];
    } catch (e) {
      throw Exception('Failed to scan documents: $e');
    }
  }

  /// Converts a list of image file paths into a single PDF document
  Future<String> createPdfFromImages(List<String> imagePaths) async {
    if (imagePaths.isEmpty) {
      throw Exception('No images provided to create PDF');
    }

    final pdf = pw.Document();

    for (final imagePath in imagePaths) {
      final file = File(imagePath);
      if (!await file.exists()) continue;
      
      final imageBytes = await file.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero, // full bleed
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final outputDir = await getTemporaryDirectory();
    final fileName = 'Scanned_Doc_${const Uuid().v4().substring(0, 8)}.pdf';
    final outputFile = File('${outputDir.path}/$fileName');
    
    await outputFile.writeAsBytes(await pdf.save());
    return outputFile.path;
  }
}

final documentScannerServiceProvider = Provider((ref) => DocumentScannerService());
