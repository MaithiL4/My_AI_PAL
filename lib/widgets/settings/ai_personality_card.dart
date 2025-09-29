
import 'package:flutter/material.dart';

class AIPersonalityCard extends StatelessWidget {
  const AIPersonalityCard({super.key});

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
            Text("AI Personality", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
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
    );
  }
}
