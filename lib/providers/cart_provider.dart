import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.price * quantity;

  // map convert
  Map<String, dynamic> toMap() {
    return {
      'product_id': product.id,
      'product_name': product.name,
      'price': product.price,
      'quantity': quantity,
      'image_url': product.imageUrl,
      'unit': product.unit,
    };
  }

  // cartitem
  factory CartItem.fromMap(Map<String, dynamic> map, Product product) {
    return CartItem(
      product: product,
      quantity: map['quantity'] ?? 1,
    );
  }
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = false;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get hasItems => _items.isNotEmpty;
  bool get isLoading => _isLoading;

  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // upload cart
  Future<void> loadCartFromDatabase() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> cartMaps =
      await _databaseHelper.getCartItems();

      _items.clear();

      for (var map in cartMaps) {
        // for product details
        final product = Product(
          id: map['product_id'] ?? 0,
          name: map['product_name'] ?? 'Unknown Product',
          supplierName: '',
          price: (map['price'] ?? 0.0).toDouble(),
          unit: map['unit'] ?? 'kg',
          stockQuantity: 100,
          minOrderQuantity: 1,
          supplierId: 1,
          imageUrl: map['image_url'] ?? '',
        );

        _items.add(CartItem.fromMap(map, product));
      }

      print('✅ Loaded ${_items.length} items from storage');
    } catch (error) {
      print('❌ Error loading cart: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // cart save
  Future<void> _saveCartToStorage() async {
    try {
      final List<Map<String, dynamic>> itemsMap =
      _items.map((item) => item.toMap()).toList();
      await _databaseHelper.saveCartItems(itemsMap);
    } catch (error) {
      print('❌ Error saving cart: $error');
    }
  }

  // product add
  Future<void> addToCart(Product product, [int quantity = 1]) async {
    try {
      final index = _items.indexWhere((item) => item.product.id == product.id);

      if (index >= 0) {
        _items[index].quantity += quantity;
      } else {
        _items.add(CartItem(product: product, quantity: quantity));
      }

      await _saveCartToStorage();
      notifyListeners();
      _showSuccessSnackBar('${product.name} добавлен в корзину');
    } catch (error) {
      print('❌ Error adding to cart: $error');
    }
  }

  // product remove
  Future<void> removeFromCart(int productId) async {
    try {
      _items.removeWhere((item) => item.product.id == productId);
      await _saveCartToStorage();
      notifyListeners();
      _showSuccessSnackBar('Товар удален из корзины');
    } catch (error) {
      print('❌ Error removing item: $error');
    }
  }

  // product remove with dialog
  void showRemoveConfirmationDialog(int productId, BuildContext context) {
    final item = _items.firstWhere((item) => item.product.id == productId);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удалить товар?'),
          content: Text('Вы уверены, что хотите удалить "${item.product.name}" из корзины?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                removeFromCart(productId);
              },
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // count update
  Future<void> updateQuantity(int productId, int newQuantity) async {
    try {
      final index = _items.indexWhere((item) => item.product.id == productId);
      if (index >= 0) {
        if (newQuantity > 0) {
          _items[index].quantity = newQuantity;
        } else {
          await removeFromCart(productId);
          return;
        }
        await _saveCartToStorage();
        notifyListeners();
      }
    } catch (error) {
      print('❌ Error updating quantity: $error');
    }
  }

  // count increase
  Future<void> increaseQuantity(int productId) async {
    await updateQuantity(productId, getQuantity(productId) + 1);
  }

  // count decrease
  Future<void> decreaseQuantity(int productId) async {
    await updateQuantity(productId, getQuantity(productId) - 1);
  }

  // clear cart with dialog
  void clearCartWithConfirmation(BuildContext context) {
    if (_items.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Очистить корзину'),
          content: const Text('Вы уверены, что хотите удалить все товары из корзины?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                clearCart();
              },
              child: const Text('Очистить все', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // clear cart
  Future<void> clearCart() async {
    try {
      await _databaseHelper.clearCart();
      _items.clear();
      notifyListeners();
      _showSuccessSnackBar('Корзина очищена');
    } catch (error) {
      print('❌ Error clearing cart: $error');
    }
  }

  // is in cart
  bool isInCart(int productId) {
    return _items.any((item) => item.product.id == productId);
  }

  // get quantity
  int getQuantity(int productId) {
    final item = _items.firstWhere(
          (item) => item.product.id == productId,
      orElse: () => CartItem(
          product: Product(
            id: 0, name: '', supplierName: '', price: 0, unit: '',
            stockQuantity: 0, minOrderQuantity: 0, supplierId: 0, imageUrl: '',
          ),
          quantity: 0
      ),
    );
    return item.quantity;
  }

  void _showSuccessSnackBar(String message) {
    print('✅ $message');
  }
}