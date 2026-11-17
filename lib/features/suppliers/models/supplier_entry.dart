class SupplierEntry {
  const SupplierEntry({
    required this.id,
    required this.supplierId,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.description,
  });

  final String id;
  final String supplierId;
  final String type; // 'purchase' = Udhar; 'payment' = Jama
  final double amount;
  final DateTime createdAt;
  final String? description;

  bool get isPurchase => type == 'purchase';
  bool get isPayment => type == 'payment';
  double get signedAmount => isPurchase ? amount : -amount;

  factory SupplierEntry.fromJson(Map<String, dynamic> json) => SupplierEntry(
    id: json['id'] as String,
    supplierId: json['supplier_id'] as String,
    type: json['type'] as String,
    amount: (json['amount'] as num).toDouble(),
    createdAt: DateTime.parse(json['created_at'] as String),
    description: json['description'] as String?,
  );
}
