import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:my_ai_pal/widgets/gradient_scaffold.dart';

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
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Select Avatar', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: GlassmorphicContainer(
          width: 350,
          height: 500,
          borderRadius: 20,
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
          child: GridView.builder(
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
        ),
      ),
    );
  }
}
