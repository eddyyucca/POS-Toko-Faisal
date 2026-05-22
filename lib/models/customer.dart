class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final int points;
  final double totalSpend;
  final String createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.points = 0,
    this.totalSpend = 0.0,
    required this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'].toString(),
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String? ?? '',
      points: map['points'] as int? ?? 0,
      totalSpend: (map['totalSpend'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'points': points,
      'totalSpend': totalSpend,
      'createdAt': createdAt,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    int? points,
    double? totalSpend,
    String? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      points: points ?? this.points,
      totalSpend: totalSpend ?? this.totalSpend,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
