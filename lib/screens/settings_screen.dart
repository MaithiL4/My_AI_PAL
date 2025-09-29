import 'package:my_ai_pal/screens/mood_dashboard_screen.dart';
import 'package:my_ai_pal/widgets/settings/ai_personality_card.dart';
import 'package:my_ai_pal/widgets/settings/avatar_selection.dart';
import 'package:my_ai_pal/widgets/settings/data_management_card.dart';
import 'package:my_ai_pal/widgets/settings/personalize_card.dart';
import 'package:my_ai_pal/widgets/settings/theme_card.dart';
import 'package:my_ai_pal/screens/memory_lane_screen.dart';
import 'package:my_ai_pal/screens/my_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/screens/login_screen.dart';
import 'package:my_ai_pal/services/auth_service.dart';
import 'package:my_ai_pal/widgets/gradient_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _userNameController;
  late TextEditingController _aiPalNameController;

  @override
  void initState() {
    super.initState();
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    _userNameController = TextEditingController(text: user.userName);
    _aiPalNameController = TextEditingController(text: user.aiPalName);
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _aiPalNameController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    final newUserName = _userNameController.text.trim();
    final newAiPalName = _aiPalNameController.text.trim();

    if (newUserName.isEmpty || newAiPalName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Names cannot be empty.")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restart Required"),
        content: const Text(
            "Changing names requires a restart. You will be logged out and need to log back in."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Continue"),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'userName': newUserName,
        'aiPalName': newAiPalName,
      });
      await context.read<AuthService>().logout();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _clearHistory() async {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear History?"),
        content: const Text("This will permanently delete all chat messages."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Clear"),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final chatCollection =
          FirebaseFirestore.instance.collection('users').doc(user.id).collection('chats');
      final snapshot = await chatCollection.get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chat history cleared.")),
        );
      }
    }
  }

  void _logout() async {
    await context.read<AuthService>().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 2,
              color: Colors.white.withOpacity(0.1),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: const Text('My Profile', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyProfileScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const AvatarSelection(),
            const SizedBox(height: 20),
            PersonalizeCard(
              userNameController: _userNameController,
              aiPalNameController: _aiPalNameController,
              onSave: _saveSettings,
            ),
            const SizedBox(height: 20),
            const ThemeCard(),
            const SizedBox(height: 20),
            const AIPersonalityCard(),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              color: Colors.white.withOpacity(0.1),
              child: ListTile(
                leading: const Icon(Icons.sentiment_satisfied, color: Colors.white),
                title: const Text('Mood Dashboard', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MoodDashboardScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              color: Colors.white.withOpacity(0.1),
              child: ListTile(
                leading: const Icon(Icons.history, color: Colors.white),
                title: const Text('Memory Lane', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MemoryLaneScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            DataManagementCard(onClearHistory: _clearHistory),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
