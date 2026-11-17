class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.isArchived,
    this.sku,
    this.description,
  });

  final String id;
  final String name;
  final String category;
  final String unit;
  final String? sku;
  final String? description;
  final double purchasePrice;
  final double sellingPrice;
  final double stockQuantity;
  final double lowStockThreshold;
  final bool isArchived;

  bool get isLowStock => !isArchived && stockQuantity <= lowStockThreshold;
  double get stockValue => stockQuantity * purchasePrice;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String? ?? 'General',
    unit: json['unit'] as String? ?? 'pcs',
    sku: json['sku'] as String?,
    description: json['description'] as String?,
    purchasePrice: (json['purchase_price'] as num).toDouble(),
    sellingPrice: (json['selling_price'] as num).toDouble(),
    stockQuantity: (json['stock_quantity'] as num).toDouble(),
    lowStockThreshold: (json['low_stock_threshold'] as num).toDouble(),
    isArchived: json['is_archived'] as bool? ?? false,
  );
}
