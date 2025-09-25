import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/models/user.dart';

class PersonalityScreen extends StatefulWidget {
  const PersonalityScreen({super.key});

  @override
  State<PersonalityScreen> createState() => _PersonalityScreenState();
}

class _PersonalityScreenState extends State<PersonalityScreen> {
  final TextEditingController _personalityController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadPersonality();
  }

  void _loadPersonality() {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    _personalityController.text = user.aiPalName;
  }

  void _savePersonality() {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    final newPersonality = _personalityController.text.trim();
    if (newPersonality.isNotEmpty) {
      _firestore
          .collection('users')
          .doc(user.id)
          .update({'aiPalName': newPersonality});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personality saved!')),
      );
    }
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
                hintText: 'e.g., "A helpful and friendly assistant."'
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