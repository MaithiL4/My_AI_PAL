import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'package:my_ai_pal/widgets/gradient_scaffold.dart';
import 'package:my_ai_pal/widgets/chat_bubble.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/blocs/chat/chat_bloc.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:my_ai_pal/screens/settings_screen.dart';
import 'package:my_ai_pal/screens/ai_profile_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(
        context.read(),
        context.read(),
        FirebaseFirestore.instance,
      )..add(FetchMessages()),
      child: const ChatView(),
    );
  }
}

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels == _scroll.position.maxScrollExtent) {
      context.read<ChatBloc>().add(LoadMoreMessages());
    }
  }

  void _sendMessage(User user) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(SendMessage(message: text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.watch<AuthBloc>().state as AuthAuthenticated).user;

    return GradientScaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AIProfileScreen(user: user)),
          ),
          child: Text('${user.aiPalName} 💬',
              style: const TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
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
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
          ],
          stops: const [0.1, 1],
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.5),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ChatLoaded || state is AITyping) {
                    final messages = state is ChatLoaded ? state.messages : (state as AITyping).messages;
                    final isLoadingMore = state is ChatLoaded ? state.isLoadingMore : false;
                    final isAITyping = state is AITyping;

                    return ListView.builder(
                      controller: _scroll,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (isLoadingMore ? 1 : 0) + (isAITyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (isAITyping && index == 0) {
                          return ChatBubble(
                            message: '...',
                            isUser: false,
                            userName: user.userName,
                            aiPalName: user.aiPalName,
                            timestamp: DateTime.now(),
                            userAvatarUrl: user.avatarUrl,
                            aiAvatarUrl: user.aiAvatarUrl,
                          );
                        }
                        final itemIndex = isAITyping ? index - 1 : index;

                        if (isLoadingMore && itemIndex == messages.length) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final msg =
                            messages[itemIndex].data() as Map<String, dynamic>;
                        final isUser = msg['sender'] == user.userName;
                        return ChatBubble(
                          message: msg['text'] ?? '',
                          isUser: isUser,
                          userName: user.userName,
                          aiPalName: user.aiPalName,
                          timestamp: (msg['timestamp'] as Timestamp?)
                                  ?.toDate() ??
                              DateTime.now(),
                          userAvatarUrl: user.avatarUrl,
                          aiAvatarUrl: user.aiAvatarUrl,
                        );
                      },
                    );
                  } else if (state is ChatError) {
                    return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoaded && state.isLoadingMore) {
                  return const SizedBox.shrink();
                }
                return _buildMessageInput(user);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (event) {
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
    );
  }
}