import 'package:glassmorphism/glassmorphism.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_ai_pal/widgets/gradient_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:my_ai_pal/screens/settings_screen.dart';
import 'package:my_ai_pal/services/ai_service.dart';
import 'package:my_ai_pal/services/ai_service_exception.dart';
import 'package:my_ai_pal/services/error_service.dart';
import 'package:my_ai_pal/widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _isTyping = false;

  List<QueryDocumentSnapshot> _messages = [];
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  StreamSubscription? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMoreMessages);
    _fetchMessages(isInitialFetch: true);
    _subscribeToNewMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.removeListener(_loadMoreMessages);
    _scroll.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _loadMoreMessages() {
    if (_scroll.position.pixels == _scroll.position.maxScrollExtent && !_isLoadingMore) {
      _fetchMessages();
    }
  }

  Future<void> _fetchMessages({bool isInitialFetch = false}) async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .limit(20);

    if (!isInitialFetch && _lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();

    if (isInitialFetch && snapshot.docs.isEmpty) {
      _getInitialGreeting(user);
    }

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
      setState(() {
        _messages.addAll(snapshot.docs);
      });
    }

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _subscribeToNewMessages() {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    _messagesSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .limit(1)        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final newMessage = snapshot.docs.first;
        if (!_messages.any((msg) => msg.id == newMessage.id)) {
          setState(() {
            _messages.insert(0, newMessage);
          });
        }
      }
    });
  }

  void _sendMessage(User user) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _isTyping = true;
    });

    try {
      final history = _messages.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'sender': data['sender'] as String,
          'text': data['text'] as String,
        };
      }).toList();


      await context.read<AIService>().getAIReply(
        userMessage: text,
        user: user,
        history: history.reversed.toList(),
      );
    } on AIServiceException catch (e, s) {
      ErrorService.handleError(e, s);
    } finally {
      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.watch<AuthBloc>().state as AuthAuthenticated).user;

    return GradientScaffold(
      appBar: AppBar(
        title: Text('${user.aiPalName} 💬', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: GlassmorphicContainer(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 0,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
          ],
          stops: const [0.1, 1],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.5),
          ],
        ),
        child: Column(
          children: [
            if (_isLoadingMore) const LinearProgressIndicator(),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index].data() as Map<String, dynamic>;
                        final isUser = msg['sender'] == user.userName;
                        return ChatBubble(
                          message: msg['text'] ?? '',
                          isUser: isUser,
                          userName: user.userName,
                          aiPalName: user.aiPalName,
                          timestamp: (msg['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                          userAvatarUrl: user.avatarUrl,
                          aiAvatarUrl: user.aiAvatarUrl,
                        );
                      },
                    ),
            ),
            if (_isTyping)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Typing...', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white70)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (RawKeyEvent event) {
                        if (event is RawKeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter &&
                            !event.isShiftPressed) {
                          _sendMessage(user);
                        }
                      },
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Type your message...",
                          hintStyle: const TextStyle(color: Colors.white54),
                          fillColor: Colors.white.withOpacity(0.1),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _sendMessage(user),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<void> _getInitialGreeting(User user) async {
    // Add a small delay to avoid calling setState during build
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _isTyping = true);
    try {
      await context.read<AIService>().getAIReply(
        userMessage: "Introduce yourself to your new friend, ${user.userName}. Be warm and ask a question to start the conversation.",
        user: user,
        history: [], // No history for the first message
      );
    } on AIServiceException catch (e, s) {
      ErrorService.handleError(e, s);
    } finally {
      setState(() => _isTyping = false);
    }
  }
}
