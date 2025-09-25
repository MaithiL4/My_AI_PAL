import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_ai_pal/screens/settings_screen.dart';
import 'package:my_ai_pal/services/ai_service_exception.dart';
import 'package:my_ai_pal/theme/colors.dart';
import 'package:my_ai_pal/services/ai_service.dart';
import 'package:my_ai_pal/services/error_service.dart';
import 'package:my_ai_pal/widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  final String aiPalName;

  const ChatScreen({
    super.key,
    required this.userName,
    required this.aiPalName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late Box<Map> _box;
  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _openBoxAndLoad();
  }

  Future<void> _openBoxAndLoad() async {
    _box = await Hive.openBox<Map>('messages_${widget.userName}');
    final loaded = _box.values.map((m) {
      return {
        'sender': m['sender'] as String,
        'text': m['text'] as String,
        'timestamp': m['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      };
    }).toList();

    if (loaded.isEmpty) {
      _getInitialGreeting();
    } else {
      setState(() => _messages = loaded);
      _scrollToBottom();
    }
  }

  Future<void> _getInitialGreeting() async {
    setState(() => _isTyping = true);
    try {
      final reply = await AIService.getAIReply(
        userMessage: "Introduce yourself to your new friend, ${widget.userName}. Be warm and ask a question to start the conversation.",
        userName: widget.userName,
        aiPalName: widget.aiPalName,
        history: [], // No history for the first message
      );
      final aiMessage = {
        'sender': widget.aiPalName,
        'text': reply,
        'timestamp': DateTime.now().toIso8601String(),
      };
      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
      });
      _saveMessage(aiMessage);
      _scrollToBottom();
    } on AIServiceException catch (e, s) {
      ErrorService.handleError(e, s);
      setState(() => _isTyping = false);
    }
  }

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

  void _saveMessage(Map<String, dynamic> message) {
    _box.add(message);
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMessage = {
      'sender': widget.userName,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    };
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _saveMessage(userMessage);
    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await AIService.getAIReply(
        userMessage: text,
        userName: widget.userName,
        aiPalName: widget.aiPalName,
        history: _messages.map((m) => {'sender': m['sender'] as String, 'text': m['text'] as String}).toList(),
      );
      final aiMessage = {
        'sender': widget.aiPalName,
        'text': reply,
        'timestamp': DateTime.now().toIso8601String(),
      };
      setState(() {
        _messages.add(aiMessage);
        _isTyping = false;
      });
      _saveMessage(aiMessage);
      _scrollToBottom();

      // Trigger summarization every 5 messages (user + AI)
      if (_messages.length % 5 == 0) {
        AIService.summarizeAndStoreMemory(
          userName: widget.userName,
          aiPalName: widget.aiPalName,
          history: _messages.map((m) => {'sender': m['sender'] as String, 'text': m['text'] as String}).toList(),
        );
      }
    } on AIServiceException catch (e, s) {
      ErrorService.handleError(e, s);
      setState(() {
        _messages.remove(userMessage); // Remove the user's message if AI fails
        _isTyping = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _box.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionLevel = (_messages.length / 20).clamp(0.0, 1.0);
    final dynamicBackgroundColor = Color.lerp(
      Theme.of(context).colorScheme.surface,
      AppColors.accent.withOpacity(0.3),
      connectionLevel,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.aiPalName} 💬'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                Text('${(connectionLevel * 100).toInt()}%'),
                const SizedBox(width: 4),
                const Icon(Icons.favorite, color: AppColors.accent),
              ],
            ),
          ),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.background,
              dynamicBackgroundColor!,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == widget.userName;
                  return ChatBubble(
                    message: msg['text'] ?? '',
                    isUser: isUser,
                    userName: widget.userName,
                    aiPalName: widget.aiPalName,
                    timestamp: msg['timestamp'] != null ? DateTime.parse(msg['timestamp']) : DateTime.now(),
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
                    onPressed: _sendMessage,
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
}
