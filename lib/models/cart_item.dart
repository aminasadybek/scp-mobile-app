class CartItem {
  final int? id;
  final int productId;
  final String productName;
  final double price;
  int quantity;
  final String imageUrl;
  final DateTime addedAt;

  CartItem({
    this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.addedAt,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
      'added_at': addedAt.toIso8601String(),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      productId: map['product_id'],
      productName: map['product_name'],
      price: map['price'],
      quantity: map['quantity'],
      imageUrl: map['image_url'],
      addedAt: DateTime.parse(map['added_at']),
    );
  }

  CartItem copyWith({
    int? id,
    int? productId,
    String? productName,
    double? price,
    int? quantity,
    String? imageUrl,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}