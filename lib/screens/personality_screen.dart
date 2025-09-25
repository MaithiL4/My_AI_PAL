
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:my_ai_pal/services/auth_service.dart';

class PersonalityScreen extends StatefulWidget {
  const PersonalityScreen({super.key});

  @override
  State<PersonalityScreen> createState() => _PersonalityScreenState();
}

class _PersonalityScreenState extends State<PersonalityScreen> {
  final TextEditingController _personalityController = TextEditingController();
  final AuthService _authService = AuthService();
  late Box _personalityBox;

  @override
  void initState() {
    super.initState();
    _openBoxAndLoadPersonality();
  }

  Future<void> _openBoxAndLoadPersonality() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _personalityBox = await Hive.openBox('personality_${user.userName}');
      final savedPersonality = _personalityBox.get('personality');
      if (savedPersonality != null) {
        _personalityController.text = savedPersonality;
      }
    }
  }

  void _savePersonality() {
    _personalityBox.put('personality', _personalityController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Personality saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Personality'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _personalityController,
              decoration: const InputDecoration(
                labelText: 'AI Personality',
                hintText: 'e.g., "A helpful and friendly assistant."',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _savePersonality,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
