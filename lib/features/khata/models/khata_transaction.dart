class KhataTransaction {
  const KhataTransaction({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  final String id;
  final String customerId;

  /// Either 'credit' or 'payment'.
  final String type;

  final double amount;
  final String? description;
  final DateTime createdAt;

  bool get isCredit => type == 'credit';

  bool get isPayment => type == 'payment';
}
