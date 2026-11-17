import '../../../core/services/realtime_watch.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../models/supplier.dart';
import '../models/supplier_account.dart';
import '../models/supplier_entry.dart';
import '../repositories/supplier_repository.dart';

class SupplierViewModel extends GetxController {
  RealtimeWatch? _realtime;

  SupplierViewModel(this._repository);
  final SupplierRepository _repository;

  final suppliers = <Supplier>[].obs;
  final archived = <Supplier>[].obs;
  final entries = <SupplierEntry>[].obs;
  final selected = Rxn<Supplier>();
  final loading = false.obs;
  final saving = false.obs;
  final error = RxnString();
  final query = ''.obs;
  final showArchived = false.obs;

  List<Supplier> get filtered {
    final term = query.value.trim().toLowerCase();
    final source = showArchived.value ? archived : suppliers;
    return source
        .where(
          (supplier) =>
              term.isEmpty ||
              supplier.name.toLowerCase().contains(term) ||
              supplier.phone.toLowerCase().contains(term),
        )
        .toList();
  }

  SupplierAccount? get account => selected.value == null
      ? null
      : SupplierAccount(supplier: selected.value!, entries: entries.toList());

  @override
  void onInit() {
    super.onInit();
    _realtime = RealtimeWatch(Supabase.instance.client);
    _realtime!.watch(table: 'suppliers', onChange: () => load());
    _realtime!.watch(
      table: 'supplier_transactions',
      onChange: () {
        if (selected.value != null) refreshEntries();
      },
    );

    load();
  }

  Future<void> load() async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        _repository.listSuppliers(),
        _repository.listSuppliers(archived: true),
      ]);
      suppliers.assignAll(results[0]);
      archived.assignAll(results[1]);
    } catch (e) {
      error.value = 'Unable to load suppliers: $e';
    } finally {
      loading.value = false;
    }
  }

  Future<void> open(Supplier supplier) async {
    selected.value = supplier;
    entries.clear();
    await refreshEntries();
  }

  Future<void> refreshEntries() async {
    final supplier = selected.value;
    if (supplier == null) return;
    loading.value = true;
    error.value = null;
    try {
      entries.assignAll(await _repository.listEntries(supplier.id));
    } catch (e) {
      error.value = 'Unable to load supplier ledger: $e';
    } finally {
      loading.value = false;
    }
  }

  Future<bool> saveSupplier({
    String? id,
    required String name,
    required String phone,
    String? address,
  }) async {
    if (saving.value) return false;
    saving.value = true;
    error.value = null;
    try {
      final result = await _repository.saveSupplier(
        id: id,
        name: name,
        phone: phone,
        address: address,
      );
      if (selected.value?.id == result.id) selected.value = result;
      await load();
      return true;
    } catch (e) {
      error.value = 'Unable to save supplier: $e';
      return false;
    } finally {
      saving.value = false;
    }
  }

  Future<bool> archiveSupplier(String id, bool value) async {
    try {
      await _repository.setArchived(id, value);
      await load();
      if (selected.value?.id == id) selected.value = null;
      return true;
    } catch (e) {
      error.value = 'Unable to change supplier status: $e';
      return false;
    }
  }

  Future<bool> saveEntry({
    String? id,
    required String type,
    required double amount,
    String? description,
  }) async {
    final supplier = selected.value;
    if (supplier == null || saving.value) return false;
    saving.value = true;
    error.value = null;
    try {
      await _repository.saveEntry(
        id: id,
        supplierId: supplier.id,
        type: type,
        amount: amount,
        description: description,
      );
      await refreshEntries();
      return true;
    } catch (e) {
      error.value = 'Unable to save entry: $e';
      return false;
    } finally {
      saving.value = false;
    }
  }

  Future<bool> removeEntry(String id) async {
    if (selected.value == null || saving.value) return false;
    saving.value = true;
    error.value = null;
    try {
      await _repository.deleteEntry(id: id, supplierId: selected.value!.id);
      await refreshEntries();
      return true;
    } catch (e) {
      error.value = 'Unable to remove transaction: $e';
      return false;
    } finally {
      saving.value = false;
    }
  }

  @override
  void onClose() {
    _realtime?.dispose();
    super.onClose();
  }
}
