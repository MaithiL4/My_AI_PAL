import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_ai_pal/screens/avatar_selection_screen.dart';
import 'package:my_ai_pal/screens/login_screen.dart';
import 'package:my_ai_pal/services/auth_service.dart';
import 'package:my_ai_pal/services/theme_service.dart';
import 'package:my_ai_pal/theme/colors.dart';
import 'package:provider/provider.dart';

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
    _userNameController = TextEditingController();
    _aiPalNameController = TextEditingController();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    _userNameController.text = user.userName;
    _aiPalNameController.text = user.aiPalName;
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
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () async {
                  final selectedAvatar = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (context) => const AvatarSelectionScreen()),
                  );

                  if (selectedAvatar != null) {
                    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
                    final updatedUser = user.copyWith(avatarUrl: selectedAvatar);
                    context.read<AuthBloc>().add(UserUpdated(updatedUser));
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.id)
                        .update({'avatarUrl': selectedAvatar});
                  }
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      child: ClipOval(
                        child: SvgPicture.network(
                          (context.watch<AuthBloc>().state as AuthAuthenticated).user.avatarUrl ??
                              'https://api.dicebear.com/7.x/adventurer/svg?seed=0',
                          placeholderBuilder: (context) => const CircularProgressIndicator(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Your Avatar'),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final selectedAvatar = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(builder: (context) => const AvatarSelectionScreen()),
                  );

                  if (selectedAvatar != null) {
                    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
                    final updatedUser = user.copyWith(aiAvatarUrl: selectedAvatar);
                    context.read<AuthBloc>().add(UserUpdated(updatedUser));
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.id)
                        .update({'aiAvatarUrl': selectedAvatar});
                  }
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      child: ClipOval(
                        child: SvgPicture.network(
                          (context.watch<AuthBloc>().state as AuthAuthenticated).user.aiAvatarUrl ??
                              'https://api.dicebear.com/7.x/adventurer/svg?seed=13',
                          placeholderBuilder: (context) => const CircularProgressIndicator(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('AI Pal\'s Avatar'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Personalize", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _userNameController,
                    decoration: const InputDecoration(
                      labelText: "Your Name",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _aiPalNameController,
                    decoration: const InputDecoration(
                      labelText: "AI Pal's Name",
                      prefixIcon: Icon(Icons.psychology),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      child: const Text("Save Names"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Theme", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: themeService.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      themeService.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Follow System Theme'),
                    value: themeService.themeMode == ThemeMode.system,
                    onChanged: (value) {
                      if (value) {
                        themeService.setThemeMode(ThemeMode.system);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AI Personality", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/personality');
                      },
                      icon: const Icon(Icons.psychology_alt),
                      label: const Text("Customize AI Personality"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Data Management", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _clearHistory,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text("Clear Chat History"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}