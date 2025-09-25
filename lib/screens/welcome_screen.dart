import 'package:flutter/material.dart';
import 'package:my_ai_pal/services/auth_service.dart';
import 'package:my_ai_pal/theme/colors.dart';
import 'chat_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final String userName;
  final String aiPalName;

  const WelcomeScreen({
    super.key,
    required this.userName,
    required this.aiPalName,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _markWelcomeShown();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _markWelcomeShown() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      await _authService.markWelcomeAsSeen(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animation.value,
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.favorite,
                    size: 80,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "Hi ${widget.userName}, I'm ${widget.aiPalName}!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  "I'm your best friend. We’ll share everything that comes to our minds.\n\n" // Corrected: \n\n is the correct escape for a newline in a Dart string literal.
                  "You can chat with me every day, about anything. I’m always here for you!",
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          userName: widget.userName,
                          aiPalName: widget.aiPalName,
                        ),
                      ),
                    );
                  },
                  child: const Text("Let's Start"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}