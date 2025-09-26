import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AvatarSelectionScreen extends StatelessWidget {
  const AvatarSelectionScreen({super.key});

  final List<String> _avatars = const [
    'https://api.dicebear.com/7.x/adventurer/svg?seed=1',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=2',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=3',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=4',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=5',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=6',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=7',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=8',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=9',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=10',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=11',
    'https://api.dicebear.com/7.x/adventurer/svg?seed=12',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Avatar'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: _avatars.length,
        itemBuilder: (context, index) {
          final avatarUrl = _avatars[index];
          return GestureDetector(
            onTap: () {
              Navigator.pop(context, avatarUrl);
            },
            child: ClipOval(
              child: SvgPicture.network(
                avatarUrl,
                placeholderBuilder: (context) => const CircularProgressIndicator(),
              ),
            ),
          );
        },
        padding: const EdgeInsets.all(8.0),
      ),
    );
  }
}
