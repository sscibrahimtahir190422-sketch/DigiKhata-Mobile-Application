import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/customers/models/customer.dart';
import '../../features/customers/repositories/customer_repositories.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<List<Customer>> getCustomers() => _listCustomers(archived: false);

  @override
  Future<List<Customer>> getArchivedCustomers() =>
      _listCustomers(archived: true);

  Future<List<Customer>> _listCustomers({required bool archived}) async {
    final shopId = _supabase.auth.currentUser?.id;
    if (shopId == null) throw AuthException('Please sign in.');
    const pageSize = 500;
    final result = <Customer>[];
    for (var offset = 0; ; offset += pageSize) {
      final rows = await _supabase
          .from('customers')
          .select('id,name,phone,is_archived')
          .eq('shop_id', shopId)
          .eq('is_archived', archived)
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + pageSize - 1);
      result.addAll(rows.map(Customer.fromJson));
      if (rows.length < pageSize) break;
    }
    return result;
  }

  @override
  Future<Customer> addCustomer(Customer customer) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to add customers.');
    }

    final response = await _supabase
        .from('customers')
        .insert({
          'shop_id': user.id,
          'name': customer.name.trim(),
          'phone': customer.phone.trim(),
        })
        .select('id, name, phone, is_archived')
        .single();

    return Customer.fromJson(response);
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to delete customers.');
    }

    await _supabase
        .from('customers')
        .delete()
        .eq('id', customerId)
        .eq('shop_id', user.id);
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to update customers.');
    }

    final response = await _supabase
        .from('customers')
        .update({'name': customer.name.trim(), 'phone': customer.phone.trim()})
        .eq('id', customer.id)
        .eq('shop_id', user.id)
        .select('id, name, phone, is_archived')
        .single();

    return Customer.fromJson(response);
  }

  @override
  Future<void> archiveCustomer(String customerId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to archive customers.');
    }

    await _supabase
        .from('customers')
        .update({'is_archived': true})
        .eq('id', customerId)
        .eq('shop_id', user.id)
        .eq('is_archived', false);
  }

  @override
  Future<void> restoreCustomer(String customerId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to restore customers.');
    }

    await _supabase
        .from('customers')
        .update({'is_archived': false})
        .eq('id', customerId)
        .eq('shop_id', user.id)
        .eq('is_archived', true);
  }

  @override
  Future<Customer?> getCustomerById(String customerId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to view customer details.');
    }

    final response = await _supabase
        .from('customers')
        .select('id, name, phone, is_archived')
        .eq('id', customerId)
        .eq('shop_id', user.id)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Customer.fromJson(Map<String, dynamic>.from(response));
  }
}
