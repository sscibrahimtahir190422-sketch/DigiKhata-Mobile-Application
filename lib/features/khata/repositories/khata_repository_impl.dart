import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/khata_transaction.dart';
import 'khata_repository.dart';

class KhataRepositoryImpl implements KhataRepository {
  KhataRepositoryImpl(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<List<KhataTransaction>> getTransactions({
    required String customerId,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to view transactions.');
    }

    const pageSize = 500;
    final entries = <KhataTransaction>[];
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _supabase
          .from('khata_transactions')
          .select('id, customer_id, type, amount, description, created_at')
          .eq('shop_id', user.id)
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + pageSize - 1);
      entries.addAll(
        rows.map(
          (row) => KhataTransaction(
            id: row['id'] as String,
            customerId: row['customer_id'] as String,
            type: row['type'] as String,
            amount: (row['amount'] as num).toDouble(),
            description: row['description'] as String?,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        ),
      );
      if (rows.length < pageSize) break;
    }
    return entries;
  }

  @override
  Future<void> addTransaction({
    required String customerId,
    required String type,
    required double amount,
    String? description,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to add transactions.');
    }

    _validateTransaction(type: type, amount: amount);

    await _supabase.from('khata_transactions').insert({
      'shop_id': user.id,
      'customer_id': customerId,
      'type': type,
      'amount': amount,
      'description': _cleanDescription(description),
    });
  }

  @override
  Future<void> updateTransaction({
    required String transactionId,
    required String customerId,
    required String type,
    required double amount,
    String? description,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to update transactions.');
    }

    _validateTransaction(type: type, amount: amount);

    final response = await _supabase
        .from('khata_transactions')
        .update({
          'type': type,
          'amount': amount,
          'description': _cleanDescription(description),
        })
        .eq('id', transactionId)
        .eq('shop_id', user.id)
        .eq('customer_id', customerId)
        .select('id');

    if (response.isEmpty) {
      throw Exception(
        'No transaction was updated. Check the transaction ID, '
        'customer ID, shop ID, and Supabase UPDATE policy.',
      );
    }

    debugPrint('Transaction updated successfully: ${response.first['id']}');
  }

  @override
  Future<void> deleteTransaction({
    required String transactionId,
    required String customerId,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to delete transactions.');
    }

    await _supabase
        .from('khata_transactions')
        .delete()
        .eq('id', transactionId)
        .eq('shop_id', user.id)
        .eq('customer_id', customerId);
  }

  void _validateTransaction({required String type, required double amount}) {
    if (type != 'credit' && type != 'payment') {
      throw ArgumentError('Transaction type must be credit or payment.');
    }

    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }
  }

  String? _cleanDescription(String? description) {
    final cleaned = description?.trim();

    if (cleaned == null || cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }
}
