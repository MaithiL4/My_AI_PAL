
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:my_ai_pal/screens/avatar_selection_screen.dart';

class AvatarSelection extends StatelessWidget {
  const AvatarSelection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = (context.watch<AuthBloc>().state as AuthAuthenticated).user;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () async {
            final selectedAvatar = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (context) => const AvatarSelectionScreen()),
            );

            if (selectedAvatar != null) {
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
                    user.avatarUrl ??
                        'https://api.dicebear.com/7.x/adventurer/svg?seed=0',
                    placeholderBuilder: (context) => const CircularProgressIndicator(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Your Avatar', style: TextStyle(color: Colors.white)),
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
                    user.aiAvatarUrl ??
                        'https://api.dicebear.com/7.x/adventurer/svg?seed=13',
                    placeholderBuilder: (context) => const CircularProgressIndicator(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('AI Pal\'s Avatar', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}
