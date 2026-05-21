class Product {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String emoji;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.emoji,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;
}

const List<Product> dummyProducts = [
  Product(id: '1', name: 'Kopi Arabika', category: 'Minuman', price: 25000, stock: 50, emoji: '☕'),
  Product(id: '2', name: 'Teh Tarik', category: 'Minuman', price: 18000, stock: 40, emoji: '🍵'),
  Product(id: '3', name: 'Jus Alpukat', category: 'Minuman', price: 22000, stock: 30, emoji: '🥑'),
  Product(id: '4', name: 'Es Lemon Tea', category: 'Minuman', price: 15000, stock: 60, emoji: '🍋'),
  Product(id: '5', name: 'Cappuccino', category: 'Minuman', price: 30000, stock: 45, emoji: '🧋'),
  Product(id: '6', name: 'Air Mineral', category: 'Minuman', price: 5000, stock: 100, emoji: '💧'),
  Product(id: '7', name: 'Nasi Goreng', category: 'Makanan', price: 35000, stock: 20, emoji: '🍳'),
  Product(id: '8', name: 'Mie Ayam', category: 'Makanan', price: 28000, stock: 25, emoji: '🍜'),
  Product(id: '9', name: 'Roti Bakar', category: 'Makanan', price: 20000, stock: 35, emoji: '🍞'),
  Product(id: '10', name: 'Sandwich', category: 'Makanan', price: 32000, stock: 15, emoji: '🥪'),
  Product(id: '11', name: 'Salad Bowl', category: 'Makanan', price: 38000, stock: 12, emoji: '🥗'),
  Product(id: '12', name: 'Pisang Goreng', category: 'Snack', price: 12000, stock: 50, emoji: '🍌'),
  Product(id: '13', name: 'Kentang Goreng', category: 'Snack', price: 18000, stock: 40, emoji: '🍟'),
  Product(id: '14', name: 'Donat', category: 'Snack', price: 10000, stock: 30, emoji: '🍩'),
  Product(id: '15', name: 'Kue Lapis', category: 'Snack', price: 8000, stock: 25, emoji: '🍰'),
  Product(id: '16', name: 'Keripik', category: 'Snack', price: 15000, stock: 60, emoji: '🥨'),
];
