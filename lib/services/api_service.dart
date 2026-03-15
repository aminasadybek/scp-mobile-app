import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'package:hive/hive.dart';
import '../database/database_helper.dart';

class ApiService {
  static Future<bool> registerUser({required String name, required String email, required String password, String phone = '', String role = 'consumer', int companyId = 0}) async {
    var usersBox = Hive.box<User>('users');
    if (usersBox.values.any((u) => u.email == email)) {
      return false;
    }
    String? inviteCode;
    if (role == User.ROLE_SALES_REP) {
      inviteCode = companyId.toString();
    }
    final user = User(
      id: usersBox.length + 1,
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
      companyId: companyId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      inviteCode: inviteCode,
    );
    await usersBox.add(user);
    return true;
  }

  static Future<User?> loginUser(String email, String password) async {
    var usersBox = Hive.box<User>('users');
    for (var u in usersBox.values) {
      print('User: email=${u.email}, password=${u.password}');
    }
    try {
      final user = usersBox.values.firstWhere((u) =>
      u.email.trim().toLowerCase() == email.trim().toLowerCase() &&
          u.password == password
      );
      return user;
    } catch (e) {
      try {
        print('ApiService.loginUser error: $e');
      } catch (_) {}
      return null;
    }
  }
  static const String baseUrl = 'http://localhost:8000/api'; // Измени на реальный URL
  static String? _authToken;
  static bool useMock = true;

  static const String _mockUsersKey = 'mock_users';
  static const String _mockChatsKey = 'mock_chats';
  static const String _mockComplaintsKey = 'mock_complaints';
  static const String _mockOrdersKey = 'mock_orders';

  static final DatabaseHelper _db = DatabaseHelper();

  static String? get authToken => _authToken;
  static void setAuthToken(String token) {
    _authToken = token;
  }

  static void clearAuthToken() {
    _authToken = null;
  }

  static Future<SharedPreferences> _prefs() async => await SharedPreferences.getInstance();

  static Future<Map<String, dynamic>?> _getSavedUserMap() async {
    return await _db.getUser();
  }

  static Future<Map<String, dynamic>?> getSavedUserMap() async {
    return await _getSavedUserMap();
  }

  static Map<String, String> _getHeaders({bool requireAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requireAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> registerConsumer({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String companyName,
  }) async {
    if (useMock) {
      final prefs = await _prefs();
      await prefs.remove(_mockUsersKey);
      await _db.logoutUser();

      final List<dynamic> users = [];


      final newId = DateTime.now().millisecondsSinceEpoch;
      final token = 'mock-token-$newId';

      final userMap = {
        'id': newId,
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': 'consumer',
        'company_id': 1,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      users.add(userMap);
      await prefs.setString(_mockUsersKey, json.encode(users));

      // persist ONLY the last registered user as current
      await _db.saveUser(userMap);
      _authToken = token;

      return {'user': userMap, 'token': token};
    }

    // fallback to network
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/consumer'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'company_name': companyName,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          setAuthToken(data['token']);
        }
        return data;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (useMock) {
      final prefs = await _prefs();
      await _db.logoutUser();

      final List<dynamic> users = prefs.getString(_mockUsersKey) != null
          ? json.decode(prefs.getString(_mockUsersKey)!) as List<dynamic>
          : [];

      final found = users.cast<Map<String, dynamic>>().firstWhere(
              (u) => u['email'] == email && u['password'] == password,
          orElse: () => {});

      if (found.isEmpty) throw Exception('Invalid credentials');

      final token = 'mock-token-${found['id']}';
      _authToken = token;

      // persist logged-in user to DatabaseHelper
      await _db.saveUser(found);

      return {'user': found, 'token': token};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          setAuthToken(data['token']);
        }
        return data;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  static Future<User> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data['user']);
      } else {
        throw Exception('Failed to get user');
      }
    } catch (e) {
      throw Exception('Get user error: $e');
    }
  }

  /// Logout
  static Future<void> logout() async {
    if (useMock) {
      clearAuthToken();
      try {
        await _db.logoutUser();
      } catch (e) {
        print('Mock logout db clear error: $e');
      }
      return;
    }

    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _getHeaders(requireAuth: true),
      );
    } catch (e) {
      print('Logout error: $e');
    } finally {
      clearAuthToken();
    }
  }

  static Future<List<Map<String, dynamic>>> getSupplierLinks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/supplier-links'),
        headers: _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['links'] ?? []);
      } else {
        throw Exception('Failed to get supplier links');
      }
    } catch (e) {
      throw Exception('Get links error: $e');
    }
  }

  static Future<Map<String, dynamic>> requestSupplierLink({
    required int supplierId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/supplier-links/request'),
        headers: _getHeaders(requireAuth: true),
        body: jsonEncode({
          'supplier_id': supplierId,
          'message': message,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Request failed');
      }
    } catch (e) {
      throw Exception('Request link error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getProducts({int? supplierId}) async {
    try {
      String url = '$baseUrl/products';
      if (supplierId != null) {
        url += '?supplier_id=$supplierId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['products'] ?? []);
      } else {
        throw Exception('Failed to get products');
      }
    } catch (e) {
      throw Exception('Get products error: $e');
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required int supplierId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    if (useMock) {
      final savedUser = await _getSavedUserMap();
      if (savedUser == null) throw Exception('Not authenticated');

      final existingOrders = savedUser['orders'] != null
          ? (json.decode(savedUser['orders']) as List<dynamic>)
          : <dynamic>[];

      final newOrderId = DateTime.now().millisecondsSinceEpoch;
      final orderMap = {
        'id': newOrderId,
        'status': 'submitted',
        'consumerId': savedUser['id'],
        'supplierId': supplierId,
        'totalAmount': items.fold(0.0, (sum, it) => sum + (it['unit_price'] ?? 0) * (it['quantity'] ?? 1)),
        'notes': notes,
        'submittedAt': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'items': items,
      };

      existingOrders.insert(0, orderMap);
      savedUser['orders'] = json.encode(existingOrders);
      await _db.saveUser(savedUser);

      return {'order': orderMap};
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: _getHeaders(requireAuth: true),
        body: jsonEncode({
          'supplier_id': supplierId,
          'items': items,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Order creation failed');
      }
    } catch (e) {
      throw Exception('Create order error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getOrders() async {
    if (useMock) {
      final savedUser = await _getSavedUserMap();
      if (savedUser == null) return [];
      if (savedUser['orders'] == null) return [];
      try {
        final orders = json.decode(savedUser['orders']) as List<dynamic>;
        return orders.cast<Map<String, dynamic>>();
      } catch (e) {
        return [];
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['orders'] ?? []);
      } else {
        throw Exception('Failed to get orders');
      }
    } catch (e) {
      throw Exception('Get orders error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getChats() async {
    if (useMock) {
      final prefs = await _prefs();
      if (prefs.getString(_mockChatsKey) != null) {
        final saved = json.decode(prefs.getString(_mockChatsKey)!) as List<dynamic>;
        return saved.cast<Map<String, dynamic>>();
      }

      // initialize default mock chats
      final now = DateTime.now();
      final defaultChats = [
        {
          'id': 1,
          'supplier_id': 1,
          'supplier_name': 'Fresh Farm Supplies',
          'last_message': 'Great, thank you!',
          'last_message_at': now.subtract(const Duration(minutes: 30)).toIso8601String(),
          'unread_count': 0,
          'messages': [
            {
              'id': 1,
              'chat_id': 1,
              'sender_id': 100,
              'sender_name': 'Fresh Farm Supplies',
              'sender_role': 'sales',
              'message': 'Hello! Thanks for your order.',
              'sent_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
              'is_read': true,
            },
            {
              'id': 2,
              'chat_id': 1,
              'sender_id': 101,
              'sender_name': 'Fresh Farm Supplies',
              'sender_role': 'sales',
              'message': 'Let us know if you need anything else!',
              'sent_at': now.subtract(const Duration(hours: 1, minutes: 30)).toIso8601String(),
              'is_read': true,
            },
          ],
        },
        {
          'id': 2,
          'supplier_id': 2,
          'supplier_name': 'Organic Vegetables Co.',
          'last_message': 'Also — carrots will be available by Friday.',
          'last_message_at': now.subtract(const Duration(hours: 4)).toIso8601String(),
          'unread_count': 2,
          'messages': [
            {
              'id': 11,
              'chat_id': 2,
              'sender_id': 200,
              'sender_name': 'Organic Vegetables Co.',
              'sender_role': 'sales',
              'message': 'We have cucumbers in stock tomorrow.',
              'sent_at': now.subtract(const Duration(hours: 5)).toIso8601String(),
              'is_read': false,
            },
            {
              'id': 12,
              'chat_id': 2,
              'sender_id': 200,
              'sender_name': 'Organic Vegetables Co.',
              'sender_role': 'sales',
              'message': 'Also — carrots will be available by Friday.',
              'sent_at': now.subtract(const Duration(hours: 4, minutes: 20)).toIso8601String(),
              'is_read': false,
            },
          ],
        },
      ];

      await prefs.setString(_mockChatsKey, json.encode(defaultChats));
      return defaultChats.cast<Map<String, dynamic>>();
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chats'),
        headers: _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['chats'] ?? []);
      } else {
        throw Exception('Failed to get chats');
      }
    } catch (e) {
      throw Exception('Get chats error: $e');
    }
  }

  static Future<void> appendChat(Map<String, dynamic> chat) async {
    if (!useMock) return;
    final prefs = await _prefs();
    final saved = prefs.getString(_mockChatsKey);
    final chats = saved != null
        ? (json.decode(saved) as List<dynamic>).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    final idx = chats.indexWhere((c) => c['id'] == chat['id']);
    if (idx != -1) {
      chats[idx] = chat;
    } else {
      chats.add(chat);
    }

    await prefs.setString(_mockChatsKey, json.encode(chats));
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int chatId,
    required String message,
    String? fileUrl,
  }) async {
    if (useMock) {
      final prefs = await _prefs();
      final saved = prefs.getString(_mockChatsKey);
      if (saved == null) throw Exception('Chat not found');
      final chats = (json.decode(saved) as List<dynamic>).cast<Map<String, dynamic>>();

      final chatIndex = chats.indexWhere((c) => c['id'] == chatId);
      if (chatIndex == -1) throw Exception('Chat not found');

      final newMsgId = DateTime.now().millisecondsSinceEpoch;

      final savedUser = await _getSavedUserMap();
      final senderId = savedUser != null ? savedUser['id'] : 1;
      final senderName = savedUser != null ? (savedUser['name'] ?? 'You') : 'You';

      final senderRole = savedUser != null ? (savedUser['role'] ?? 'customer') : 'customer';

      final msgMap = {
        'id': newMsgId,
        'chat_id': chatId,
        'sender_id': senderId,
        'sender_name': senderName,
        'sender_role': senderRole,
        'message': message,
        'file_url': fileUrl,
        'sent_at': DateTime.now().toIso8601String(),
        'is_read': true,
      };

      chats[chatIndex]['messages'] = (chats[chatIndex]['messages'] as List<dynamic>)..add(msgMap);
      chats[chatIndex]['last_message'] = message;
      chats[chatIndex]['last_message_at'] = DateTime.now().toIso8601String();

      await prefs.setString(_mockChatsKey, json.encode(chats));

      return msgMap;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chats/$chatId/messages'),
        headers: _getHeaders(requireAuth: true),
        body: jsonEncode({
          'message': message,
          'file_url': fileUrl,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      throw Exception('Send message error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getMessages(int chatId) async {
    if (useMock) {
      final prefs = await _prefs();
      final saved = prefs.getString(_mockChatsKey);
      if (saved == null) return [];
      final chats = (json.decode(saved) as List<dynamic>).cast<Map<String, dynamic>>();
      final chat = chats.firstWhere((c) => c['id'] == chatId, orElse: () => {});
      if (chat.isEmpty) return [];
      return (chat['messages'] as List<dynamic>).cast<Map<String, dynamic>>();
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$chatId/messages'),
        headers: _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['messages'] ?? []);
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      throw Exception('Get messages error: $e');
    }
  }

  static Future<void> markChatRead(int chatId) async {
    if (!useMock) return;
    final prefs = await _prefs();
    final saved = prefs.getString(_mockChatsKey);
    if (saved == null) return;
    final chats = (json.decode(saved) as List<dynamic>).cast<Map<String, dynamic>>();
    final index = chats.indexWhere((c) => c['id'] == chatId);
    if (index == -1) return;

    final savedUser = await _getSavedUserMap();
    final currentUserId = savedUser != null ? savedUser['id'] : null;

    final msgs = (chats[index]['messages'] as List<dynamic>).cast<Map<String, dynamic>>();
    for (var i = 0; i < msgs.length; i++) {
      if (msgs[i]['sender_id'] != currentUserId) {
        msgs[i]['is_read'] = true;
      }
    }

    chats[index]['messages'] = msgs;
    chats[index]['unread_count'] = 0;

    await prefs.setString(_mockChatsKey, json.encode(chats));
  }

  static Future<Map<String, dynamic>> createComplaint({
    required int orderId,
    required String description,
  }) async {
    if (useMock) {
      final prefs = await _prefs();
      final savedComplaints = prefs.getString(_mockComplaintsKey);
      final complaints = savedComplaints != null
          ? (json.decode(savedComplaints) as List<dynamic>).cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];

      final savedUser = await _getSavedUserMap();
      final consumerId = savedUser != null ? savedUser['id'] : 1;

      final newComplaint = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'order_id': orderId,
        'consumer_id': consumerId,
        'supplier_id': 1,
        'description': description,
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      };

      complaints.insert(0, newComplaint);
      await prefs.setString(_mockComplaintsKey, json.encode(complaints));
      return newComplaint;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/complaints'),
        headers: _getHeaders(requireAuth: true),
        body: jsonEncode({
          'order_id': orderId,
          'description': description,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Complaint creation failed');
      }
    } catch (e) {
      throw Exception('Create complaint error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getComplaints() async {
    if (useMock) {
      final prefs = await _prefs();
      final saved = prefs.getString(_mockComplaintsKey);
      if (saved == null) return [];
      try {
        final complaints = (json.decode(saved) as List<dynamic>).cast<Map<String, dynamic>>();
        return complaints;
      } catch (e) {
        return [];
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/complaints'),
        headers: _getHeaders(requireAuth: true),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['complaints'] ?? []);
      } else {
        throw Exception('Failed to get complaints');
      }
    } catch (e) {
      throw Exception('Get complaints error: $e');
    }
  }
}
