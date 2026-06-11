import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryModel {
  final String id;
  final String name;
  final String category; // "paper", "toner", "other"
  final int currentStock;
  final String unit; // "sheets", "cartridges", "items"
  final int lowStockThreshold;
  final DateTime? lastRestockedAt;

  const InventoryModel({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.unit,
    required this.lowStockThreshold,
    this.lastRestockedAt,
  });

  factory InventoryModel.fromMap(Map<String, dynamic> map, String id) {
    return InventoryModel(
      id: id,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'other',
      currentStock: map['currentStock'] as int? ?? 0,
      unit: map['unit'] as String? ?? 'items',
      lowStockThreshold: map['lowStockThreshold'] as int? ?? 10,
      lastRestockedAt: (map['lastRestockedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'currentStock': currentStock,
      'unit': unit,
      'lowStockThreshold': lowStockThreshold,
      if (lastRestockedAt != null) 'lastRestockedAt': Timestamp.fromDate(lastRestockedAt!),
    };
  }
}
