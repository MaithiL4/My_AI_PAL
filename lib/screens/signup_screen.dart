import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/screens/welcome_screen.dart';
import 'package:my_ai_pal/theme/colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userNameController = TextEditingController();
  final _aiPalNameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _userNameController.dispose();
    _aiPalNameController.dispose();
    super.dispose();
  }

  void _signUp() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final usersName = _userNameController.text.trim();
    final aiPalName = _aiPalNameController.text.trim();

    if (username.isEmpty || password.isEmpty || usersName.isEmpty || aiPalName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    context.read<AuthBloc>().add(AuthSignUpRequested(
          username: username,
          password: password,
          usersName: usersName,
          aiPalName: aiPalName,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => WelcomeScreen(
                  userName: state.user.userName,
                  aiPalName: state.user.aiPalName,
                ),
              ),
              (route) => false,
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _userNameController,
                      decoration: const InputDecoration(
                        labelText: "Your Name",
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _aiPalNameController,
                      decoration: const InputDecoration(
                        labelText: "AI Pal's Name",
                        prefixIcon: Icon(Icons.psychology),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: state is AuthLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _signUp,
                              child: const Text("Sign Up"),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
