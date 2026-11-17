import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import 'inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl(this._client);
  final SupabaseClient _client;

  String get _shopId =>
      _client.auth.currentUser?.id ??
      (throw AuthException('Please sign in to manage inventory.'));

  static const fields =
      'id,name,sku,category,unit,description,purchase_price,'
      'selling_price,stock_quantity,low_stock_threshold,is_archived';

  @override
  Future<List<Product>> listProducts() async {
    const pageSize = 500;
    final products = <Product>[];
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _client
          .from('products')
          .select(fields)
          .eq('shop_id', _shopId)
          .order('name')
          .order('id')
          .range(offset, offset + pageSize - 1);
      products.addAll(rows.map(Product.fromJson));
      if (rows.length < pageSize) break;
    }
    return products;
  }

  @override
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
  }) async {
    if (name.trim().isEmpty || category.trim().isEmpty || unit.trim().isEmpty) {
      throw ArgumentError('Product name, category and unit are required.');
    }
    if (!purchasePrice.isFinite ||
        purchasePrice < 0 ||
        !sellingPrice.isFinite ||
        sellingPrice < 0 ||
        !lowStockThreshold.isFinite ||
        lowStockThreshold < 0) {
      throw ArgumentError('Prices and threshold cannot be negative.');
    }
    final data = <String, dynamic>{
      'name': name.trim(),
      'category': category.trim(),
      'unit': unit.trim(),
      'sku': sku?.trim().isEmpty == true ? null : sku?.trim(),
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'low_stock_threshold': lowStockThreshold,
    };
    final Map<String, dynamic> row;
    if (id == null) {
      row = await _client
          .from('products')
          .insert({...data, 'shop_id': _shopId, 'stock_quantity': 0})
          .select(fields)
          .single();
    } else {
      row = await _client
          .from('products')
          .update(data)
          .eq('id', id)
          .eq('shop_id', _shopId)
          .select(fields)
          .single();
    }
    return Product.fromJson(row);
  }

  @override
  Future<void> setArchived(String productId, bool archived) async {
    final result = await _client
        .from('products')
        .update({'is_archived': archived})
        .eq('shop_id', _shopId)
        .eq('id', productId)
        .select('id');
    if (result.isEmpty) throw StateError('Product no longer available.');
  }

  @override
  Future<double> adjustStock(
    String productId,
    double delta,
    String reason,
  ) async {
    if (!delta.isFinite || delta == 0 || reason.trim().isEmpty) {
      throw ArgumentError('Enter a valid quantity and reason.');
    }
    if ((delta * 1000 - (delta * 1000).round()).abs() > 0.000001) {
      throw ArgumentError('Stock supports up to 3 decimal places.');
    }
    final value = await _client.rpc(
      'digikhata_adjust_stock',
      params: {
        'p_product_id': productId,
        'p_delta': delta,
        'p_reason': reason.trim(),
      },
    );
    return (value as num).toDouble();
  }

  @override
  Future<List<StockMovement>> listMovements(String productId) async {
    const pageSize = 500;
    final history = <StockMovement>[];
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _client
          .from('stock_movements')
          .select('id,delta,quantity_after,reason,created_at')
          .eq('shop_id', _shopId)
          .eq('product_id', productId)
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + pageSize - 1);
      history.addAll(rows.map(StockMovement.fromJson));
      if (rows.length < pageSize) break;
    }
    return history;
  }
}
