import 'package:supabase_flutter/supabase_flutter.dart';

import '../../customers/models/customer.dart';
import '../models/payment_record.dart';
import 'payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._client);
  final SupabaseClient _client;

  String get _shopId =>
      _client.auth.currentUser?.id ??
      (throw AuthException('Please sign in to manage payments.'));

  @override
  Future<List<Customer>> listCustomers() async {
    const pageSize = 500;
    final customers = <Customer>[];
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _client
          .from('customers')
          .select('id,name,phone,is_archived')
          .eq('shop_id', _shopId)
          .eq('is_archived', false)
          .order('name')
          .order('id')
          .range(offset, offset + pageSize - 1);
      customers.addAll(rows.map(Customer.fromJson));
      if (rows.length < pageSize) break;
    }
    return customers;
  }

  @override
  Future<List<PaymentRecord>> listPayments() async {
    final id = _shopId;
    const pageSize = 500;
    final names = <String, String>{};
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _client
          .from('customers')
          .select('id,name')
          .eq('shop_id', id)
          .order('id')
          .range(offset, offset + pageSize - 1);
      for (final row in rows) {
        names[row['id'] as String] = row['name'] as String;
      }
      if (rows.length < pageSize) break;
    }

    final payments = <PaymentRecord>[];
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _client
          .from('khata_transactions')
          .select('id,customer_id,amount,description,created_at')
          .eq('shop_id', id)
          .eq('type', 'payment')
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + pageSize - 1);
      payments.addAll(
        rows.map(
          (row) => PaymentRecord(
            id: row['id'] as String,
            customerId: row['customer_id'] as String,
            customerName: names[row['customer_id']] ?? 'Unknown customer',
            amount: (row['amount'] as num).toDouble(),
            description: row['description'] as String?,
            createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
          ),
        ),
      );
      if (rows.length < pageSize) break;
    }
    return payments;
  }

  @override
  Future<void> createPayment({
    required String customerId,
    required double amount,
    String? description,
  }) async {
    if (!amount.isFinite ||
        amount <= 0 ||
        amount > 999999999.99 ||
        (amount * 100 - (amount * 100).round()).abs() > 0.000001) {
      throw ArgumentError('Enter a valid amount with up to two decimals.');
    }
    await _client.from('khata_transactions').insert({
      'shop_id': _shopId,
      'customer_id': customerId,
      'type': 'payment',
      'amount': amount,
      'description': description?.trim().isEmpty == true
          ? null
          : description?.trim(),
    });
  }

  @override
  Future<void> deletePayment(String id) async {
    final rows = await _client
        .from('khata_transactions')
        .delete()
        .eq('id', id)
        .eq('shop_id', _shopId)
        .eq('type', 'payment')
        .select('id');
    if (rows.isEmpty) throw StateError('Payment no longer exists.');
  }
}
