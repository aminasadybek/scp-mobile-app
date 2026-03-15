import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'package:hive/hive.dart';
import '../models/complaint.dart';
import '../models/complaint_adapter.dart';


class ComplaintProvider with ChangeNotifier {
  List<Complaint> _complaints = [];
  bool _isLoading = false;
  String? _errorMessage;

  ComplaintProvider() {
    loadComplaints();
  }

  // (old helper removed) Use loadComplaints() to fetch from ApiService and sync Hive.

  void _saveToHive() {
    final box = Hive.box<Complaint>('complaints');
    // persist full list: clear and re-add to keep hive in sync
    box.clear();
    for (var c in _complaints) {
      box.add(c);
    }
  }

  List<Complaint> get complaints => List.unmodifiable(_complaints);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Complaint> get openComplaints =>
      _complaints.where((c) => c.status == 'open' || c.status == 'in_progress').toList();

  List<Complaint> get resolvedComplaints =>
      _complaints.where((c) => c.status == 'resolved').toList();

  List<Complaint> get closedComplaints =>
      _complaints.where((c) => c.status == 'closed').toList();

  Future<void> loadComplaints() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apiComplaints = await ApiService.getComplaints();

      if (apiComplaints.isNotEmpty) {
        _complaints = apiComplaints.map((m) => Complaint.fromJson(m)).toList();

        // persist to Hive box
        final box = Hive.box<Complaint>('complaints');
        box.clear();
        for (var c in _complaints) {
          box.add(c);
        }
      } else {
        final box = Hive.box<Complaint>('complaints');
        if (box.isNotEmpty) {
          _complaints = box.values.toList();
        } else {
          loadMockComplaints();
          for (var c in _complaints) {
            box.add(c);
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // on error, fall back to Hive-backed data or mock list
      final box = Hive.box<Complaint>('complaints');
      if (box.isNotEmpty) {
        _complaints = box.values.toList();
      } else {
        loadMockComplaints();
        for (var c in _complaints) {
          box.add(c);
        }
      }

      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // create complaint
  Future<bool> createComplaint({
    required int orderId,
    required String description,
    String? priority,
  }) async {
    try {
      final result = await ApiService.createComplaint(
        orderId: orderId,
        description: description,
      );

      final newComplaint = Complaint(
        id: result['id'] ?? DateTime.now().millisecond,
        orderId: orderId,
        consumerId: result['consumer_id'] ?? 1,
        supplierId: result['supplier_id'] ?? 1,
        description: description,
        status: 'open',
        createdAt: DateTime.now(),
        priority: priority,
      );

      _complaints.insert(0, newComplaint);
      _saveToHive();

      try {
        await loadComplaints();
      } catch (_) {}

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // get complaint by id
  Complaint? getComplaintById(int id) {
    try {
      return _complaints.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // get complaints by order id
  List<Complaint> getComplaintsByOrder(int orderId) {
    return _complaints.where((c) => c.orderId == orderId).toList();
  }

  // clear complaint error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // mock complaints for testing
  void loadMockComplaints() {
    _complaints = [
      Complaint(
        id: 1,
        orderId: 100,
        consumerId: 1,
        supplierId: 1,
        description: 'Items arrived damaged. Some tomatoes were rotten.',
        status: 'in_progress',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        assignedTo: 'manager',
        priority: 'high',
      ),
      Complaint(
        id: 2,
        orderId: 101,
        consumerId: 1,
        supplierId: 2,
        description: 'Delivery delayed by 3 hours.',
        status: 'resolved',
        resolution: 'Applied 10% discount to next order',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 4)),
        priority: 'medium',
      ),
      Complaint(
        id: 3,
        orderId: 102,
        consumerId: 1,
        supplierId: 1,
        description: 'Wrong quantity delivered - received 5kg instead of 10kg',
        status: 'open',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        priority: 'critical',
      ),
    ];
    notifyListeners();
  }

  /// update complaint
  Future<bool> updateComplaint({
    required int id,
    String? status,
    String? priority,
    String? resolution,
  }) async {
    try {
      final idx = _complaints.indexWhere((c) => c.id == id);
      if (idx == -1) return false;

      final old = _complaints[idx];
      // If complaint is closed, clear priority (no priority for closed complaints)
      final effectivePriority = (status == 'closed') ? null : (priority ?? old.priority);

      final updated = Complaint(
        id: old.id,
        orderId: old.orderId,
        consumerId: old.consumerId,
        supplierId: old.supplierId,
        description: old.description,
        status: status ?? old.status,
        resolution: resolution ?? old.resolution,
        createdAt: old.createdAt,
        resolvedAt: resolution != null ? DateTime.now() : old.resolvedAt,
        assignedTo: old.assignedTo,
        priority: effectivePriority,
      );

      _complaints[idx] = updated;
      _saveToHive();

      // Also update mock storage in SharedPreferences so mocks stay in sync
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = 'mock_complaints';
        final saved = prefs.getString(key);
        final list = saved != null
            ? (json.decode(saved) as List<dynamic>).cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];

        final sidx = list.indexWhere((c) => c['id'] == id);
        if (sidx != -1) {
          final map = Map<String, dynamic>.from(list[sidx]);
          if (status != null) map['status'] = status;
          // if status is closed, ensure priority is cleared
          if (status == 'closed') {
            map['priority'] = null;
          } else if (priority != null) {
            map['priority'] = priority;
          }
          if (resolution != null) {
            map['resolution'] = resolution;
            map['resolved_at'] = DateTime.now().toIso8601String();
            if (status == null) map['status'] = 'resolved';
          }
          list[sidx] = map;
          await prefs.setString(key, json.encode(list));
        }
      } catch (e) {
        // ignore prefs sync error
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
