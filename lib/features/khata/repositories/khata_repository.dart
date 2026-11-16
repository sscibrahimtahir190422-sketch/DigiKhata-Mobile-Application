import '../models/khata_transaction.dart';

abstract interface class KhataRepository {
  Future<List<KhataTransaction>> getTransactions({required String customerId});

  Future<void> addTransaction({
    required String customerId,
    required String type,
    required double amount,
    String? description,
  });

  Future<void> updateTransaction({
    required String transactionId,
    required String customerId,
    required String type,
    required double amount,
    String? description,
  });

  Future<void> deleteTransaction({
    required String transactionId,
    required String customerId,
  });
}
