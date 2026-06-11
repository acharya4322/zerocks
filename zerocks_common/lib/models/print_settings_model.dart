class PrintSettingsModel {
  final String colorMode; // "bw", "color", "mixed"
  final String sides; // "single", "double"
  final String pageSize; // "A4", "A3", "Legal", etc.
  final String quality; // "draft", "standard", "high"
  final String pageRange; // "all", "1-5", "1,3,5"
  final String orientation; // "auto", "portrait", "landscape"
  final int copies;

  const PrintSettingsModel({
    this.colorMode = 'bw',
    this.sides = 'single',
    this.pageSize = 'A4',
    this.quality = 'standard',
    this.pageRange = 'all',
    this.orientation = 'auto',
    this.copies = 1,
  });

  factory PrintSettingsModel.fromMap(Map<String, dynamic> map) {
    return PrintSettingsModel(
      colorMode: map['colorMode'] as String? ?? 'bw',
      sides: map['sides'] as String? ?? 'single',
      pageSize: map['pageSize'] as String? ?? 'A4',
      quality: map['quality'] as String? ?? 'standard',
      pageRange: map['pageRange'] as String? ?? 'all',
      orientation: map['orientation'] as String? ?? 'auto',
      copies: map['copies'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'colorMode': colorMode,
      'sides': sides,
      'pageSize': pageSize,
      'quality': quality,
      'pageRange': pageRange,
      'orientation': orientation,
      'copies': copies,
    };
  }

  PrintSettingsModel copyWith({
    String? colorMode,
    String? sides,
    String? pageSize,
    String? quality,
    String? pageRange,
    String? orientation,
    int? copies,
  }) {
    return PrintSettingsModel(
      colorMode: colorMode ?? this.colorMode,
      sides: sides ?? this.sides,
      pageSize: pageSize ?? this.pageSize,
      quality: quality ?? this.quality,
      pageRange: pageRange ?? this.pageRange,
      orientation: orientation ?? this.orientation,
      copies: copies ?? this.copies,
    );
  }
}
