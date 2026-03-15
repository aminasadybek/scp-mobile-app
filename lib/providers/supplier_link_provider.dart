import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class SupplierLink {
  final int id;
  final int consumerId;
  final int supplierId;
  final String supplierName;
  final String status; // pending, accepted, rejected, blocked
  final DateTime requestedAt;
  final DateTime? respondedAt;

  SupplierLink({
    required this.id,
    required this.consumerId,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.requestedAt,
    this.respondedAt,
  });

  factory SupplierLink.fromJson(Map<String, dynamic> json) {
    return SupplierLink(
      id: json['id'],
      consumerId: json['consumer_id'],
      supplierId: json['supplier_id'],
      supplierName: json['supplier_name'] ?? 'Unknown',
      status: json['status'] ?? 'pending',
      requestedAt: DateTime.parse(json['requested_at']),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'])
          : null,
    );
  }
}

class SupplierLinkProvider with ChangeNotifier {
  List<SupplierLink> _links = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SupplierLink> get links => List.unmodifiable(_links);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // get connected suppliers
  List<SupplierLink> get connectedSuppliers =>
      _links.where((link) => link.status == 'accepted').toList();

  // get pending requests
  List<SupplierLink> get pendingRequests =>
      _links.where((link) => link.status == 'pending').toList();

  // update links from API
  Future<void> loadLinks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final linksData = await ApiService.getSupplierLinks();
      _links = linksData.map((json) => SupplierLink.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  // send link request
  Future<bool> requestSupplierLink({
    required int supplierId,
    required String supplierName,
    required String message,
  }) async {
    try {
      final result = await ApiService.requestSupplierLink(
        supplierId: supplierId,
        message: message,
      );

      // add to links
      final newLink = SupplierLink(
        id: result['id'] ?? DateTime.now().millisecond,
        consumerId: result['consumer_id'] ?? 0,
        supplierId: supplierId,
        supplierName: supplierName,
        status: 'pending',
        requestedAt: DateTime.now(),
      );

      _links.add(newLink);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // check if connected to supplier
  bool isConnectedTo(int supplierId) {
    return connectedSuppliers.any((link) => link.supplierId == supplierId);
  }

  // check if there is a pending request to supplier
  bool hasPendingRequest(int supplierId) {
    return pendingRequests.any((link) => link.supplierId == supplierId);
  }

  // clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool _hasLoadedMock = false;

  // load mock links for testing
  void loadMockLinks() {
    if (_hasLoadedMock) return;
    _hasLoadedMock = true;

    _links = [
      SupplierLink(
        id: 1,
        consumerId: 1,
        supplierId: 1,
        supplierName: 'Fresh Farm Supplies',
        status: 'accepted',
        requestedAt: DateTime.now().subtract(const Duration(days: 5)),
        respondedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      SupplierLink(
        id: 2,
        consumerId: 1,
        supplierId: 2,
        supplierName: 'Organic Vegetables Co.',
        status: 'pending',
        requestedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    notifyListeners();
  }
}
