// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).loadMockChats();
    });
  }

  // Dialog moved into method
  void _openNewChatDialog(BuildContext context) {
    final supplierLinkProvider = Provider.of<SupplierLinkProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final suppliers = supplierLinkProvider.connectedSuppliers;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFFFF),
          title: const Text(
            'Start New Chat',
            style: TextStyle(
              color: Color(0xFF3F6533),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: suppliers.isEmpty
              ? const Text(
            'No approved suppliers yet.',
            style: TextStyle(color: Color(0xFF3F6533)),
          )
              : SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suppliers.length,
              itemBuilder: (context, index) {
                final supplier = suppliers[index];

                return ListTile(
                  leading: const Icon(Icons.store, color: Color(0xFF6B8E23)),
                  title: Text(
                    supplier.supplierName,
                    style: const TextStyle(
                      color: Color(0xFF3F6533),
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  onTap: () async {
                    // Create or get existing chat id
                    final newChatId = await chatProvider.startChatWithSupplier(
                      supplier.supplierId,
                      supplier.supplierName,
                    );

                    // Close dialog and navigate — check widget still mounted after awaits
                    if (!mounted) return;
                    Navigator.pop(context);

                    if (!mounted) return;
                    // Ensure messages are loaded and chat is selected in provider
                    await chatProvider.selectChat(newChatId);
                    // Mark read if you want (optional)
                    await chatProvider.markChatAsRead(newChatId);

                    if (!mounted) return;
                    // Find the provider-backed Chat instance
                    final openedChat = chatProvider.chats.firstWhere((c) => c.id == newChatId);

                    // Navigate to detail screen with the provider chat object
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _ChatDetailScreen(chat: openedChat),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFF3F6533)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        try {
          if (chatProvider.chats.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Messages',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
                backgroundColor: const Color(0xFF6B8E23),
                foregroundColor: Colors.white,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'No chats yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connect with suppliers to start messaging',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: const Color(0xFF6B8E23),
                child: const Icon(Icons.add_comment_rounded, color: Colors.white),
                onPressed: () {
                  _openNewChatDialog(context);
                },
              ),
            );
          }

          // List of chats
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Messages',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              backgroundColor: const Color(0xFF6B8E23),
              foregroundColor: Colors.white,
            ),
            body: ListView.builder(
              itemCount: chatProvider.chats.length,
              itemBuilder: (context, index) {
                final chat = chatProvider.chats[index];
                return _ChatListTile(
                  chat: chat,
                  onTap: () async {
                    try {
                      final navigator = Navigator.of(context);

                      // load messages & mark read
                      await chatProvider.selectChat(chat.id);
                      await chatProvider.markChatAsRead(chat.id); // <-- correct placement

                      await navigator.push(MaterialPageRoute(
                        builder: (_) => _ChatDetailScreen(chat: chat),
                      ));

                      // After returning from detail, clear selection
                      chatProvider.clearSelectedChat();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to open chat right now')),
                      );
                    }
                  },
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: const Color(0xFF6B8E23),
              child: const Icon(Icons.add_comment_rounded, color: Colors.white),
              onPressed: () {
                _openNewChatDialog(context);
              },
            ),
          );
        } catch (e) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Messages',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              backgroundColor: const Color(0xFF6B8E23),
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('An error occurred while loading chats.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      // recovery: safe navigation and state reset
                      chatProvider.clearSelectedChat();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: const Color(0xFF6B8E23),
              child: const Icon(Icons.add_comment_rounded, color: Colors.white),
              onPressed: () {
                _openNewChatDialog(context);
              },
            ),
          );
        }
      },
    );
  }
}

class _ChatListTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;

  const _ChatListTile({
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine a better title for sales reps: prefer consumerName saved on the chat
    String displayTitle = chat.supplierName;
    try {
      final userProv = Provider.of<UserProvider>(context, listen: false);
      final curUser = userProv.currentUser;
      if (curUser != null && curUser.role == User.ROLE_SALES_REP) {
        if (chat.consumerName != null && chat.consumerName!.isNotEmpty) {
          displayTitle = chat.consumerName!;
        }
      }
    } catch (_) {}

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF6B8E23).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.store,
          color: Color(0xFF6B8E23),
        ),
      ),
      title: Text(
        displayTitle,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        chat.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(chat.lastMessageAt),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          if (chat.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFF6B8E23),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

class _ChatDetailScreen extends StatefulWidget {
  final Chat chat;

  const _ChatDetailScreen({required this.chat});

  @override
  State<_ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<_ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Ensure we scroll to bottom after messages are built and mark read
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      } catch (_) {}

      // mark chat as read (safe: requires ChatProvider to have method)
      final chatProv = Provider.of<ChatProvider>(context, listen: false);
      try {
        await chatProv.markChatAsRead(widget.chat.id);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isOwnMessage(ChatMessage message) {
    // Determine ownership by comparing senderId with current user's id
    try {
      final userProv = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProv.currentUser;
      if (currentUser != null) {
        // Exact sender match
        if (message.senderId == currentUser.id) return true;

        // If the logged-in user is a sales_rep, treat any message authored by a sales role as 'own'
        // This covers mock/default supplier messages that have a different supplier id but represent the sales team.
        if (currentUser.role == User.ROLE_SALES_REP && message.senderRole == ConversationRole.sales) {
          return true;
        }

        return false;
      }
    } catch (_) {}

    // fallback conservative: consider message own only if role is customer
    return message.senderRole == ConversationRole.customer;
  }

  Widget _statusWidget(ChatMessage message) {
    final st = message.status;
    switch (st) {
      case MessageStatus.sending:
        return const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2));
      case MessageStatus.failed:
        return const Icon(Icons.error, color: Colors.red, size: 14);
      case MessageStatus.sent:
        return const Icon(Icons.check, color: Colors.green, size: 14);
    }
  }

  Future<void> _sendMessage(ChatProvider chatProvider) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);

    try {
      final success = await chatProvider.sendMessage(
        widget.chat.id,
        text,
      );

      if (success) {
        _messageController.clear();
        if (!mounted) return;
        ErrorHandler.showSuccessSnackBar(context, 'Message sent');

        // Scroll to bottom after a short delay to allow list update
        await Future.delayed(const Duration(milliseconds: 120));
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 50,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } else {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(
          context,
          chatProvider.errorMessage ?? 'Failed to send message',
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showErrorSnackBar(context, e);
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        final messages = chatProvider.selectedChatMessages;
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.chat.supplierName),
            backgroundColor: const Color(0xFF6B8E23),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                chatProvider.clearSelectedChat();
                Navigator.pop(context);
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.report),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Escalation request sent to manager (demo)')),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text('No messages yet. Say hi!'))
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwn = _isOwnMessage(message);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isOwn)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B8E23).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.store,
                                color: Color(0xFF6B8E23),
                                size: 18,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment:
                              isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                // Show sender name for messages that are not the current user's
                                if (!isOwn)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      message.senderName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOwn ? const Color(0xFF6B8E23) : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.message,
                                        style: TextStyle(
                                          color: isOwn ? Colors.white : Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatMessageTime(message.sentAt),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (isOwn) _statusWidget(message),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isOwn) const SizedBox(width: 8),
                          if (isOwn)
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B8E23),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Input area
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.attach_file),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('File upload coming soon'),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.mic),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Audio recording coming soon'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: (_isSending || _messageController.text.trim().isEmpty)
                          ? null
                          : () => _sendMessage(chatProvider),
                      mini: true,
                      backgroundColor: (_isSending || _messageController.text.trim().isEmpty)
                          ? Colors.grey
                          : const Color(0xFF6B8E23),
                      child: _isSending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
