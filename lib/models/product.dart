class Product {
  final int id;
  final String name;
  final String supplierName;
  final double price;
  final String unit;
  final int stockQuantity;
  final int minOrderQuantity;
  final int supplierId;
  final String imageUrl;
  final bool isActive;
  final List<String> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.supplierName,
    required this.price,
    required this.unit,
    required this.stockQuantity,
    required this.minOrderQuantity,
    required this.supplierId,
    required this.imageUrl,
    this.isActive = true,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      supplierName: json['supplierName'] ?? '',
      price: (json['price'] as num).toDouble(),
      unit: json['unit'],
      stockQuantity: json['stock_quantity'],
      minOrderQuantity: json['min_order_quantity'],
      supplierId: json['supplier_id'],
      imageUrl: json['image_url'] ?? '',
      isActive: json['is_active'] ?? true,
      images: List<String>.from(json['images'] ?? []),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'supplierName': supplierName,
      'price': price,
      'unit': unit,
      'stock_quantity': stockQuantity,
      'min_order_quantity': minOrderQuantity,
      'supplier_id': supplierId,
      'image_url': imageUrl,
      'is_active': isActive,
      'images': images,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}