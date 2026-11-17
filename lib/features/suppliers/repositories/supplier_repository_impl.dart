import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supplier.dart';
import '../models/supplier_entry.dart';
import 'supplier_repository.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  SupplierRepositoryImpl(this._client);
  final SupabaseClient _client;

  String get _shopId =>
      _client.auth.currentUser?.id ??
      (throw AuthException('Please sign in to access supplier accounts.'));

  @override
  Future<List<Supplier>> listSuppliers({bool archived = false}) async {
    const pageSize = 500;
    final suppliers = <Supplier>[];
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _client
          .from('suppliers')
          .select('id,name,phone,address,is_archived')
          .eq('shop_id', _shopId)
          .eq('is_archived', archived)
          .order('name')
          .order('id')
          .range(offset, offset + pageSize - 1);
      suppliers.addAll(rows.map(Supplier.fromJson));
      if (rows.length < pageSize) break;
    }
    return suppliers;
  }

  @override
  Future<Supplier> saveSupplier({
    String? id,
    required String name,
    required String phone,
    String? address,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 150) {
      throw ArgumentError('Supplier name must contain 1–150 characters.');
    }
    if (phone.trim().length > 30 || (address?.length ?? 0) > 500) {
      throw ArgumentError('Phone or address is too long.');
    }
    final values = <String, dynamic>{
      'name': trimmed,
      'phone': phone.trim(),
      'address': address?.trim().isEmpty == true ? null : address?.trim(),
    };
    final Map<String, dynamic> row;
    if (id == null) {
      row = await _client
          .from('suppliers')
          .insert({...values, 'shop_id': _shopId})
          .select('id,name,phone,address,is_archived')
          .single();
    } else {
      row = await _client
          .from('suppliers')
          .update(values)
          .eq('id', id)
          .eq('shop_id', _shopId)
          .select('id,name,phone,address,is_archived')
          .single();
    }
    return Supplier.fromJson(row);
  }

  @override
  Future<void> setArchived(String id, bool archived) async {
    final rows = await _client
        .from('suppliers')
        .update({'is_archived': archived})
        .eq('shop_id', _shopId)
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) throw StateError('Supplier no longer exists.');
  }

  @override
  Future<List<SupplierEntry>> listEntries(String supplierId) async {
    const pageSize = 500;
    final entries = <SupplierEntry>[];
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _client
          .from('supplier_transactions')
          .select('id,supplier_id,type,amount,description,created_at')
          .eq('shop_id', _shopId)
          .eq('supplier_id', supplierId)
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + pageSize - 1);
      entries.addAll(rows.map(SupplierEntry.fromJson));
      if (rows.length < pageSize) break;
    }
    return entries;
  }

  @override
  Future<SupplierEntry> saveEntry({
    String? id,
    required String supplierId,
    required String type,
    required double amount,
    String? description,
  }) async {
    if (type != 'purchase' && type != 'payment') {
      throw ArgumentError('Choose purchase (Udhar) or payment (Jama).');
    }
    if (!amount.isFinite ||
        amount <= 0 ||
        amount > 999999999.99 ||
        (amount * 100 - (amount * 100).round()).abs() > 0.000001) {
      throw ArgumentError('Enter a valid amount with up to two decimals.');
    }
    if ((description?.length ?? 0) > 500) {
      throw ArgumentError('Description cannot exceed 500 characters.');
    }
    final values = <String, dynamic>{
      'type': type,
      'amount': amount,
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
    };
    final Map<String, dynamic> row;
    const selected = 'id,supplier_id,type,amount,description,created_at';
    if (id == null) {
      row = await _client
          .from('supplier_transactions')
          .insert({...values, 'shop_id': _shopId, 'supplier_id': supplierId})
          .select(selected)
          .single();
    } else {
      row = await _client
          .from('supplier_transactions')
          .update(values)
          .eq('id', id)
          .eq('shop_id', _shopId)
          .eq('supplier_id', supplierId)
          .select(selected)
          .single();
    }
    return SupplierEntry.fromJson(row);
  }

  @override
  Future<void> deleteEntry({
    required String id,
    required String supplierId,
  }) async {
    final rows = await _client
        .from('supplier_transactions')
        .delete()
        .eq('id', id)
        .eq('supplier_id', supplierId)
        .eq('shop_id', _shopId)
        .select('id');
    if (rows.isEmpty) throw StateError('Transaction was not found.');
  }
}
