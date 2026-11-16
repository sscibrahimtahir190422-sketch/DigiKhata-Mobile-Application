import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../customers/models/customer.dart';
import '../models/khata_transaction.dart';
import '../models/transaction_reciept.dart';
import '../repositories/khata_repository.dart';

enum TransactionDateFilter { allTime, today, last7Days, last30Days, custom }

class KhataViewModel extends GetxController {
  KhataViewModel(this._repository, this.customerId);

  final KhataRepository _repository;
  final String customerId;

  final transactions = <KhataTransaction>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  final dateFilter = TransactionDateFilter.allTime.obs;
  final customStartDate = Rxn<DateTime>();
  final customEndDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
  }

  double get totalCredit => transactions
      .where((transaction) => transaction.isCredit)
      .fold(0.0, (total, transaction) => total + transaction.amount);

  double get totalPayments => transactions
      .where((transaction) => transaction.isPayment)
      .fold(0.0, (total, transaction) => total + transaction.amount);

  double get outstandingBalance => totalCredit - totalPayments;

  /// Creates a receipt using the selected transaction and customer.
  ///
  /// The historical balance is calculated from transactions up to and
  /// including the selected transaction, independent of the date filter.
  TransactionReceipt createReceipt({
    required KhataTransaction transaction,
    required Customer customer,
    String shopName = 'DigiKhata',
  }) {
    if (customer.id != customerId || transaction.customerId != customerId) {
      throw ArgumentError(
        'The customer and transaction must belong to this account.',
      );
    }

    final orderedTransactions = transactions.toList()
      ..sort((a, b) {
        final dateComparison = a.createdAt.compareTo(b.createdAt);

        if (dateComparison != 0) {
          return dateComparison;
        }

        // Deterministic ordering for transactions with identical timestamps.
        return a.id.compareTo(b.id);
      });

    final selectedIndex = orderedTransactions.indexWhere(
      (item) => item.id == transaction.id,
    );

    if (selectedIndex == -1) {
      throw StateError(
        'Transaction not found in the loaded transaction history.',
      );
    }

    double balanceAfterTransaction = 0;

    for (var i = 0; i <= selectedIndex; i++) {
      final item = orderedTransactions[i];

      if (item.isCredit) {
        balanceAfterTransaction += item.amount;
      } else if (item.isPayment) {
        balanceAfterTransaction -= item.amount;
      }
    }

    final selectedTransaction = orderedTransactions[selectedIndex];

    return TransactionReceipt(
      shopName: shopName,
      customerName: customer.name,
      customerPhone: customer.phone,
      transactionId: selectedTransaction.id,
      transactionType: selectedTransaction.type,
      amount: selectedTransaction.amount,
      transactionDate: selectedTransaction.createdAt,
      description: selectedTransaction.description,
      balanceAfterTransaction: balanceAfterTransaction,
    );
  }

  List<KhataTransaction> get filteredTransactions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? start;
    DateTime? end;

    switch (dateFilter.value) {
      case TransactionDateFilter.allTime:
        break;

      case TransactionDateFilter.today:
        start = today;
        end = today.add(const Duration(days: 1));

      case TransactionDateFilter.last7Days:
        start = today.subtract(const Duration(days: 6));
        end = today.add(const Duration(days: 1));

      case TransactionDateFilter.last30Days:
        start = today.subtract(const Duration(days: 29));
        end = today.add(const Duration(days: 1));

      case TransactionDateFilter.custom:
        final selectedStart = customStartDate.value;
        final selectedEnd = customEndDate.value;

        if (selectedStart == null || selectedEnd == null) {
          return transactions.toList();
        }

        start = DateTime(
          selectedStart.year,
          selectedStart.month,
          selectedStart.day,
        );

        end = DateTime(
          selectedEnd.year,
          selectedEnd.month,
          selectedEnd.day,
        ).add(const Duration(days: 1));
    }

    if (start == null || end == null) {
      return transactions.toList();
    }

    return transactions.where((transaction) {
      final date = transaction.createdAt.toLocal();
      return !date.isBefore(start!) && date.isBefore(end!);
    }).toList();
  }

  double get filteredCredit => filteredTransactions
      .where((transaction) => transaction.isCredit)
      .fold(0.0, (total, transaction) => total + transaction.amount);

  double get filteredPayments => filteredTransactions
      .where((transaction) => transaction.isPayment)
      .fold(0.0, (total, transaction) => total + transaction.amount);

  String get dateFilterLabel {
    switch (dateFilter.value) {
      case TransactionDateFilter.allTime:
        return 'All time';
      case TransactionDateFilter.today:
        return 'Today';
      case TransactionDateFilter.last7Days:
        return 'Last 7 days';
      case TransactionDateFilter.last30Days:
        return 'Last 30 days';
      case TransactionDateFilter.custom:
        final start = customStartDate.value;
        final end = customEndDate.value;

        if (start == null || end == null) {
          return 'Custom range';
        }

        return '${_formatDate(start)} - ${_formatDate(end)}';
    }
  }

  void setDateFilter(TransactionDateFilter filter) {
    dateFilter.value = filter;
  }

  Future<void> selectCustomDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    if (end.isBefore(start)) {
      errorMessage.value = 'End date cannot be before start date.';
      return;
    }

    customStartDate.value = start;
    customEndDate.value = end;
    dateFilter.value = TransactionDateFilter.custom;
    errorMessage.value = null;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> loadTransactions() async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _repository.getTransactions(customerId: customerId);

      transactions.assignAll(result);
    } catch (e, stackTrace) {
      _logError('LOAD TRANSACTIONS', e, stackTrace);
      errorMessage.value = 'Unable to load transactions: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addTransaction({
    required String type,
    required double amount,
    String? description,
  }) async {
    if (isSaving.value) return false;

    isSaving.value = true;
    errorMessage.value = null;

    try {
      await _repository.addTransaction(
        customerId: customerId,
        type: type,
        amount: amount,
        description: description,
      );

      await _refreshAfterMutation();
      return true;
    } catch (e, stackTrace) {
      _logError('ADD TRANSACTION', e, stackTrace);
      errorMessage.value = 'Unable to save transaction: $e';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateTransaction({
    required String transactionId,
    required String type,
    required double amount,
    String? description,
  }) async {
    if (isSaving.value) return false;

    isSaving.value = true;
    errorMessage.value = null;

    try {
      await _repository.updateTransaction(
        transactionId: transactionId,
        customerId: customerId,
        type: type,
        amount: amount,
        description: description,
      );

      await _refreshAfterMutation();
      return true;
    } catch (e, stackTrace) {
      _logError('UPDATE TRANSACTION', e, stackTrace);
      errorMessage.value = 'Unable to update transaction: $e';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteTransaction({required String transactionId}) async {
    if (isSaving.value) return false;

    isSaving.value = true;
    errorMessage.value = null;

    try {
      await _repository.deleteTransaction(
        transactionId: transactionId,
        customerId: customerId,
      );

      await _refreshAfterMutation();
      return true;
    } catch (e, stackTrace) {
      _logError('DELETE TRANSACTION', e, stackTrace);
      errorMessage.value = 'Unable to delete transaction: $e';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _refreshAfterMutation() async {
    final result = await _repository.getTransactions(customerId: customerId);

    transactions.assignAll(result);
  }

  void _logError(String operation, Object error, StackTrace stackTrace) {
    debugPrint('========== $operation ERROR ==========');
    debugPrint('Error type: ${error.runtimeType}');
    debugPrint('Error details: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
