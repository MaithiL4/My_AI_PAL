import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String? imageUrl;
  final bool isUser;
  final String userName;
  final String aiPalName;
  final DateTime timestamp;
  final String? userAvatarUrl;
  final String? aiAvatarUrl;

  const ChatBubble({
    super.key,
    required this.message,
    this.imageUrl,
    required this.isUser,
    required this.userName,
    required this.aiPalName,
    required this.timestamp,
    this.userAvatarUrl,
    this.aiAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              radius: 20,
              child: ClipOval(
                child: SvgPicture.network(
                  aiAvatarUrl ?? 'https://api.dicebear.com/7.x/adventurer/svg?seed=13',
                  placeholderBuilder: (context) => const CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        Flexible(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primary.withOpacity(0.4)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.network(
                          imageUrl!,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                        ),
                      ),
                    if (message.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: imageUrl != null ? 8.0 : 0.0),
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('hh:mm a').format(timestamp),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isUser)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: CircleAvatar(
              radius: 20,
              child: ClipOval(
                child: SvgPicture.network(
                  userAvatarUrl ?? 'https://api.dicebear.com/7.x/adventurer/svg?seed=0',
                  placeholderBuilder: (context) => const CircularProgressIndicator(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
