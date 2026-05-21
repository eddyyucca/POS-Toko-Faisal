class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stockGudang;
  final int stockDisplay;
  final int minStock;
  final int maxStock;
  final String emoji;
  final double discountPercent;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stockGudang,
    required this.stockDisplay,
    required this.minStock,
    required this.maxStock,
    required this.emoji,
    this.discountPercent = 0.0,
  });

  int get totalStock => stockGudang + stockDisplay;

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'].toString(),
      name: map['name'],
      category: map['category'],
      price: (map['price'] as num).toDouble(),
      stockGudang: map['stockGudang'] as int,
      stockDisplay: map['stockDisplay'] as int,
      minStock: map['minStock'] as int,
      maxStock: map['maxStock'] as int,
      emoji: map['emoji'],
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'stockGudang': stockGudang,
      'stockDisplay': stockDisplay,
      'minStock': minStock,
      'maxStock': maxStock,
      'emoji': emoji,
      'discountPercent': discountPercent,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    int? stockGudang,
    int? stockDisplay,
    int? minStock,
    int? maxStock,
    String? emoji,
    double? discountPercent,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stockGudang: stockGudang ?? this.stockGudang,
      stockDisplay: stockDisplay ?? this.stockDisplay,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      emoji: emoji ?? this.emoji,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }
}

class CartItem {
  final Product product;
  int quantity;
  double customDiscountPercent;
  double customDiscountAmount;

  CartItem({
    required this.product, 
    this.quantity = 1,
    this.customDiscountPercent = 0.0,
    this.customDiscountAmount = 0.0,
  });

  double get unitPriceAfterDiscount {
    double price = product.price;
    // Apply product default discount if exists, or custom
    double pct = customDiscountPercent > 0 ? customDiscountPercent : product.discountPercent;
    
    double afterPct = price - (price * (pct / 100));
    double finalPrice = afterPct - customDiscountAmount;
    return finalPrice < 0 ? 0 : finalPrice;
  }

  double get subtotal => unitPriceAfterDiscount * quantity;
}
