import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:my_ai_pal/screens/settings_screen.dart';
import 'package:my_ai_pal/services/ai_service.dart';
import 'package:my_ai_pal/services/ai_service_exception.dart';
import 'package:my_ai_pal/services/error_service.dart';
import 'package:my_ai_pal/theme/colors.dart';
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
  bool _initialGreetingSent = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
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
      final chatCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('chats')
          .orderBy('timestamp', descending: true)
          .limit(10);

      final snapshot = await chatCollection.get();
      final history = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'sender': data['sender'] as String,
          'text': data['text'] as String,
        };
      }).toList();


      await AIService.getAIReply(
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
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.watch<AuthBloc>().state as AuthAuthenticated).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('${user.aiPalName} 💬'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.id)
                  .collection('chats')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty && !_initialGreetingSent) {
                  _initialGreetingSent = true;
                  _getInitialGreeting(user);
                  return const Center(child: CircularProgressIndicator());
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isUser = msg['sender'] == user.userName;
                    return ChatBubble(
                      message: msg['text'] ?? '',
                      isUser: isUser,
                      userName: user.userName,
                      aiPalName: user.aiPalName,
                      timestamp: (msg['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                    );
                  },
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
                  Text('Typing...', style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      fillColor: Theme.of(context).colorScheme.surface,
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
    );
  }

  Future<void> _getInitialGreeting(User user) async {
    // Add a small delay to avoid calling setState during build
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _isTyping = true);
    try {
      await AIService.getAIReply(
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