
import 'package:flutter/material.dart';

class PersonalizeCard extends StatelessWidget {
  final TextEditingController userNameController;
  final TextEditingController aiPalNameController;
  final VoidCallback onSave;

  const PersonalizeCard({
    super.key,
    required this.userNameController,
    required this.aiPalNameController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Personalize", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
            const SizedBox(height: 20),
            TextField(
              controller: userNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Your Name",
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.person, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: aiPalNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "AI Pal's Name",
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.psychology, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSave,
                child: const Text("Save Names"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
