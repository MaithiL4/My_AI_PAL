import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_ai_pal/theme/colors.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String userName;
  final String aiPalName;
  final DateTime timestamp;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.userName,
    required this.aiPalName,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
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
    );
  }
}