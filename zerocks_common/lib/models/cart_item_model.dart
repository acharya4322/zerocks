class CartItemModel {
  final String id; // productId or serviceId
  final String name;
  final int quantity;
  final double unitPrice;
  final String type; // "service" or "stationery"

  const CartItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.type,
  });

  double get total => quantity * unitPrice;

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] as String? ?? map['productId'] as String? ?? '',
      name: map['name'] as String,
      quantity: map['quantity'] as int? ?? 1,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      type: map['type'] as String? ?? 'stationery', // Defaults to stationery for backward compat
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (type == 'stationery') 'productId': id else 'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total,
      'type': type,
    };
  }

  CartItemModel copyWith({
    String? id,
    String? name,
    int? quantity,
    double? unitPrice,
    String? type,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      type: type ?? this.type,
    );
  }
}
