class Supplier {
  final String id;
  final String name;
  final String phone;
  final String address;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
    };
  }
}
