
import 'package:flutter/material.dart';
import 'package:my_ai_pal/services/theme_service.dart';
import 'package:provider/provider.dart';

class ThemeCard extends StatelessWidget {
  const ThemeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    return Card(
      elevation: 2,
      color: Colors.white.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Theme", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
              value: themeService.themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeService.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
              },
            ),
            SwitchListTile(
              title: const Text('Follow System Theme', style: TextStyle(color: Colors.white)),
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
    );
  }
}
