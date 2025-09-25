import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_ai_pal/models/user.dart';
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
  final AuthService _authService = AuthService();
  late TextEditingController _userNameController;
  late TextEditingController _aiPalNameController;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController();
    _aiPalNameController = TextEditingController();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _userNameController.text = _currentUser?.userName ?? '';
      _aiPalNameController.text = _currentUser?.aiPalName ?? '';
    });
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _aiPalNameController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    if (_currentUser != null) {
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
        _currentUser!.userName = newUserName;
        _currentUser!.aiPalName = newAiPalName;
        await _currentUser!.save();
        await _authService.logout();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  void _clearHistory() async {
    if (_currentUser == null) return;

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
      final box = await Hive.openBox<Map>('messages_${_currentUser!.userName}');
      await box.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chat history cleared.")),
        );
      }
    }
  }

  void _logout() async {
    await _authService.logout();
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
