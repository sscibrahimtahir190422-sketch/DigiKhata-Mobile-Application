class StockMovement {
  const StockMovement({
    required this.id,
    required this.delta,
    required this.quantityAfter,
    required this.reason,
    required this.createdAt,
  });
  final String id;
  final double delta;
  final double quantityAfter;
  final String reason;
  final DateTime createdAt;

  factory StockMovement.fromJson(Map<String, dynamic> json) => StockMovement(
    id: json['id'] as String,
    delta: (json['delta'] as num).toDouble(),
    quantityAfter: (json['quantity_after'] as num).toDouble(),
    reason: json['reason'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );
}
