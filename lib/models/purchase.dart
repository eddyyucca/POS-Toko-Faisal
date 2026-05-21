import 'product.dart';

class Purchase {
  final String id;
  final String date;
  final String supplierId;
  final double total;
  final String notes;
  final String userId;

  Purchase({
    required this.id,
    required this.date,
    required this.supplierId,
    required this.total,
    required this.notes,
    required this.userId,
  });

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      date: map['date'],
      supplierId: map['supplierId'],
      total: map['total'],
      notes: map['notes'],
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'supplierId': supplierId,
      'total': total,
      'notes': notes,
      'userId': userId,
    };
  }
}

class PurchaseItem {
  final String id;
  final String purchaseId;
  final String productId;
  final int qty;
  final double costPrice;
  
  // Optional, for UI rendering
  Product? product;

  PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.qty,
    required this.costPrice,
    this.product,
  });

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'],
      purchaseId: map['purchaseId'],
      productId: map['productId'],
      qty: map['qty'],
      costPrice: map['costPrice'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchaseId': purchaseId,
      'productId': productId,
      'qty': qty,
      'costPrice': costPrice,
    };
  }
}
