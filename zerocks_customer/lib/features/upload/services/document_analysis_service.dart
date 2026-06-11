import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdfx/pdfx.dart';
import 'package:image/image.dart' as img;
import 'package:zerocks_common/zerocks_common.dart';

class DocumentAnalysisService {
  static const int _colorDifferenceThreshold = 25; // Tolerance for R-G-B diff
  static const int _colorPixelsThreshold = 100; // Minimum color pixels to mark page as color

  /// Analyze a file to determine pages, color vs bw, and basic metadata.
  Future<DocumentAnalysisModel> analyzeFile(File file, {bool isScanned = false}) async {
    final bytes = await file.readAsBytes();
    final size = bytes.length;
    final extension = file.path.split('.').last.toLowerCase();

    if (extension == 'pdf') {
      return _analyzePdf(file.path, bytes, size, isScanned);
    } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
      return _analyzeImage(bytes, size, extension, isScanned);
    } else {
      // For unsupported files, return basic info (e.g. word doc)
      return DocumentAnalysisModel(
        totalPages: 1,
        colorPages: 0,
        bwPages: 1,
        fileType: extension,
        fileSizeBytes: size,
        isScanned: isScanned,
      );
    }
  }

  Future<DocumentAnalysisModel> _analyzePdf(String path, Uint8List bytes, int size, bool isScanned) async {
    int totalPages = 0;
    int colorPages = 0;
    int bwPages = 0;
    
    try {
      final document = await PdfDocument.openFile(path);
      totalPages = document.pagesCount;

      for (int i = 1; i <= totalPages; i++) {
        final page = await document.getPage(i);
        // Render page to image with reasonable resolution for color checking
        // Not too high to save memory and time
        final pageImage = await page.render(
          width: page.width / 2, 
          height: page.height / 2, 
          format: PdfPageImageFormat.png,
        );

        if (pageImage != null) {
          final isColor = _isImageColor(pageImage.bytes);
          if (isColor) {
            colorPages++;
          } else {
            bwPages++;
          }
        } else {
          // If rendering fails, default to BW
          bwPages++;
        }
        
        await page.close();
      }
      
      await document.close();
      
      return DocumentAnalysisModel(
        totalPages: totalPages,
        colorPages: colorPages,
        bwPages: bwPages,
        fileType: 'pdf',
        fileSizeBytes: size,
        isScanned: isScanned,
      );
    } catch (e) {
      debugPrint('Error analyzing PDF: $e');
      // Fallback
      return DocumentAnalysisModel(
        totalPages: totalPages > 0 ? totalPages : 1,
        colorPages: 0,
        bwPages: totalPages > 0 ? totalPages : 1,
        fileType: 'pdf',
        fileSizeBytes: size,
        isScanned: isScanned,
      );
    }
  }

  Future<DocumentAnalysisModel> _analyzeImage(Uint8List bytes, int size, String ext, bool isScanned) async {
    final isColor = _isImageColor(bytes);
    return DocumentAnalysisModel(
      totalPages: 1,
      colorPages: isColor ? 1 : 0,
      bwPages: isColor ? 0 : 1,
      fileType: ext,
      fileSizeBytes: size,
      isScanned: isScanned,
    );
  }

  /// Determines if an image contains color pixels by checking RGB variance.
  bool _isImageColor(Uint8List imageBytes) {
    try {
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) return false;

      int colorPixelsCount = 0;
      
      // Sample pixels (every 4th pixel to speed up)
      for (int y = 0; y < decodedImage.height; y += 4) {
        for (int x = 0; x < decodedImage.width; x += 4) {
          final pixel = decodedImage.getPixel(x, y);
          
          final r = pixel.r;
          final g = pixel.g;
          final b = pixel.b;

          // Check difference between RGB channels.
          // True grayscale has R == G == B.
          final maxDiff = _max3(r, g, b) - _min3(r, g, b);
          
          if (maxDiff > _colorDifferenceThreshold) {
            colorPixelsCount++;
            if (colorPixelsCount > _colorPixelsThreshold) {
              return true; // Fast exit
            }
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error decoding image for color check: $e');
      return false;
    }
  }

  num _max3(num a, num b, num c) {
    var max = a;
    if (b > max) max = b;
    if (c > max) max = c;
    return max;
  }

  num _min3(num a, num b, num c) {
    var min = a;
    if (b < min) min = b;
    if (c < min) min = c;
    return min;
  }
}
