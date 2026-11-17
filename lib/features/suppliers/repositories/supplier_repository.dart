import '../models/supplier.dart';
import '../models/supplier_entry.dart';

abstract class SupplierRepository {
  Future<List<Supplier>> listSuppliers({bool archived = false});
  Future<Supplier> saveSupplier({
    String? id,
    required String name,
    required String phone,
    String? address,
  });
  Future<void> setArchived(String id, bool archived);
  Future<List<SupplierEntry>> listEntries(String supplierId);
  Future<SupplierEntry> saveEntry({
    String? id,
    required String supplierId,
    required String type,
    required double amount,
    String? description,
  });
  Future<void> deleteEntry({required String id, required String supplierId});
}
