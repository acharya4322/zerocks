import 'package:cloud_firestore/cloud_firestore.dart';

enum PrintJobStatus {
  uploaded,
  inQueue,
  printing,
  ready,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case PrintJobStatus.uploaded:
        return 'Uploaded';
      case PrintJobStatus.inQueue:
        return 'In Queue';
      case PrintJobStatus.printing:
        return 'Printing';
      case PrintJobStatus.ready:
        return 'Ready';
      case PrintJobStatus.completed:
        return 'Completed';
      case PrintJobStatus.cancelled:
        return 'Cancelled';
    }
  }

  static PrintJobStatus fromString(String value) {
    return PrintJobStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PrintJobStatus.uploaded,
    );
  }
}

class PrintJobModel {
  final String id;
  final String userId;
  final String shopId;
  final String? shopName;
  final String? orderId;
  final String? fileUrl;
  final String fileName;
  final String fileType; // 'pdf' or 'image'
  final int? fileSizeBytes;
  final int? pageCount;
  final PrintJobStatus status;
  final int copies;

  // Print options
  final bool isColor;
  final bool isDuplex;
  final String pageSize;
  final String orientation;
  final String? pageRange;

  // Pricing
  final double? pricePerPage;
  final double? totalPrice;

  // Queue
  final int? queuePosition;
  final DateTime? estimatedReadyAt;

  // Timestamps
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? printedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;

  // Status history
  final List<StatusChange> statusHistory;

  const PrintJobModel({
    required this.id,
    required this.userId,
    required this.shopId,
    this.shopName,
    this.orderId,
    this.fileUrl,
    required this.fileName,
    required this.fileType,
    this.fileSizeBytes,
    this.pageCount,
    required this.status,
    required this.copies,
    this.isColor = false,
    this.isDuplex = false,
    this.pageSize = 'A4',
    this.orientation = 'auto',
    this.pageRange,
    this.pricePerPage,
    this.totalPrice,
    this.queuePosition,
    this.estimatedReadyAt,
    required this.createdAt,
    this.acceptedAt,
    this.printedAt,
    this.completedAt,
    this.expiresAt,
    this.statusHistory = const [],
  });

  factory PrintJobModel.fromMap(Map<String, dynamic> map, String docId) {
    // Parse print options map
    final printOptions = map['printOptions'] as Map<String, dynamic>?;
    // Parse pricing map
    final pricing = map['pricing'] as Map<String, dynamic>?;
    // Parse status history
    final historyList = map['statusHistory'] as List<dynamic>?;

    return PrintJobModel(
      id: docId,
      userId: map['userId'] as String,
      shopId: map['shopId'] as String,
      shopName: map['shopName'] as String?,
      orderId: map['orderId'] as String?,
      fileUrl: map['fileUrl'] as String?,
      fileName: map['fileName'] as String,
      fileType: map['fileType'] as String? ?? 'pdf',
      fileSizeBytes: map['fileSizeBytes'] as int?,
      pageCount: map['pageCount'] as int?,
      status: PrintJobStatus.fromString(map['status'] as String),
      copies: map['copies'] as int? ?? 1,
      // Print options
      isColor: printOptions?['isColor'] as bool? ?? false,
      isDuplex: printOptions?['isDuplex'] as bool? ?? false,
      pageSize: printOptions?['pageSize'] as String? ?? 'A4',
      orientation: printOptions?['orientation'] as String? ?? 'auto',
      pageRange: printOptions?['pageRange'] as String?,
      // Pricing
      pricePerPage: (pricing?['pricePerPage'] as num?)?.toDouble(),
      totalPrice: (pricing?['total'] as num?)?.toDouble(),
      // Queue
      queuePosition: map['queuePosition'] as int?,
      estimatedReadyAt:
          (map['estimatedReadyAt'] as Timestamp?)?.toDate(),
      // Timestamps
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (map['acceptedAt'] as Timestamp?)?.toDate(),
      printedAt: (map['printedAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      // Status history
      statusHistory: historyList
              ?.map((e) =>
                  StatusChange.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'shopId': shopId,
      'shopName': shopName,
      'orderId': orderId,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'pageCount': pageCount,
      'status': status.name,
      'copies': copies,
      'printOptions': {
        'isColor': isColor,
        'isDuplex': isDuplex,
        'pageSize': pageSize,
        'orientation': orientation,
        'pageRange': pageRange,
      },
      'pricing': pricePerPage != null
          ? {
              'pricePerPage': pricePerPage,
              'total': totalPrice,
            }
          : null,
      'queuePosition': queuePosition,
      'estimatedReadyAt': estimatedReadyAt != null
          ? Timestamp.fromDate(estimatedReadyAt!)
          : null,
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedAt':
          acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'printedAt':
          printedAt != null ? Timestamp.fromDate(printedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'expiresAt':
          expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'statusHistory':
          statusHistory.map((e) => e.toMap()).toList(),
    };
  }

  PrintJobModel copyWith({
    String? id,
    String? userId,
    String? shopId,
    String? shopName,
    String? orderId,
    String? fileUrl,
    String? fileName,
    String? fileType,
    int? fileSizeBytes,
    int? pageCount,
    PrintJobStatus? status,
    int? copies,
    bool? isColor,
    bool? isDuplex,
    String? pageSize,
    String? orientation,
    String? pageRange,
    double? pricePerPage,
    double? totalPrice,
    int? queuePosition,
    DateTime? estimatedReadyAt,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? printedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    List<StatusChange>? statusHistory,
  }) {
    return PrintJobModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      orderId: orderId ?? this.orderId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      pageCount: pageCount ?? this.pageCount,
      status: status ?? this.status,
      copies: copies ?? this.copies,
      isColor: isColor ?? this.isColor,
      isDuplex: isDuplex ?? this.isDuplex,
      pageSize: pageSize ?? this.pageSize,
      orientation: orientation ?? this.orientation,
      pageRange: pageRange ?? this.pageRange,
      pricePerPage: pricePerPage ?? this.pricePerPage,
      totalPrice: totalPrice ?? this.totalPrice,
      queuePosition: queuePosition ?? this.queuePosition,
      estimatedReadyAt: estimatedReadyAt ?? this.estimatedReadyAt,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      printedAt: printedAt ?? this.printedAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  bool get isActive =>
      status != PrintJobStatus.completed &&
      status != PrintJobStatus.cancelled;
}

/// Records a status change event in the job's history.
class StatusChange {
  final String status;
  final DateTime at;
  final String? by; // UID of who made the change

  const StatusChange({
    required this.status,
    required this.at,
    this.by,
  });

  factory StatusChange.fromMap(Map<String, dynamic> map) {
    return StatusChange(
      status: map['status'] as String,
      at: (map['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      by: map['by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'at': Timestamp.fromDate(at),
      'by': by,
    };
  }
}
