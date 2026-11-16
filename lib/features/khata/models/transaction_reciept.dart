class TransactionReceipt {
  const TransactionReceipt({
    required this.shopName,
    required this.customerName,
    required this.customerPhone,
    required this.transactionId,
    required this.transactionType,
    required this.amount,
    required this.transactionDate,
    required this.description,
    required this.balanceAfterTransaction,
  });

  final String shopName;
  final String customerName;
  final String customerPhone;
  final String transactionId;
  final String transactionType;
  final double amount;
  final DateTime transactionDate;
  final String? description;
  final double balanceAfterTransaction;

  bool get isCredit => transactionType.toLowerCase() == 'credit';

  String get formattedAmount => 'PKR ${amount.toStringAsFixed(2)}';

  String get formattedBalance =>
      'PKR ${balanceAfterTransaction.toStringAsFixed(2)}';

  String toShareText() {
    final date =
        '${transactionDate.day.toString().padLeft(2, '0')}/'
        '${transactionDate.month.toString().padLeft(2, '0')}/'
        '${transactionDate.year}';

    final time =
        '${transactionDate.hour.toString().padLeft(2, '0')}:'
        '${transactionDate.minute.toString().padLeft(2, '0')}';

    final transactionLabel = isCredit ? 'Credit Added' : 'Payment Received';

    final details = description?.trim();

    return '''
DIGIKHATA
Customer Transaction Receipt
--------------------------------
Customer: $customerName
Phone: ${customerPhone.isEmpty ? 'Not provided' : customerPhone}
Transaction: $transactionLabel
Amount: $formattedAmount
Date: $date
Time: $time
${details != null && details.isNotEmpty ? 'Description: $details\n' : ''}Balance after transaction: $formattedBalance
Reference: $transactionId
--------------------------------
Thank you!
'''
        .trim();
  }
}
