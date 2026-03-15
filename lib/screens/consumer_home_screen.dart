import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../screens/supplier_links_screen.dart';

class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Product> _searchProducts = [];

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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() => _searchQuery = query);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final supplierLinkProvider = Provider.of<SupplierLinkProvider>(context, listen: false);
    final connectedSupplierIds = supplierLinkProvider.connectedSuppliers.map((l) => l.supplierId).toList();
    final qLower = query.toLowerCase();
    final matchedProducts = productProvider.products.where((p) {
      return (p.name.toLowerCase().contains(qLower) || p.supplierName.toLowerCase().contains(qLower))
          && connectedSupplierIds.contains(p.supplierId);
    }).toList();
    setState(() {
      _searchProducts = matchedProducts;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchProducts = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final supplierLinkProvider = Provider.of<SupplierLinkProvider>(context);
    final connectedSupplierIds = supplierLinkProvider.connectedSuppliers.map((link) => link.supplierId).toList();

    // Show products from connected suppliers
    final filteredProducts = productProvider.products.where((product) => connectedSupplierIds.contains(product.supplierId)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CaterChain Marketplace'),
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B8E23)))
          : (_searchQuery.isNotEmpty)
          ? _buildSearchResultsView()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Featured Products',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16.0),
            if (filteredProducts.isNotEmpty)
              Column(
                children: filteredProducts.map((product) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B8E23).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF6B8E23).withOpacity(0.3), width: 1),
                        ),
                        child: const Icon(Icons.shopping_bag, color: Color(0xFF6B8E23)),
                      ),
                      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      subtitle: Text(product.supplierName, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text('${product.price.toStringAsFixed(0)} ₸'),
                    ),
                  );
                }).toList(),
              )
            else
              const Text('No products available from connected suppliers'),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsView() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(12.0), border: Border.all(color: Colors.grey[300]!)),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(controller: _searchController, decoration: const InputDecoration(hintText: 'Search products', hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none, isDense: true)),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(onTap: _clearSearch, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Icon(Icons.clear, size: 20, color: Colors.grey[600]))),
                ],
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Align(alignment: Alignment.centerLeft, child: Text('Results for "$_searchQuery"', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 8),
          Expanded(
            child: (_searchProducts.isEmpty)
                ? Center(child: Text('No results for "$_searchQuery"'))
                : ListView(padding: const EdgeInsets.symmetric(horizontal: 8.0), children: _searchProducts.map((p) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFF6B8E23).withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF6B8E23).withOpacity(0.3), width: 1)), child: const Icon(Icons.shopping_bag, color: Color(0xFF6B8E23))),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text(p.supplierName, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text('${p.price.toStringAsFixed(0)} ₸'),
                ),
              );
            }).toList()),
          ),
        ],
      ),
    );
  }
}
