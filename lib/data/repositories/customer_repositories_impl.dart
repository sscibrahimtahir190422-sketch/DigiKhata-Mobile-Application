import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/customers/models/customer.dart';
import '../../features/customers/repositories/customer_repositories.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(this._supabase);

  final SupabaseClient _supabase;

  @override
  Future<List<Customer>> getCustomers() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to view customers.');
    }

    final response = await _supabase
        .from('customers')
        .select('id, name, phone, is_archived')
        .eq('shop_id', user.id)
        .eq('is_archived', false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => Customer.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Customer>> getArchivedCustomers() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final response = await _supabase
        .from('customers')
        .select('id, name, phone, is_archived')
        .eq('shop_id', user.id)
        .eq('is_archived', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Customer.fromJson(Map<String, dynamic>.from(item)))
        .toList();
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
