import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_glass_morphism/flutter_glass_morphism.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/widgets/gradient_scaffold.dart';

class PersonalityScreen extends StatefulWidget {
  const PersonalityScreen({super.key});

  @override
  State<PersonalityScreen> createState() => _PersonalityScreenState();
}

class _PersonalityScreenState extends State<PersonalityScreen> {
  final List<String> _predefinedTraits = [
    'Friendly',
    'Witty',
    'Curious',
    'Empathetic',
    'Supportive',
    'Playful',
    'Sarcastic',
    'Formal',
    'Informal',
  ];

  final Set<String> _selectedTraits = {};
  final TextEditingController _customTraitController = TextEditingController();
  bool _traitsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_traitsInitialized) {
      final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
      _selectedTraits.addAll(user.personalityTraits);
      _traitsInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Customize Personality', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: GlassMorphismContainer(
          width: 350,
          height: 600,
          borderRadius: BorderRadius.circular(20),
          alignment: Alignment.center,

          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    ..._predefinedTraits.map((trait) => CheckboxListTile(
                          title: Text(trait, style: const TextStyle(color: Colors.white)),
                          value: _selectedTraits.contains(trait),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedTraits.add(trait);
                              } else {
                                _selectedTraits.remove(trait);
                              }
                            });
                          },
                        )),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _customTraitController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Add a custom trait',
                          labelStyle: TextStyle(color: Colors.white54),
                          suffixIcon: Icon(Icons.add, color: Colors.white),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _selectedTraits.add(value);
                              _customTraitController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    Wrap(
                      spacing: 8.0,
                      children: _selectedTraits
                          .map((trait) => Chip(
                                label: Text(trait),
                                onDeleted: () {
                                  setState(() {
                                    _selectedTraits.remove(trait);
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
                    final updatedUser = user.copyWith(personalityTraits: _selectedTraits.toList());
                    context.read<AuthBloc>().add(UserUpdated(updatedUser));
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.id)
                        .update({'personalityTraits': _selectedTraits.toList()});
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
