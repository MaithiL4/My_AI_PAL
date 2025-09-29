import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:my_ai_pal/screens/avatar_selection_screen.dart';
import 'package:my_ai_pal/widgets/gradient_scaffold.dart';
import 'package:glassmorphism/glassmorphism.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  late User _user;
  bool _isEditing = false;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    _nameController.text = _user.userName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedUser = _user.copyWith(userName: _nameController.text.trim());
    context.read<AuthBloc>().add(UserUpdated(updatedUser));
    FirebaseFirestore.instance
        .collection('users')
        .doc(_user.id)
        .update({'userName': _nameController.text.trim()});
    setState(() {
      _user = updatedUser;
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _isEditing
              ? IconButton(
                  icon: const Icon(Icons.save, color: Colors.white),
                  onPressed: _saveChanges,
                )
              : IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                ),
        ],
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _isEditing
                      ? () async {
                          final selectedAvatar = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(builder: (context) => const AvatarSelectionScreen()),
                          );

                          if (selectedAvatar != null) {
                            final updatedUser = _user.copyWith(avatarUrl: selectedAvatar);
                            context.read<AuthBloc>().add(UserUpdated(updatedUser));
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(_user.id)
                                .update({'avatarUrl': selectedAvatar});
                            setState(() {
                              _user = updatedUser;
                            });
                          }
                        }
                      : null,
                  child: CircleAvatar(
                    radius: 80,
                    child: ClipOval(
                      child: SvgPicture.network(
                        _user.avatarUrl ?? 'https://api.dicebear.com/7.x/adventurer/svg?seed=0',
                        placeholderBuilder: (context) => const CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _isEditing
                    ? TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      )
                    : Text(
                        _user.userName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                const SizedBox(height: 10),
                Text(
                  _user.email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
