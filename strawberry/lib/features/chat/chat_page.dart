import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';

class ChatPage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final bool isAdmin;

  const ChatPage({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.isAdmin,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Stream<List<Map<String, dynamic>>> _chatStream;

  // Messages we've sent/deleted locally, shown immediately while we wait for
  // the Realtime stream to confirm them (see _sendMessage / _mergeMessages).
  final List<Map<String, dynamic>> _pendingMessages = [];

  static const Color _bg = Color(0xFFF6F6FB);
  static const Color _surface = Colors.white;
  static const Color _primary = Color(0xFFE94464);
  static const Color _primarySoft = Color(0xFFFFE7EC);
  static const Color _textDark = Color(0xFF1E1B24);
  static const Color _textMuted = Color(0xFF8A8794);
  static const Color _border = Color(0xFFEDEDF4);

  @override
  void initState() {
    super.initState();
    _chatStream = _authService.getChatStream(widget.studentId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final senderId = widget.isAdmin ? 'admin' : widget.studentId;
    final receiverId = widget.isAdmin ? widget.studentId : 'admin';

    try {
      // sendMessage now returns the inserted row (with its real id) so we
      // can show it immediately instead of waiting for the Realtime event
      // to come back — that round trip is what was making messages only
      // show up after leaving and reopening the chat.
      final inserted = await _authService.sendMessage(senderId, receiverId, text);
      if (!mounted) return;
      setState(() {
        _pendingMessages.add(inserted);
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: const Color(0xFFEF4949),
        ),
      );
    }
  }

  Future<void> _confirmDeleteMessage(Map<String, dynamic> msg) async {
    if (!widget.isAdmin) return;
    final id = msg['id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This message will be permanently deleted for both sides.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4949))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _authService.deleteMessage(id as int);
      if (!mounted) return;
      setState(() {
        _pendingMessages.removeWhere((m) => m['id'] == id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete message: $e'),
          backgroundColor: const Color(0xFFEF4949),
        ),
      );
    }
  }

  Future<void> _confirmDeleteChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entire chat?'),
        content: Text(
          'All messages with ${widget.studentName} will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete chat', style: TextStyle(color: Color(0xFFEF4949))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _authService.deleteChatThread(widget.studentId);
      if (!mounted) return;
      setState(() {
        _pendingMessages.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete chat: $e'),
          backgroundColor: const Color(0xFFEF4949),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isAdmin ? widget.studentName : 'Chat with Admin',
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            Text(
              widget.isAdmin ? 'Student Chat' : 'Online Support',
              style: const TextStyle(color: _textMuted, fontSize: 11.5),
            ),
          ],
        ),
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _border, width: 1)),
        actions: widget.isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: _textMuted),
                  tooltip: 'Delete entire chat',
                  onPressed: _confirmDeleteChat,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }

                final streamMessages = snapshot.data ?? const [];

                // Merge the confirmed stream data with anything we sent
                // optimistically that the stream hasn't echoed back yet.
                final streamIds = streamMessages.map((m) => m['id']).toSet();
                final stillPending =
                    _pendingMessages.where((m) => !streamIds.contains(m['id'])).toList();
                final messages = [...streamMessages, ...stillPending]
                  ..sort((a, b) {
                    final ta = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
                    final tb = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
                    return ta.compareTo(tb);
                  });

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Send a message to start.',
                      style: TextStyle(color: _textMuted, fontSize: 14),
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final text = msg['message'] ?? '';
                    final sender = msg['sender_id'] as String;

                    final isMe = widget.isAdmin
                        ? (sender == 'admin')
                        : (sender == widget.studentId);

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                      onLongPress: widget.isAdmin ? () => _confirmDeleteMessage(msg) : null,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? _primary : _surface,
                          border: isMe ? null : Border.all(color: _border),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe
                                ? const Radius.circular(16)
                                : Radius.zero,
                            bottomRight: isMe
                                ? Radius.zero
                                : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isMe ? Colors.white : _textDark,
                            fontSize: 14.5,
                            fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: _textDark, fontSize: 14.5),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: _primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                filled: true,
                fillColor: _bg,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 22,
            backgroundColor: _primary,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}