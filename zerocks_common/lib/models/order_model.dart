import 'package:cloud_firestore/cloud_firestore.dart';
import 'print_job_model.dart';

enum OrderStatus {
  pending,      // Created, awaiting payment
  paid,         // Payment successful, awaiting shop acceptance
  inQueue,      // Shop accepted, in processing queue
  processing,   // Currently printing / packing
  ready,        // Ready for pickup
  completed,    // Handed over to customer
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.pending: return 'Pending Payment';
      case OrderStatus.paid: return 'Paid';
      case OrderStatus.inQueue: return 'In Queue';
      case OrderStatus.processing: return 'Processing';
      case OrderStatus.ready: return 'Ready for Pickup';
      case OrderStatus.completed: return 'Completed';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

enum OrderItemType {
  print,
  product,
  service;

  static OrderItemType fromString(String value) {
    return OrderItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderItemType.product,
    );
  }
}

class OrderItemModel {
  final String id;
  final OrderItemType type;
  final String name;
  final double price;
  final int quantity;
  
  // For physical products
  final String? productId;
  final String? imageUrl;
  
  // For print jobs
  final String? fileUrl;
  final String? fileType;
  final int? pageCount;
  final Map<String, dynamic>? printOptions;

  const OrderItemModel({
    required this.id,
    required this.type,
    required this.name,
    required this.price,
    required this.quantity,
    this.productId,
    this.imageUrl,
    this.fileUrl,
    this.fileType,
    this.pageCount,
    this.printOptions,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as String,
      type: OrderItemType.fromString(map['type'] as String),
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int? ?? 1,
      productId: map['productId'] as String?,
      imageUrl: map['imageUrl'] as String?,
      fileUrl: map['fileUrl'] as String?,
      fileType: map['fileType'] as String?,
      pageCount: map['pageCount'] as int?,
      printOptions: map['printOptions'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'price': price,
      'quantity': quantity,
      'productId': productId,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'pageCount': pageCount,
      'printOptions': printOptions,
    };
  }
}

class OrderModel {
  final String id;
  final String userId;
  final String shopId;
  final OrderStatus status;
  final double totalAmount;
  final String? paymentId;
  final String? paymentSignature;
  final List<OrderItemModel> items;
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<StatusChange> statusHistory;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.status,
    required this.totalAmount,
    this.paymentId,
    this.paymentSignature,
    required this.items,
    required this.createdAt,
    this.completedAt,
    this.statusHistory = const [],
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    final historyList = map['statusHistory'] as List<dynamic>?;
    final itemsList = map['items'] as List<dynamic>?;

    return OrderModel(
      id: docId,
      userId: map['userId'] as String,
      shopId: map['shopId'] as String,
      status: OrderStatus.fromString(map['status'] as String),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paymentId: map['paymentId'] as String?,
      paymentSignature: map['paymentSignature'] as String?,
      items: itemsList
              ?.map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      statusHistory: historyList
              ?.map((e) => StatusChange.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'shopId': shopId,
      'status': status.name,
      'totalAmount': totalAmount,
      'paymentId': paymentId,
      'paymentSignature': paymentSignature,
      'items': items.map((e) => e.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
    };
  }
  
  bool get isActive =>
      status != OrderStatus.completed &&
      status != OrderStatus.cancelled;
}
