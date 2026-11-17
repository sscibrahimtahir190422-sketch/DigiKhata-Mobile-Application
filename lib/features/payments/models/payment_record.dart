class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.createdAt,
    this.description,
  });
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final DateTime createdAt;
  final String? description;
}
