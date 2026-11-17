import '../../../core/services/realtime_watch.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../repositories/inventory_repository.dart';

class InventoryViewModel extends GetxController {
  RealtimeWatch? _realtime;

  InventoryViewModel(this._repository);
  final InventoryRepository _repository;
  final products = <Product>[].obs;
  final loading = false.obs;
  final saving = false.obs;
  final error = RxnString();
  final search = ''.obs;
  final showArchived = false.obs;
  final onlyLowStock = false.obs;

  List<Product> get filtered {
    final query = search.value.trim().toLowerCase();
    return products
        .where(
          (product) =>
              product.isArchived == showArchived.value &&
              (!onlyLowStock.value || product.isLowStock) &&
              (query.isEmpty ||
                  [
                    product.name,
                    product.sku ?? '',
                    product.category,
                  ].any((value) => value.toLowerCase().contains(query))),
        )
        .toList();
  }

  int get activeCount => products.where((p) => !p.isArchived).length;
  int get lowCount => products.where((p) => p.isLowStock).length;
  double get inventoryValue => products
      .where((p) => !p.isArchived)
      .fold(0, (double total, p) => total + p.stockValue);

  @override
  void onInit() {
    super.onInit();
    _realtime = RealtimeWatch(Supabase.instance.client);
    _realtime!.watch(table: 'products', onChange: () => load());
    _realtime!.watch(table: 'stock_movements', onChange: () => load());
    load();
  }

  Future<void> load() async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    try {
      products.assignAll(await _repository.listProducts());
    } catch (e) {
      error.value = 'Unable to load products: $e';
    } finally {
      loading.value = false;
    }
  }

  Future<bool> save({
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
    if (saving.value) return false;
    saving.value = true;
    error.value = null;
    try {
      await _repository.saveProduct(
        id: id,
        name: name,
        category: category,
        unit: unit,
        sku: sku,
        description: description,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        lowStockThreshold: lowStockThreshold,
      );
      await load();
      return true;
    } catch (e) {
      error.value = 'Unable to save product: $e';
      return false;
    } finally {
      saving.value = false;
    }
  }

  Future<bool> archive(String id, bool archived) async {
    try {
      await _repository.setArchived(id, archived);
      await load();
      return true;
    } catch (e) {
      error.value = '$e';
      return false;
    }
  }

  Future<bool> adjust(String id, double delta, String reason) async {
    if (saving.value) return false;
    saving.value = true;
    error.value = null;
    try {
      await _repository.adjustStock(id, delta, reason);
      await load();
      return true;
    } catch (e) {
      error.value = 'Unable to update stock: $e';
      return false;
    } finally {
      saving.value = false;
    }
  }

  Future<List<StockMovement>> history(String id) =>
      _repository.listMovements(id);
  @override
  void onClose() {
    _realtime?.dispose();
    super.onClose();
  }
}
