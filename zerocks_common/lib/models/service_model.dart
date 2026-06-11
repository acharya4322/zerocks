import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String name;
  final double price;
  final bool isAvailable;
  final String? description;
  final DateTime createdAt;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    this.isAvailable = true,
    this.description,
    required this.createdAt,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      isAvailable: map['isAvailable'] as bool? ?? true,
      description: map['description'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'isAvailable': isAvailable,
      if (description != null) 'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
