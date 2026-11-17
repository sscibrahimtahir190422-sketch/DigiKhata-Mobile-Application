import 'package:flutter_test/flutter_test.dart';
import 'package:digikhata/features/inventory/models/product.dart';

void main() {
  test('Product calculates low stock and cost value', () {
    const product = Product(
      id: 'p1',
      name: 'Rice',
      category: 'Groceries',
      unit: 'kg',
      purchasePrice: 120,
      sellingPrice: 155,
      stockQuantity: 2.5,
      lowStockThreshold: 3,
      isArchived: false,
    );
    expect(product.isLowStock, isTrue);
    expect(product.stockValue, 300);
  });

  test('Archived products are not marked low stock', () {
    const product = Product(
      id: 'p2',
      name: 'Sugar',
      category: 'Groceries',
      unit: 'kg',
      purchasePrice: 100,
      sellingPrice: 110,
      stockQuantity: 0,
      lowStockThreshold: 5,
      isArchived: true,
    );
    expect(product.isLowStock, isFalse);
  });

  test('Product parses numeric data from Supabase', () {
    final product = Product.fromJson({
      'id': 'p3',
      'name': 'Milk',
      'category': 'Dairy',
      'unit': 'ltr',
      'purchase_price': 210,
      'selling_price': 245.50,
      'stock_quantity': 6,
      'low_stock_threshold': 2.5,
      'is_archived': false,
    });
    expect(product.purchasePrice, 210.0);
    expect(product.sellingPrice, 245.5);
    expect(product.isLowStock, isFalse);
  });
}
