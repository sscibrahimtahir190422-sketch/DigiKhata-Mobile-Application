import '../../../core/services/realtime_watch.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../customers/models/customer.dart';
import '../models/payment_record.dart';
import '../repositories/payment_repository.dart';

class PaymentViewModel extends GetxController {
  RealtimeWatch? _realtime;

  PaymentViewModel(this._repository);
  final PaymentRepository _repository;
  final payments = <PaymentRecord>[].obs;
  final customers = <Customer>[].obs;
  final loading = false.obs;
  final saving = false.obs;
  final error = RxnString();
  final query = ''.obs;
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();
  double get total => filtered.fold(0, (double a, p) => a + p.amount);
  List<PaymentRecord> get filtered => payments.where((p) {
    final search = query.value.trim().toLowerCase();
    if (search.isNotEmpty &&
        !p.customerName.toLowerCase().contains(search) &&
        !(p.description ?? '').toLowerCase().contains(search)) {
      return false;
    }
    final from = startDate.value;
    final until = endDate.value;
    if (from != null &&
        p.createdAt.isBefore(DateTime(from.year, from.month, from.day))) {
      return false;
    }
    if (until != null &&
        !p.createdAt.isBefore(
          DateTime(until.year, until.month, until.day + 1),
        )) {
      return false;
    }
    return true;
  }).toList();

  void setRange(DateTimeRange? range) {
    startDate.value = range?.start;
    endDate.value = range?.end;
  }

  @override
  void onInit() {
    super.onInit();
    _realtime = RealtimeWatch(Supabase.instance.client);
    _realtime!.watch(table: 'khata_transactions', onChange: () => load());
    _realtime!.watch(table: 'customers', onChange: () => load());
    load();
  }

  Future<void> load() async {
    if (loading.value) {
      return;
    }
    loading.value = true;
    error.value = null;
    try {
      final result = await Future.wait<Object>([
        _repository.listPayments(),
        _repository.listCustomers(),
      ]);
      payments.assignAll(result[0] as List<PaymentRecord>);
      customers.assignAll(result[1] as List<Customer>);
    } catch (e) {
      error.value = 'Could not load payments: $e';
    } finally {
      loading.value = false;
    }
  }

  Future<bool> create({
    required String customerId,
    required double amount,
    String? description,
  }) async {
    if (saving.value) {
      return false;
    }
    saving.value = true;
    error.value = null;
    try {
      await _repository.createPayment(
        customerId: customerId,
        amount: amount,
        description: description,
      );
      await load();
      return true;
    } catch (e) {
      error.value = '$e';
      return false;
    } finally {
      saving.value = false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _repository.deletePayment(id);
      await load();
      return true;
    } catch (e) {
      error.value = '$e';
      return false;
    }
  }

  @override
  void onClose() {
    _realtime?.dispose();
    super.onClose();
  }
}
