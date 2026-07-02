class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final double costPrice;
  final int stockGudang;
  final int stockDisplay;
  final int minStock;
  final int maxStock;
  final String emoji;
  final double discountPercent;
  final String sku;
  final String unit;
  final String unit2;
  final int unit2Conversion;
  final double unit2Price;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.costPrice = 0.0,
    required this.stockGudang,
    required this.stockDisplay,
    required this.minStock,
    required this.maxStock,
    required this.emoji,
    this.discountPercent = 0.0,
    this.sku = '',
    this.unit = 'Pcs',
    this.unit2 = '',
    this.unit2Conversion = 0,
    this.unit2Price = 0.0,
  });

  int get totalStock => stockGudang + stockDisplay;

  bool get hasUnit2 => unit2.isNotEmpty && unit2Conversion > 0;

  double get marginPercent {
    if (costPrice <= 0 || price <= 0) return 0.0;
    return ((price - costPrice) / price) * 100;
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'].toString(),
      name: map['name'],
      category: map['category'],
      price: (map['price'] as num).toDouble(),
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      stockGudang: map['stockGudang'] as int,
      stockDisplay: map['stockDisplay'] as int,
      minStock: map['minStock'] as int,
      maxStock: map['maxStock'] as int,
      emoji: map['emoji'],
      discountPercent: (map['discountPercent'] as num?)?.toDouble() ?? 0.0,
      sku: map['sku'] as String? ?? '',
      unit: map['unit'] as String? ?? 'Pcs',
      unit2: map['unit2'] as String? ?? '',
      unit2Conversion: (map['unit2Conversion'] as num?)?.toInt() ?? 0,
      unit2Price: (map['unit2Price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'costPrice': costPrice,
      'stockGudang': stockGudang,
      'stockDisplay': stockDisplay,
      'minStock': minStock,
      'maxStock': maxStock,
      'emoji': emoji,
      'discountPercent': discountPercent,
      'sku': sku,
      'unit': unit,
      'unit2': unit2,
      'unit2Conversion': unit2Conversion,
      'unit2Price': unit2Price,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    double? costPrice,
    int? stockGudang,
    int? stockDisplay,
    int? minStock,
    int? maxStock,
    String? emoji,
    double? discountPercent,
    String? sku,
    String? unit,
    String? unit2,
    int? unit2Conversion,
    double? unit2Price,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stockGudang: stockGudang ?? this.stockGudang,
      stockDisplay: stockDisplay ?? this.stockDisplay,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      emoji: emoji ?? this.emoji,
      discountPercent: discountPercent ?? this.discountPercent,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      unit2: unit2 ?? this.unit2,
      unit2Conversion: unit2Conversion ?? this.unit2Conversion,
      unit2Price: unit2Price ?? this.unit2Price,
    );
  }
}

class CartItem {
  final Product product;
  int quantity;
  double customDiscountPercent;
  double customDiscountAmount;
  String selectedUnit;
  int conversionQty;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.customDiscountPercent = 0.0,
    this.customDiscountAmount = 0.0,
    String? selectedUnit,
    int? conversionQty,
  })  : selectedUnit = selectedUnit ?? product.unit,
        conversionQty = conversionQty ?? 1;

  double get baseUnitPrice =>
      selectedUnit == product.unit2 ? product.unit2Price : product.price;

  double get unitPriceAfterDiscount {
    double price = baseUnitPrice;
    // Apply product default discount if exists, or custom
    double pct = customDiscountPercent > 0 ? customDiscountPercent : product.discountPercent;

    double afterPct = price - (price * (pct / 100));
    double finalPrice = afterPct - customDiscountAmount;
    return finalPrice < 0 ? 0 : finalPrice;
  }

  double get subtotal => unitPriceAfterDiscount * quantity;
}
