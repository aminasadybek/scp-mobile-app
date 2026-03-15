import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../screens/supplier_links_screen.dart';
import 'consumer_home_screen.dart';
import 'dart:async';
import 'sales_rep_home_screen.dart';
import 'profile_sales_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Product> _searchProducts = [];
  List<String> _searchSuppliers = [];

  Timer? _debounce;

  // Keep the same supplier name → id map you used for supplier boxes
  final Map<String, int> _supplierIds = {
    'ROYAL FLOWERS Co.': 10,
    'Fresh Dairy': 11,
    'Global Meats': 12,
    'Ocean Catch': 13,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
      Provider.of<SupplierLinkProvider>(context, listen: false).loadMockLinks();
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      setState(() => _searchQuery = query);

      if (query.isEmpty) {
        setState(() {
          _searchProducts = [];
          _searchSuppliers = [];
        });
        return;
      }

      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final supplierLinkProvider = Provider.of<SupplierLinkProvider>(context, listen: false);
      final connectedSupplierIds = supplierLinkProvider.connectedSuppliers.map((l) => l.supplierId).toList();
      final qLower = query.toLowerCase();

      final matchedProducts = productProvider.products.where((p) {
        return (p.name.toLowerCase().contains(qLower) || p.supplierName.toLowerCase().contains(qLower))
            && connectedSupplierIds.contains(p.supplierId);
      }).toList();

      final matchedSuppliers = _supplierIds.keys
          .where((name) => name.toLowerCase().contains(qLower))
          .toList();

      setState(() {
        _searchProducts = matchedProducts;
        _searchSuppliers = matchedSuppliers;
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchProducts = [];
      _searchSuppliers = [];
    });
  }

  // Reuse your existing _buildSupplierBox and _buildProductCard methods below.
  // If you prefer showing product detail on tap, replace the SnackBar nav with your product detail route.
  void _onTapProduct(Product product) {
    // If out of stock, notify the user and return
    if (product.stockQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product is out of stock'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);

    // Add to cart
    cartProvider.addToCart(product);

    // Show same snackbar pattern you used elsewhere
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.name} to cart', style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF6B8E23),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            navigationProvider.navigateToCart();
          },
        ),
      ),
    );
  }


  void _onTapSupplier(String supplierName) {
    final supplierId = _supplierIds[supplierName] ?? -1;
    if (supplierId == -1) return;

    final supplierLinkProvider = Provider.of<SupplierLinkProvider>(
        context, listen: false);
    final bool hasAccess = supplierLinkProvider.connectedSuppliers
        .any((link) => link.supplierId == supplierId);

    if (!hasAccess) {
      // show same dialog you used before
      showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(
              title: const Text('No approved link'),
              content: const Text(
                  "You can't open the catalog since you don't have an approved link."),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK')),
              ],
            ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierLinksScreen(supplierId: supplierId),
      ),
    );
  }

  Widget _buildSupplierBox(String name, String category, IconData icon) {
    final supplierLinkProvider =
    Provider.of<SupplierLinkProvider>(context, listen: false);

    // Hardcode a mapping from supplier name → supplierId
    final Map<String, int> supplierIds = {
      'ROYAL FLOWERS Co.': 10,
      'Fresh Dairy': 11,
      'Global Meats': 12,
      'Ocean Catch': 13,
    };

    final int supplierId = supplierIds[name] ?? -1;

    final bool hasAccess = supplierLinkProvider.connectedSuppliers
        .any((link) => link.supplierId == supplierId);

    return GestureDetector(
      onTap: () {
        // If supplierId is invalid show an info dialog
        if (supplierId == -1) {
          showDialog(
            context: context,
            builder: (_) =>
                AlertDialog(
                  title: const Text('Supplier not found'),
                  content: const Text('This supplier is not recognized.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK')),
                  ],
                ),
          );
          return;
        }

        // If no connected link -> show the message box
        if (!hasAccess) {
          showDialog(
            context: context,
            builder: (_) =>
                AlertDialog(
                  title: const Text('No approved link'),
                  content: const Text(
                      "You can't open the catalog since you don't have an approved link."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
          return;
        }

        // Has access -> navigate to SupplierLinksScreen passing supplierId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SupplierLinksScreen(supplierId: supplierId),
          ),
        );
      },

      child: Container(
        width: 150,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF6B8E23).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6B8E23),
                size: 40,
              ),
            ),
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(
                  horizontal: 6.0, vertical: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      height: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF6B8E23).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF6B8E23).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Icon(Icons.shopping_bag, color: Color(0xFF6B8E23)),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              product.supplierName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${product.price.toStringAsFixed(0)} ₸',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B8E23),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'per ${product.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (product.stockQuantity > 0)
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'In stock: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF787A77),
                      ),
                    ),
                    TextSpan(
                      text: '${product.stockQuantity}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B8E23),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF6B8E23),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            onPressed: () {
              cartProvider.addToCart(product);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Added ${product.name} to cart',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0xFF6B8E23),
                  action: SnackBarAction(
                    label: 'VIEW CART',
                    textColor: Colors.white,
                    onPressed: () {
                      navigationProvider.navigateToCart();
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBox(String category, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6B8E23),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6B8E23),
                  const Color(0xFF6B8E23).withOpacity(0.8),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;


    final productProvider = Provider.of<ProductProvider>(context);
    final supplierLinkProvider = Provider.of<SupplierLinkProvider>(context);

    final connectedSupplierIds = supplierLinkProvider.connectedSuppliers
        .map((link) => link.supplierId)
        .toList();

    final filteredProducts = productProvider.products
        .where((product) => connectedSupplierIds.contains(product.supplierId))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CaterChain Marketplace'),
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,),
        actions: [
          if (userProvider.isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  userProvider.currentUser?.name.substring(0, 1) ?? 'U',
                  style: const TextStyle(
                    color: Color(0xFF6B8E23),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: productProvider.isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF6B8E23)))
          : (_searchQuery.isNotEmpty)
          ? _buildSearchResultsView()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------
            // SEARCH FIELD + RESULTS
            // -------------------------
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search suppliers, products, or categories',
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) {
                            // optional: focus out or do something on submit
                          },
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: _clearSearch,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0),
                            child: Icon(
                                Icons.clear, size: 20, color: Colors.grey[600]),
                          ),
                        ),
                    ],
                  ),
                ),

                // Live results box
                if (_searchQuery.isNotEmpty)
                  const SizedBox(height: 8),

                if (_searchQuery.isNotEmpty)
                  Container(
                    // cap max height so it doesn't grow too large
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery
                          .of(context)
                          .size
                          .height * 0.4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03),
                            blurRadius: 6),
                      ],
                    ),
                    child: _searchProducts.isEmpty && _searchSuppliers.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('No results for "$_searchQuery"'),
                    )
                        : ListView(
                      shrinkWrap: true,
                      children: [
                        if (_searchSuppliers.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            child: Text('Suppliers', style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700])),
                          ),
                          ..._searchSuppliers.map((s) {
                            return ListTile(
                              leading: const Icon(Icons.storefront_outlined),
                              title: Text(s),
                              onTap: () => _onTapSupplier(s),
                            );
                          }).toList(),
                          const Divider(height: 1),
                        ],

                        if (_searchProducts.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            child: Text('Products', style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700])),
                          ),
                          ..._searchProducts.map((p) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                              child: _buildProductCard(p, context),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24.0),

            const Text(
              'Featured Suppliers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),

            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildSupplierBox('ROYAL FLOWERS Co.', 'Flowers',
                      Icons.local_florist_outlined),
                  const SizedBox(width: 12),
                  _buildSupplierBox('Fresh Dairy', 'Dairy Products',
                      Icons.agriculture_outlined),
                  const SizedBox(width: 12),
                  _buildSupplierBox(
                      'Global Meats', 'Meat Products', Icons.set_meal_outlined),
                  const SizedBox(width: 12),
                  _buildSupplierBox(
                      'Ocean Catch', 'Seafood', Icons.waves_outlined),
                ],
              ),
            ),

            // ... rest of the widget tree unchanged (Featured Products / Categories)
            const SizedBox(height: 24.0),

            const Text(
              'Featured Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),

            if (connectedSupplierIds.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.link_off, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text(
                        'No connected suppliers yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Go to Profile → Supplier Links to connect',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              if (filteredProducts.isNotEmpty)
                Column(
                  children: filteredProducts.map((product) {
                    return _buildProductCard(product, context);
                  }).toList(),
                )
              else
                const Text('No products available from connected suppliers'),

            const SizedBox(height: 24.0),

            const Text(
              'Popular Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16.0),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildCategoryBox(
                    'Wholesale Goods', Icons.inventory_2_outlined),
                _buildCategoryBox('Raw Materials', Icons.construction_outlined),
                _buildCategoryBox(
                    'Beverages', Icons.emoji_food_beverage_outlined),
                _buildCategoryBox('Fresh Produce', Icons.grass_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsView() {
    return SafeArea(
      child: Column(
        children: [
          // Top search bar (keeps same look and allows clearing)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search suppliers, products, or categories',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Results header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Results for "$_searchQuery"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Result list
          Expanded(
            child: (_searchProducts.isEmpty && _searchSuppliers.isEmpty)
                ? Center(child: Text('No results for "$_searchQuery"'))
                : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              children: [
                if (_searchSuppliers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 4.0),
                    child: Text('Suppliers', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  ),
                  ..._searchSuppliers.map((s) {
                    return ListTile(
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(s),
                      onTap: () => _onTapSupplier(s),
                    );
                  }).toList(),
                  const Divider(height: 1),
                ],

                if (_searchProducts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 4.0),
                    child: Text('Products', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                  ),
                  ..._searchProducts.map((p) {
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B8E23).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shopping_bag, color: Color(0xFF6B8E23)),
                      ),
                      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(p.supplierName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text('${p.price.toStringAsFixed(0)} ₸'),
                      onTap: () => _onTapProduct(p),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addProductToCart(Product product) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);

    // Add to cart
    cartProvider.addToCart(product);

    // Show same snackbar pattern you used elsewhere
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${product.name} to cart', style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF6B8E23),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            navigationProvider.navigateToCart();
          },
        ),
      ),
    );
  }

}

