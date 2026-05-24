/// Validates files before upload to enforce size and type constraints.
class FileValidator {
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const double maxFileSizeMB = 10.0;
  static const List<String> allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  static const List<String> allowedMimeTypes = [
    'application/pdf',
    'image/jpeg',
    'image/png',
  ];

  /// Validate a file by name and size.
  /// Returns a [ValidationResult] with success or a user-friendly error message.
  static ValidationResult validate(String fileName, int sizeBytes) {
    // Check extension
    final ext = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      return ValidationResult.error(
        'Unsupported file type ".$ext". Only PDF and image files '
        '(${allowedExtensions.join(", ")}) are allowed.',
      );
    }

    // Check size
    if (sizeBytes > maxFileSizeBytes) {
      final sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return ValidationResult.error(
        'File is too large ($sizeMB MB). Maximum size is '
        '${maxFileSizeMB.toInt()} MB.',
      );
    }

    if (sizeBytes == 0) {
      return ValidationResult.error('File is empty (0 bytes).');
    }

    return ValidationResult.ok();
  }

  /// Determine file type from extension.
  static String getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ext == 'pdf' ? 'pdf' : 'image';
  }

  /// Get MIME content type from extension.
  static String getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
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

/// Result of a validation check.
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._({required this.isValid, this.errorMessage});

  factory ValidationResult.ok() =>
      const ValidationResult._(isValid: true);

  factory ValidationResult.error(String message) =>
      ValidationResult._(isValid: false, errorMessage: message);
}
