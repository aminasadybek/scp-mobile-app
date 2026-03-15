import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _cartKey = 'cart_items';
  static const String _userKey = 'user_data';
  static const String _productsKey = 'products_data';

  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // cart
  Future<void> saveCartItems(List<Map<String, dynamic>> items) async {
    final prefs = await _prefs;
    await prefs.setString(_cartKey, json.encode(items));
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final prefs = await _prefs;
    final String? cartJson = prefs.getString(_cartKey);

    if (cartJson != null) {
      try {
        final List<dynamic> jsonList = json.decode(cartJson);
        return jsonList.cast<Map<String, dynamic>>();
      } catch (e) {
        print('Error parsing cart data: $e');
      }
    }

    return [];
  }

  Future<void> clearCart() async {
    final prefs = await _prefs;
    await prefs.remove(_cartKey);
  }

  // products
  Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    final prefs = await _prefs;
    await prefs.setString(_productsKey, json.encode(products));
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final prefs = await _prefs;
    final String? productsJson = prefs.getString(_productsKey);

    if (productsJson != null) {
      try {
        final List<dynamic> jsonList = json.decode(productsJson);
        return jsonList.cast<Map<String, dynamic>>();
      } catch (e) {
        print('Error parsing products data: $e');
      }
    }

    return [];
  }

  // user
  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await _prefs;
    await prefs.setString(_userKey, json.encode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await _prefs;
    final String? userJson = prefs.getString(_userKey);

    if (userJson != null) {
      try {
        return json.decode(userJson);
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }

    return null;
  }

  Future<void> logoutUser() async {
    final prefs = await _prefs;
    await prefs.remove(_userKey);
  }
}