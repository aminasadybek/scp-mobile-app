import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../utils/utils.dart';

class SupplierLinksScreen extends StatefulWidget {
  final int? supplierId;

  const SupplierLinksScreen({super.key, this.supplierId});

  @override
  State<SupplierLinksScreen> createState() => _SupplierLinksScreenState();
}

class _SupplierLinksScreenState extends State<SupplierLinksScreen> {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  bool _showPendingOnly = false;

  @override
  void initState() {
    super.initState();
    // Check whether the incoming supplierId (if any) has a connected/approved link.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkApprovedLink());
  }

  void openRequestDialogFromOutside(int supplierId) {
    _showRequestDialog(presetSupplierId: supplierId);
  }

  Future<void> _checkApprovedLink() async {
    try {
      final int? supplierId = widget.supplierId;
      if (supplierId == null) return;

      final linkProvider = Provider.of<SupplierLinkProvider>(context, listen: false);

      // Consider 'connectedSuppliers' as the source of truth for having access.
      final bool isConnected = linkProvider.connectedSuppliers.any((l) => l.supplierId == supplierId);

      if (!isConnected) {
        // If the supplier exists in pendingRequests we can show a more specific message.
        final bool isPending = linkProvider.pendingRequests.any((l) => l.supplierId == supplierId);

        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('No approved link'),
            content: Text(isPending
                ? "You can't open the catalog because your request is still pending approval."
                : "You can't open the catalog since you don't have an approved link."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Supplier Links'),
          titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          backgroundColor: const Color(0xFF6B8E23),
          foregroundColor: Colors.white,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Connected'),
              Tab(text: 'Pending'),
            ],
            labelColor: Colors.white,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            indicatorWeight: 3.0,
          ),
        ),
        body: Consumer<SupplierLinkProvider>(
          builder: (context, linkProvider, _) {
            return TabBarView(
              children: [
                _buildConnectedTab(linkProvider),
                _buildPendingTab(linkProvider),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showRequestDialog,
          backgroundColor: const Color(0xFF6B8E23),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildConnectedTab(SupplierLinkProvider linkProvider) {
    if (linkProvider.connectedSuppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No connected suppliers', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Request access to start ordering', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: linkProvider.connectedSuppliers.length,
      itemBuilder: (context, index) {
        final link = linkProvider.connectedSuppliers[index];
        return _buildSupplierCard(link, isConnected: true);
      },
    );
  }

  Widget _buildPendingTab(SupplierLinkProvider linkProvider) {
    if (linkProvider.pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No pending requests', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: linkProvider.pendingRequests.length,
      itemBuilder: (context, index) {
        final link = linkProvider.pendingRequests[index];
        return _buildSupplierCard(link, isConnected: false);
      },
    );
  }

  Widget _buildSupplierCard(SupplierLink link, {required bool isConnected}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B8E23).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store, color: Color(0xFF6B8E23)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(link.supplierName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('ID: ${link.supplierId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.schedule,
                  color: isConnected ? const Color(0xFF6B8E23) : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(isConnected ? 'Connected' : 'Pending approval', style: TextStyle(fontSize: 12, color: isConnected ? const Color(0xFF6B8E23) : Colors.orange, fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(_formatDate(link.requestedAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            if (isConnected) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B8E23)),
                  onPressed: () => _onViewProductsPressed(link),
                  child: const Text('View Products', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onViewProductsPressed(SupplierLink link) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening supplier catalog...')));
  }

  void _showRequestDialog({int? presetSupplierId}) {
    final supplierIdController = TextEditingController(text: presetSupplierId?.toString() ?? '');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Supplier Link'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the supplier ID to request access', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: supplierIdController,
                decoration: InputDecoration(
                  labelText: 'Supplier ID',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.message),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B8E23)),
              ),),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B8E23)),
            onPressed: () {
              if (supplierIdController.text.isEmpty) {
                ErrorHandler.showInfoSnackBar(context, 'Please enter a supplier ID');
                return;
              }

              final linkProvider = Provider.of<SupplierLinkProvider>(context, listen: false);

              try {
                linkProvider.requestSupplierLink(
                  supplierId: int.parse(supplierIdController.text),
                  supplierName: 'Supplier ${supplierIdController.text}',
                  message: _messageController.text.trim(),
                );

                _messageController.clear();
                supplierIdController.clear();
                Navigator.pop(context);

                ErrorHandler.showSuccessSnackBar(context, 'Request sent to supplier!');
              } catch (e) {
                ErrorHandler.showErrorSnackBar(context, e);
              }
            },
            child: const Text(
              'Send Request',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
