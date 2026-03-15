import 'package:flutter/foundation.dart';

enum MessageStatus { sending, sent, failed }
enum ConversationRole { customer, sales, manager, unknown }

ConversationRole roleFromString(String? s) {
  if (s == null) return ConversationRole.unknown;
  final lower = s.toLowerCase();
  if (lower.contains('sales')) return ConversationRole.sales;
  if (lower.contains('manager')) return ConversationRole.manager;
  if (lower.contains('customer') || lower.contains('consumer') || lower.contains('you')) {
    return ConversationRole.customer;
  }
  return ConversationRole.unknown;
}

class Chat {
  final int id;
  final int supplierId;
  final String supplierName;
  final int? consumerId;
  final String? consumerName;
  String lastMessage;
  DateTime lastMessageAt;
  int unreadCount;
  bool isActive;

  final Map<String, dynamic>? rawJson;

  Chat({
    required this.id,
    this.rawJson,
    required this.supplierId,
    required this.supplierName,
    this.consumerId,
    this.consumerName,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isActive = true,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      rawJson: json,
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      supplierId:
      json['supplier_id'] is int ? json['supplier_id'] as int : int.parse('${json['supplier_id']}'),
      supplierName: json['supplier_name'] ?? 'Unknown Supplier',
      consumerId: json['consumer_id'] is int ? json['consumer_id'] as int : (json['consumer_id'] != null ? int.parse('${json['consumer_id']}') : null),
      consumerName: json['consumer_name'] ?? json['consumer'],
      lastMessage: json['last_message'] ?? '',
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : DateTime.now(),
      unreadCount: json['unread_count'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'consumer_id': consumerId,
      'consumer_name': consumerName,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt.toIso8601String(),
      'unread_count': unreadCount,
      'is_active': isActive,
    };
  }

  void updateLastMessage(String message, DateTime at, {bool incrementUnread = true}) {
    lastMessage = message;
    lastMessageAt = at;
    if (incrementUnread) unreadCount += 1;
  }
}

class ChatMessage {
  final int id;
  final int chatId;
  final int senderId;
  final String senderName;
  final ConversationRole senderRole;
  final String message;
  final String? fileUrl;
  final String? audioUrl;
  final DateTime sentAt;
  final bool isRead;
  MessageStatus status;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    this.fileUrl,
    this.audioUrl,
    required this.sentAt,
    this.isRead = false,
    this.status = MessageStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] is int ? json['id'] as int : int.parse('${json['id']}'),
      chatId: json['chat_id'] is int ? json['chat_id'] as int : int.parse('${json['chat_id']}'),
      senderId: json['sender_id'] is int ? json['sender_id'] as int : int.parse('${json['sender_id']}'),
      senderName: json['sender_name'] ?? 'Unknown',
      senderRole: roleFromString(json['sender_role'] as String?),
      message: json['message'] ?? '',
      fileUrl: json['file_url'],
      audioUrl: json['audio_url'],
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : DateTime.now(),
      isRead: json['is_read'] ?? false,
      status: _statusFromString(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': describeEnum(senderRole),
      'message': message,
      'file_url': fileUrl,
      'audio_url': audioUrl,
      'sent_at': sentAt.toIso8601String(),
      'is_read': isRead,
      'status': _statusToString(status),
    };
  }

  ChatMessage copyWith({
    int? id,
    int? chatId,
    int? senderId,
    String? senderName,
    ConversationRole? senderRole,
    String? message,
    String? fileUrl,
    String? audioUrl,
    DateTime? sentAt,
    bool? isRead,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      message: message ?? this.message,
      fileUrl: fileUrl ?? this.fileUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
    );
  }

  String get timeFormatted {
    final h = sentAt.hour.toString().padLeft(2, '0');
    final m = sentAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static MessageStatus _statusFromString(dynamic s) {
    if (s == null) return MessageStatus.sent;
    final lower = s.toString().toLowerCase();
    if (lower.contains('send') && lower.contains('ing')) return MessageStatus.sending;
    if (lower.contains('fail')) return MessageStatus.failed;
    return MessageStatus.sent;
  }

  static String _statusToString(MessageStatus st) {
    switch (st) {
      case MessageStatus.sending:
        return 'sending';
      case MessageStatus.failed:
        return 'failed';
      case MessageStatus.sent:
        return 'sent';
    }
  }
}
