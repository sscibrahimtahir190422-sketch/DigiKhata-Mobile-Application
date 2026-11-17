class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String phone;
  final String? address;
  final bool isArchived;

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String? ?? '',
    address: json['address'] as String?,
    isArchived: json['is_archived'] as bool? ?? false,
  );
}
