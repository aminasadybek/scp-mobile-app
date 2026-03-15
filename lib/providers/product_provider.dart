import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../database/database_helper.dart';

// Provider for managing products

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  List<Product> get featuredProducts => _featuredProducts;
  bool get isLoading => _isLoading;

// Add a product
  void addProduct(Product newProduct) {
    _products.add(newProduct);
    // Recompute featured products and persist
    _featuredProducts = _products.take(2).toList();
    _saveProductsToDb();
    notifyListeners();
  }

// Update an existing product
  void updateProduct(Product updatedProduct) {
    final idx = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (idx != -1) {
      _products[idx] = updatedProduct;
      // Recompute featured
      _featuredProducts = _products.take(2).toList();
      _saveProductsToDb();
      notifyListeners();
    }
  }

// Delete product by id
  void deleteProduct(int id) {
    _products.removeWhere((p) => p.id == id);
    // Recompute featured
    _featuredProducts = _products.take(2).toList();
    _saveProductsToDb();
    notifyListeners();
  }


  // Load mock products for testing
  void loadMockProducts() {
    _isLoading = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      _products = [
        Product(
          id: 1,
          name: 'Fresh Red Tomatoes',
          supplierName: 'Organic Vegetables Co.',
          price: 1500.0,
          unit: 'kg',
          stockQuantity: 100,
          minOrderQuantity: 5,
          supplierId: 1,
          imageUrl: '',
        ),
        Product(
          id: 2,
          name: 'Potatoes',
          supplierName: 'Fresh Farm Supplies',
          price: 800.0,
          unit: 'kg',
          stockQuantity: 200,
          minOrderQuantity: 10,
          supplierId: 1,
          imageUrl: '',
        ),
        Product(
          id: 3,
          name: 'Carrots',
          supplierName: 'Fresh Farm Supplies',
          price: 1200.0,
          unit: 'kg',
          stockQuantity: 150,
          minOrderQuantity: 5,
          supplierId: 2,
          imageUrl: '',
        ),
      ];

      _featuredProducts = _products.take(2).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Product? getProductById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Product> getProductsBySupplier(int supplierId) {
    return _products.where((product) => product.supplierId == supplierId).toList();
  }

  // Persist current products to DB
  Future<void> _saveProductsToDb() async {
    try {
      final db = DatabaseHelper();
      final list = _products.map((p) => p.toJson()).toList();
      await db.saveProducts(list);
    } catch (e) {
      // ignore save errors for now
    }
  }

  // Load products from persistent storage; fallback to mock data
  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = DatabaseHelper();
      final saved = await db.getProducts();
      if (saved.isNotEmpty) {
        _products = saved.map((m) => Product.fromJson(m)).toList();
      } else {
        // load mocks and persist them
        _products = [
          Product(
            id: 1,
            name: 'Fresh Red Tomatoes',
            supplierName: 'Organic Vegetables Co.',
            price: 1500.0,
            unit: 'kg',
            stockQuantity: 100,
            minOrderQuantity: 5,
            supplierId: 1,
            imageUrl: '',
          ),
          Product(
            id: 2,
            name: 'Potatoes',
            supplierName: 'Fresh Farm Supplies',
            price: 800.0,
            unit: 'kg',
            stockQuantity: 200,
            minOrderQuantity: 10,
            supplierId: 1,
            imageUrl: '',
          ),
        ];
        await _saveProductsToDb();
      }

      _featuredProducts = _products.take(2).toList();
    } catch (e) {
      // ignore
    }

    _isLoading = false;
    notifyListeners();
  }
}