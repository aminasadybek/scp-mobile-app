import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  List<Chat> _chats = [];
  final Map<int, List<ChatMessage>> _chatMessages = {};
  int? _selectedChatId;
  bool _isLoading = false;
  String? _errorMessage;

  List<Chat> get chats => List.unmodifiable(_chats);

  List<ChatMessage> get selectedChatMessages {
    if (_selectedChatId == null) return [];
    return _chatMessages[_selectedChatId] ?? [];
  }

  // return messages for a given chat id
  List<ChatMessage> messagesFor(int chatId) {
    return _chatMessages[chatId] ?? [];
  }

  int? get selectedChatId => _selectedChatId;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  int get totalUnread => _chats.fold(0, (sum, chat) => sum + chat.unreadCount);

  Future<void> loadChats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final chatsData = await ApiService.getChats();
      _chats = chatsData.map((json) => Chat.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      print('ChatProvider.loadChats error: $e');
    }
  }

  Future<void> markChatAsRead(int chatId) async {
    // mark messages as read in-memory
    if (_chatMessages.containsKey(chatId)) {
      final msgs = _chatMessages[chatId]!;
      for (var i = 0; i < msgs.length; i++) {
        final m = msgs[i];
        if (!m.isRead) {
          msgs[i] = m.copyWith(isRead: true);
        }
      }
    }

    // reset unread count on chat summary in-memory
    final chatIndex = _chats.indexWhere((c) => c.id == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex].unreadCount = 0;
    }

    // persist read state to backend/mock so it doesn't reappear after reload
    try {
      await ApiService.markChatRead(chatId);
    } catch (e) {
      // ignore persistence errors — we still keep in-memory state
      print('markChatAsRead persistence error: $e');
    }

    notifyListeners();
  }

  Future<void> selectChat(int chatId) async {
    try {
      _selectedChatId = chatId;
      if (_chatMessages.containsKey(chatId)) {
        await markChatAsRead(chatId);
        notifyListeners();
        return;
      }
      await loadChatMessages(chatId);
      await markChatAsRead(chatId);
    } catch (e) {
      _selectedChatId = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadChatMessages(int chatId) async {
    try {
      // find chat object (must exist in _chats)
      final chat = _chats.firstWhere((c) => c.id == chatId);

      List<Map<String, dynamic>>? rawList;

      if (chat.rawJson != null &&
          chat.rawJson!['messages'] != null &&
          (chat.rawJson!['messages'] is List) &&
          (chat.rawJson!['messages'] as List).isNotEmpty) {
        rawList =
        List<Map<String, dynamic>>.from(chat.rawJson!['messages'] as List);
      }

      if (rawList == null || rawList.isEmpty) {
        try {
          final fetched = await ApiService.getMessages(chatId);
          if (fetched.isNotEmpty) {
            rawList = List<Map<String, dynamic>>.from(fetched);
          }
        } catch (e) {
          // ignore fetch error for future use of
        }
      }

      if (rawList != null && rawList.isNotEmpty) {
        _chatMessages[chatId] =
            rawList.map((m) =>
                ChatMessage.fromJson(Map<String, dynamic>.from(m))).toList();
      } else {
        if (_chatMessages.containsKey(chatId) &&
            _chatMessages[chatId]!.isNotEmpty) {
        } else {
          _chatMessages[chatId] = _generateMockMessages(chatId);
        }
      }

      // sort by sentAt
      _chatMessages[chatId]!.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      notifyListeners();
    } catch (e) {
      _chatMessages[chatId] = _generateMockMessages(chatId);
      _errorMessage = e.toString();
      notifyListeners();
    }
  }


  Future<bool> sendMessage(int chatId, String message,
      {String? fileUrl}) async {
    try {
      final localId = DateTime
          .now()
          .millisecondsSinceEpoch;
      final savedUser = await ApiService.getSavedUserMap();
      final curSenderId = savedUser != null ? (savedUser['id'] as int) : 1;
      final curSenderName = savedUser != null ? (savedUser['name'] ?? 'You') : 'You';
      final curSenderRole = savedUser != null
          ? roleFromString(savedUser['role'] as String?)
          : ConversationRole.customer;

      final tempMessage = ChatMessage(
        id: localId,
        chatId: chatId,
        senderId: curSenderId,
        senderName: curSenderName,
        senderRole: curSenderRole,
        message: message,
        fileUrl: fileUrl,
        audioUrl: null,
        sentAt: DateTime.now(),
        isRead: true,
        status: MessageStatus.sending,
      );

      _chatMessages.putIfAbsent(chatId, () => []);
      _chatMessages[chatId]!.add(tempMessage);
      notifyListeners();

      final result = await ApiService.sendMessage(
        chatId: chatId,
        message: message,
        fileUrl: fileUrl,
      );

      final sentMessage = tempMessage.copyWith(
        id: result['id'] ?? localId,
        senderId: result['sender_id'] ?? 1,
        senderName: result['sender_name'] ?? 'You',
        senderRole: roleFromString(result['sender_role'] as String?),
        status: MessageStatus.sent,
      );

      final msgIndex = _chatMessages[chatId]!.indexWhere((m) =>
      m.id == localId);
      if (msgIndex != -1) {
        _chatMessages[chatId]![msgIndex] = sentMessage;
      }

      // update chat summary
      final chatIndex = _chats.indexWhere((c) => c.id == chatId);
      if (chatIndex != -1) {
        final chat = _chats[chatIndex];
        chat.lastMessage = message;
        chat.lastMessageAt = DateTime.now();
        chat.unreadCount = 0;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');

      // mark last temp message as failed
      final chatMsgs = _chatMessages[chatId];
      if (chatMsgs != null && chatMsgs.isNotEmpty) {
        final last = chatMsgs.last;
        if (last.status == MessageStatus.sending) {
          final failed = last.copyWith(status: MessageStatus.failed);
          chatMsgs[chatMsgs.length - 1] = failed;
        }
      }

      notifyListeners();
      return false;
    }
  }

  Future<int> startChatWithSupplier(int supplierId, String supplierName) async {
    Chat? existingChat;

    for (final c in _chats) {
      if (c.supplierId == supplierId) {
        existingChat = c;
        break;
      }
    }

    if (existingChat != null) return existingChat.id;

    final newId = DateTime.now().millisecondsSinceEpoch;

    // build rawJson and consumer metadata from saved user
    Map<String, dynamic> raw = {
      'id': newId,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'messages': [],
    };

    int? consId;
    String? consName;
    try {
      final saved = await ApiService.getSavedUserMap();
      if (saved != null) {
        consId = saved['id'] is int ? saved['id'] as int : (saved['id'] != null ? int.parse('${saved['id']}') : null);
        consName = saved['name']?.toString();
        raw['consumer_id'] = consId;
        raw['consumer_name'] = consName;
        raw['consumer_role'] = saved['role'] ?? '';
      }
    } catch (_) {}

    final newChat = Chat(
      rawJson: raw,
      id: newId,
      supplierId: supplierId,
      supplierName: supplierName,
      consumerId: consId,
      consumerName: consName,
      lastMessage: 'Chat created',
      lastMessageAt: DateTime.now(),
      unreadCount: 0,
    );

    _chats.add(newChat);
    // persist the created chat to mock storage so ApiService.sendMessage can find it
    try {
      if (newChat.rawJson != null) await ApiService.appendChat(newChat.rawJson!);
    } catch (e) {
      print('Failed to persist new chat: $e');
    }

    notifyListeners();
    return newChat.id;
  }

  void markMessageAsRead(int chatId, int messageId) {
    if (_chatMessages.containsKey(chatId)) {
      final index = _chatMessages[chatId]!.indexWhere((m) => m.id == messageId);

      if (index != -1) {
        final msg = _chatMessages[chatId]![index];
        _chatMessages[chatId]![index] = msg.copyWith(isRead: true);
        notifyListeners();
      }
    }
  }

  void clearSelectedChat() {
    _selectedChatId = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // mock messages
  List<ChatMessage> _generateMockMessages(int chatId) {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: 1,
        chatId: chatId,
        senderId: 100,
        senderName: 'Fresh Farm Supplies',
        senderRole: ConversationRole.sales,
        message: 'Hello! Thanks for your order.',
        sentAt: now.subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      ChatMessage(
        id: 2,
        chatId: chatId,
        senderId: 101,
        senderName: 'Fresh Farm Supplies',
        senderRole: ConversationRole.sales,
        message: 'Let us know if you need anything else!',
        sentAt: now.subtract(const Duration(hours: 1, minutes: 30)),
        isRead: true,
      ),
    ];
  }

  // mock chats - load from ApiService so persistent mock storage is used
  Future<void> loadMockChats() async {
    try {
      final chatsData = await ApiService.getChats();
      _chats = chatsData.map((json) => Chat.fromJson(json)).toList();
    } catch (e) {
      print('loadMockChats fallback error: $e');
      _chats = [];
    }

    notifyListeners();
  }
}