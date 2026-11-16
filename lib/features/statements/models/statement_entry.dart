class StatementEntry {
  const StatementEntry({
    required this.transactionId,
    required this.date,
    required this.type,
    required this.amount,
    this.description,
  });

  final String transactionId;
  final DateTime date;
  final String type;
  final double amount;
  final String? description;

  bool get isCredit => type.toLowerCase() == 'credit';

  bool get isPayment => type.toLowerCase() == 'payment';
}
