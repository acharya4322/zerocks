/// File utility functions used across all Zerocks apps.
class FileUtils {
  FileUtils._();

  /// Format file size bytes to human-readable string.
  /// Examples: "1.2 KB", "3.5 MB"
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  /// Get file extension from a filename (lowercase, no dot).
  static String getExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if a file is a PDF based on its extension.
  static bool isPdf(String fileName) {
    return getExtension(fileName) == 'pdf';
  }

  /// Check if a file is an image based on its extension.
  static bool isImage(String fileName) {
    return ['jpg', 'jpeg', 'png'].contains(getExtension(fileName));
  }

  /// Get a display-friendly file type label.
  static String getFileTypeLabel(String fileName) {
    if (isPdf(fileName)) return 'PDF Document';
    final ext = getExtension(fileName).toUpperCase();
    return '$ext Image';
  }

  /// Truncate a filename for display, keeping the extension.
  /// Example: "very_long_document_name.pdf" → "very_long_doc...pdf"
  static String truncateFileName(String fileName, {int maxLength = 25}) {
    if (fileName.length <= maxLength) return fileName;
    final ext = getExtension(fileName);
    final nameWithoutExt =
        fileName.substring(0, fileName.length - ext.length - 1);
    final truncated =
        nameWithoutExt.substring(0, maxLength - ext.length - 4);
    return '$truncated...$ext';
  }
}
