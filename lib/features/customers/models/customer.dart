class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String phone;
  final bool isArchived;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'phone': phone, 'is_archived': isArchived};
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    bool? isArchived,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
