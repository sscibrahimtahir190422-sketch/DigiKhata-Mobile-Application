import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer.dart';
import '../repositories/customer_repositories.dart';

class CustomerViewModel extends GetxController {
  CustomerViewModel(this._repository);

  final CustomerRepository _repository;

  final customers = <Customer>[].obs;
  final archivedCustomers = <Customer>[].obs;

  final isLoading = false.obs;
  final isArchivedLoading = false.obs;
  final errorMessage = RxnString();
  final archivedErrorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      customers.assignAll(await _repository.getCustomers());
    } catch (_) {
      errorMessage.value = 'Unable to load customers.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadArchivedCustomers() async {
    isArchivedLoading.value = true;
    archivedErrorMessage.value = null;

    try {
      archivedCustomers.assignAll(await _repository.getArchivedCustomers());
    } catch (error) {
      archivedErrorMessage.value = 'Unable to load archived customers: $error';
    } finally {
      isArchivedLoading.value = false;
    }
  }

  Future<bool> addCustomer({
    required String name,
    required String phone,
  }) async {
    errorMessage.value = null;

    final customer = Customer(id: '', name: name.trim(), phone: phone.trim());

    try {
      final savedCustomer = await _repository.addCustomer(customer);
      customers.add(savedCustomer);
      return true;
    } catch (_) {
      errorMessage.value = 'Unable to add customer.';
      return false;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    errorMessage.value = null;

    try {
      await _repository.deleteCustomer(customerId);
      customers.removeWhere((customer) => customer.id == customerId);
      return true;
    } on PostgrestException catch (error) {
      if (error.code == '23503') {
        errorMessage.value =
            'This customer has credit or payment history and cannot '
            'be deleted. Archive this customer instead.';
      } else {
        errorMessage.value = 'Unable to delete customer. Please try again.';
      }
      return false;
    } catch (_) {
      errorMessage.value = 'Unable to delete customer. Please try again.';
      return false;
    }
  }

  Future<bool> archiveCustomer(String customerId) async {
    errorMessage.value = null;

    try {
      await _repository.archiveCustomer(customerId);
      customers.removeWhere((customer) => customer.id == customerId);
      return true;
    } catch (_) {
      errorMessage.value = 'Unable to archive customer. Please try again.';
      return false;
    }
  }

  Future<bool> restoreCustomer(String customerId) async {
    archivedErrorMessage.value = null;

    try {
      await _repository.restoreCustomer(customerId);

      final restoredCustomer = archivedCustomers.firstWhereOrNull(
        (customer) => customer.id == customerId,
      );

      archivedCustomers.removeWhere((customer) => customer.id == customerId);

      if (restoredCustomer != null) {
        customers.insert(0, restoredCustomer.copyWith(isArchived: false));
      }

      return true;
    } catch (_) {
      archivedErrorMessage.value =
          'Unable to restore customer. Please try again.';
      return false;
    }
  }

  Future<bool> updateCustomer({
    required String id,
    required String name,
    required String phone,
  }) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final updatedCustomer = await _repository.updateCustomer(
        Customer(id: id, name: name.trim(), phone: phone.trim()),
      );

      final index = customers.indexWhere((customer) => customer.id == id);

      if (index != -1) {
        customers[index] = updatedCustomer;
      }

      return true;
    } catch (_) {
      errorMessage.value = 'Unable to update customer.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
