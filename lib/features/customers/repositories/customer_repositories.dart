import '../models/customer.dart';

abstract interface class CustomerRepository {
  Future<List<Customer>> getCustomers();

  Future<List<Customer>> getArchivedCustomers();

  Future<Customer> addCustomer(Customer customer);

  Future<Customer> updateCustomer(Customer customer);

  Future<void> deleteCustomer(String customerId);

  Future<void> archiveCustomer(String customerId);

  Future<void> restoreCustomer(String customerId);

  Future<Customer?> getCustomerById(String customerId);
}
