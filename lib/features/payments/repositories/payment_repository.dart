import '../../customers/models/customer.dart';
import '../models/payment_record.dart';

abstract interface class PaymentRepository {
  Future<List<PaymentRecord>> listPayments();
  Future<List<Customer>> listCustomers();
  Future<void> createPayment({
    required String customerId,
    required double amount,
    String? description,
  });
  Future<void> deletePayment(String id);
}
