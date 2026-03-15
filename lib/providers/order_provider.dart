import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/order.dart';
import 'cart_provider.dart';
import '../database/database_helper.dart';

class OrderProvider with ChangeNotifier {
  final List<Order> _orders = [];
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = false;

  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;

  // create order from cart
  Future<Order?> createOrderFromCart(CartProvider cartProvider, {String? notes}) async {
    if (cartProvider.items.isEmpty) return null;

    try {
      _isLoading = true;
      notifyListeners();

      // add order items from cart
      final orderItems = cartProvider.items.map((cartItem) {
        return OrderItem(
          id: DateTime.now().millisecondsSinceEpoch,
          orderId: 0,
          productId: cartItem.product.id,
          quantity: cartItem.quantity,
          unitPrice: cartItem.product.price,
          lineTotal: cartItem.totalPrice,
        );
      }).toList();

      // create new order
      final newOrder = Order(
        id: DateTime.now().millisecondsSinceEpoch,
        status: 'submitted',
        consumerId: 1,
        supplierId: 1,
        totalAmount: cartProvider.totalAmount,
        notes: notes,
        submittedAt: DateTime.now(),
        createdAt: DateTime.now(),
        items: orderItems,
      );

      _orders.insert(0, newOrder);

      // clear cart after order creation
      await cartProvider.clearCart();

      // save orders to storage
      await _saveOrdersToStorage();

      _isLoading = false;
      notifyListeners();

      _showSuccess('Order created successfully!');
      return newOrder;

    } catch (error) {
      _isLoading = false;
      notifyListeners();
      _showError('Failed to create order: $error');
      return null;
    }
  }

  // load orders from storage
  Future<void> loadOrdersFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userData = await _databaseHelper.getUser();

      if (userData != null && userData['orders'] != null) {
        final ordersJson = json.decode(userData['orders']);
        _orders.clear();

        for (var orderJson in ordersJson) {
          try {
            final order = Order(
              id: orderJson['id'],
              status: orderJson['status'],
              consumerId: orderJson['consumerId'],
              supplierId: orderJson['supplierId'],
              totalAmount: (orderJson['totalAmount'] as num).toDouble(),
              notes: orderJson['notes'],
              submittedAt: orderJson['submittedAt'] != null ? DateTime.parse(orderJson['submittedAt']) : null,
              acceptedAt: orderJson['acceptedAt'] != null ? DateTime.parse(orderJson['acceptedAt']) : null,
              completedAt: orderJson['completedAt'] != null ? DateTime.parse(orderJson['completedAt']) : null,
              createdAt: orderJson['createdAt'] != null ? DateTime.parse(orderJson['createdAt']) : DateTime.now(),
              items: (orderJson['items'] as List).map((item) => OrderItem(
                id: item['id'],
                orderId: item['orderId'],
                productId: item['productId'],
                quantity: item['quantity'],
                unitPrice: (item['unitPrice'] as num).toDouble(),
                lineTotal: (item['lineTotal'] as num).toDouble(),
              )).toList(),
            );
            _orders.add(order);
          } catch (e) {
            print('❌ Error parsing order: $e');
          }
        }
      }

      print('✅ Orders loaded from storage: ${_orders.length}');
    } catch (error) {
      print('❌ Error loading orders: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // save orders to storage
  Future<void> _saveOrdersToStorage() async {
    try {
      final ordersJson = _orders.map((order) => {
        'id': order.id,
        'status': order.status,
        'consumerId': order.consumerId,
        'supplierId': order.supplierId,
        'totalAmount': order.totalAmount,
        'notes': order.notes,
        'submittedAt': order.submittedAt?.toIso8601String(),
        'acceptedAt': order.acceptedAt?.toIso8601String(),
        'completedAt': order.completedAt?.toIso8601String(),
        'createdAt': order.createdAt?.toIso8601String(),
        'items': order.items.map((item) => {
          'id': item.id,
          'orderId': item.orderId,
          'productId': item.productId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'lineTotal': item.lineTotal,
        }).toList(),
      }).toList();

      // save to user data
      final userData = await _databaseHelper.getUser() ?? {};
      userData['orders'] = json.encode(ordersJson);
      await _databaseHelper.saveUser(userData);

      print('💾 Orders saved to storage: ${_orders.length}');
    } catch (error) {
      print('❌ Error saving orders: $error');
    }
  }

  // show success message
  void _showSuccess(String message) {
    print('✅ $message');
  }

  void _showError(String message) {
    print('❌ $message');
  }

  // debug print orders
  void debugPrintOrders() {
    print('📦 Current orders in memory: ${_orders.length}');
    for (var order in _orders) {
      print('  - Order #${order.id}: ${order.status}, ${order.totalAmount} ₸, ${order.items.length} items');
    }
  }
}