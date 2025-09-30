import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:my_ai_pal/widgets/gradient_scaffold.dart';
import 'package:flutter_glass_morphism/flutter_glass_morphism.dart';

class AIProfileScreen extends StatefulWidget {
  final User user;

  const AIProfileScreen({super.key, required this.user});

  @override
  State<AIProfileScreen> createState() => _AIProfileScreenState();
}

class _AIProfileScreenState extends State<AIProfileScreen> {
  late List<String> _personalityTraits;
  bool _isEditing = false;
  final _newTraitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _personalityTraits = List.from(widget.user.personalityTraits);
  }

  @override
  void dispose() {
    _newTraitController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedUser = widget.user.copyWith(personalityTraits: _personalityTraits);
    context.read<AuthBloc>().add(UserUpdated(updatedUser));
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.id)
        .update({'personalityTraits': _personalityTraits});
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text("${widget.user.aiPalName}'s Profile", style: const TextStyle(color: Colors.white)),
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
        child: GlassMorphismContainer(
          width: 350,
          height: 600,
          borderRadius: BorderRadius.circular(20),
          alignment: Alignment.center,

          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 80,
                  child: ClipOval(
                    child: SvgPicture.network(
                      widget.user.aiAvatarUrl ?? 'https://api.dicebear.com/7.x/adventurer/svg?seed=13',
                      placeholderBuilder: (context) => const CircularProgressIndicator(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.user.aiPalName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Personality Traits:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: _personalityTraits.isEmpty
                        ? const Center(
                            child: Text(
                              "No personality traits yet.\nTap 'Edit' to add some!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          )
                        : Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            alignment: WrapAlignment.center,
                            children: _personalityTraits.map((trait) => Chip(
                                  label: Text(trait),
                                  onDeleted: _isEditing
                                      ? () {
                                          setState(() {
                                            _personalityTraits.remove(trait);
                                          });
                                        }
                                      : null,
                                )).toList(),
                          ),
                  ),
                ),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: TextField(
                      controller: _newTraitController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Add a new trait",
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.add, color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _personalityTraits.add(value);
                            _newTraitController.clear();
                          });
                        }
                      },
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
