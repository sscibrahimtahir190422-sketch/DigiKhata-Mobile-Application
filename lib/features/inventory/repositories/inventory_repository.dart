import '../models/product.dart';
import '../models/stock_movement.dart';

abstract interface class InventoryRepository {
  Future<List<Product>> listProducts();
  Future<Product> saveProduct({
    String? id,
    required String name,
    required String category,
    required String unit,
    String? sku,
    String? description,
    required double purchasePrice,
    required double sellingPrice,
    required double lowStockThreshold,
  });
  Future<void> setArchived(String productId, bool archived);
  Future<double> adjustStock(String productId, double delta, String reason);
  Future<List<StockMovement>> listMovements(String productId);
}
