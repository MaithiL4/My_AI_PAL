import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:my_ai_pal/theme/colors.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String userName;
  final String aiPalName;
  final DateTime timestamp;
  final String? userAvatarUrl;
  final String? aiAvatarUrl;

  const ChatBubble({
    super.key,
    required this.message,
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
    final isDarkMode = theme.brightness == Brightness.dark;

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
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? theme.colorScheme.primary
                  : (isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
                bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: isUser ? AppColors.textLight : theme.textTheme.bodyLarge?.color,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  DateFormat('hh:mm a').format(timestamp),
                  style: TextStyle(
                    color: isUser
                        ? AppColors.textLight.withOpacity(0.7)
                        : theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
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