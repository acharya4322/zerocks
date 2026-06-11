class DocumentAnalysisModel {
  final int totalPages;
  final int colorPages;
  final int bwPages;
  final String fileType;
  final int fileSizeBytes;
  final bool isScanned;
  final List<String> extractedText;

  const DocumentAnalysisModel({
    required this.totalPages,
    required this.colorPages,
    required this.bwPages,
    required this.fileType,
    required this.fileSizeBytes,
    this.isScanned = false,
    this.extractedText = const [],
  });

  factory DocumentAnalysisModel.fromMap(Map<String, dynamic> map) {
    return DocumentAnalysisModel(
      totalPages: map['totalPages'] as int? ?? 0,
      colorPages: map['colorPages'] as int? ?? 0,
      bwPages: map['bwPages'] as int? ?? 0,
      fileType: map['fileType'] as String? ?? 'unknown',
      fileSizeBytes: map['fileSizeBytes'] as int? ?? 0,
      isScanned: map['isScanned'] as bool? ?? false,
      extractedText: List<String>.from(map['extractedText'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalPages': totalPages,
      'colorPages': colorPages,
      'bwPages': bwPages,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'isScanned': isScanned,
      'extractedText': extractedText,
    };
  }
}
