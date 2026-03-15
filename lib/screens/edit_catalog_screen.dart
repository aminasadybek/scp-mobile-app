import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/user_provider.dart';
import '../models/product.dart';

class EditCatalogScreen extends StatefulWidget {
  const EditCatalogScreen({super.key});

  @override
  State<EditCatalogScreen> createState() => _EditCatalogScreenState();
}

class _EditCatalogScreenState extends State<EditCatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Provider.of<ProductProvider>(context, listen: false).loadProducts();
      } catch (_) {}
    });
  }

  // -----------------------------
  // ADD / EDIT PRODUCT DIALOG
  // -----------------------------
  void _showAddEditDialog({Product? product}) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final supplierCtrl = TextEditingController(text: product?.supplierName ?? (userProvider.currentUser?.name ?? ''));
    final priceCtrl = TextEditingController(text: product?.price.toString() ?? '');
    final unitCtrl = TextEditingController(text: product?.unit ?? '');
    final stockCtrl = TextEditingController(text: product?.stockQuantity.toString() ?? '');
    final minOrderCtrl = TextEditingController(text: product?.minOrderQuantity.toString() ?? '');
    final supplierIdDefault = product != null
        ? product.supplierId.toString()
        : (userProvider.currentUser?.companyId != null && userProvider.currentUser!.companyId > 0
        ? userProvider.currentUser!.companyId.toString()
        : '1');
    final supplierIdCtrl = TextEditingController(text: supplierIdDefault);
    final imageCtrl = TextEditingController(text: product?.imageUrl ?? '');

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Edit Product'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
                TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier Name')),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
                TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit (kg, piece...)')),
                TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock Quantity'), keyboardType: TextInputType.number),
                TextField(controller: minOrderCtrl, decoration: const InputDecoration(labelText: 'Minimum Order'), keyboardType: TextInputType.number),
                TextField(controller: supplierIdCtrl, decoration: const InputDecoration(labelText: 'Supplier ID'), keyboardType: TextInputType.number),
                TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Image URL (optional)')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B8E23),
              ),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                final productProvider = Provider.of<ProductProvider>(context, listen: false);

                final newName = nameCtrl.text.trim();
                final newSupplier = supplierCtrl.text.trim();
                final newPrice = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final newUnit = unitCtrl.text.trim();
                final newStock = int.tryParse(stockCtrl.text.trim()) ?? 0;
                final newMinOrder = int.tryParse(minOrderCtrl.text.trim()) ?? 0;
                final newSupplierId = int.tryParse(supplierIdCtrl.text.trim()) ?? 0;
                final newImageUrl = imageCtrl.text.trim();

                if (newName.isEmpty || newSupplier.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name and supplier required')),
                  );
                  return;
                }

                if (product == null) {
                  // ADD product
                  final newId = productProvider.products.isEmpty
                      ? 1
                      : productProvider.products.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;

                  final newProduct = Product(
                    id: newId,
                    name: newName,
                    supplierName: newSupplier,
                    price: newPrice,
                    unit: newUnit,
                    stockQuantity: newStock,
                    minOrderQuantity: newMinOrder,
                    supplierId: newSupplierId,
                    imageUrl: newImageUrl,
                  );

                  // Correct add:
                  productProvider.addProduct(newProduct);

                } else {
                  // UPDATE product
                  final updated = Product(
                    id: product!.id,
                    name: newName,
                    supplierName: newSupplier,
                    price: newPrice,
                    unit: newUnit,
                    stockQuantity: newStock,
                    minOrderQuantity: newMinOrder,
                    supplierId: newSupplierId,
                    imageUrl: newImageUrl,
                  );

                  productProvider.updateProduct(updated);
                }

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF6B8E23),
              ),
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  // -----------------------------
  // CONFIRM DELETE
  // -----------------------------
  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final productProvider = Provider.of<ProductProvider>(context, listen: false);
              productProvider.deleteProduct(product.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    final role = (userProvider.currentUser?.role ?? '').toLowerCase();
    final isSales = role == 'sales_rep';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Catalog'),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: const Color(0xFF6B8E23),
      ),

      body: productProvider.products.isEmpty
          ? const Center(child: Text('No products available'))
          : ListView.builder(
        itemCount: productProvider.products.length,
        itemBuilder: (_, i) {
          final p = productProvider.products[i];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(p.name),
              subtitle: Text(
                '${p.supplierName}\n'
                    'Price: ${p.price} ₸ per ${p.unit}\n'
                    'Stock: ${p.stockQuantity} | Min Order: ${p.minOrderQuantity}',
              ),
              isThreeLine: true,
              trailing: isSales
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showAddEditDialog(product: p),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _confirmDelete(p),
                  ),
                ],
              )
                  : null,
            ),
          );
        },
      ),

      floatingActionButton: isSales
          ? FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: const Color(0xFF6B8E23),
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}
