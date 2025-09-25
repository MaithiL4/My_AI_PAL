import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_ai_pal/services/theme_service.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:my_ai_pal/screens/chat_screen.dart';
import 'package:my_ai_pal/screens/login_screen.dart';
import 'package:my_ai_pal/screens/personality_screen.dart';
import 'package:my_ai_pal/screens/settings_screen.dart';
import 'package:my_ai_pal/screens/welcome_screen.dart';
import 'package:my_ai_pal/services/auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:provider/provider.dart';
import 'package:my_ai_pal/theme/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        BlocProvider(create: (_) => AuthBloc(AuthService())..add(AuthCheckRequested())),
      ],
      child: const MyAIPal(),
    ),
  );
}

class MyAIPal extends StatelessWidget {
  const MyAIPal({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'MyAI Pal',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          home: const AuthWrapper(),
          routes: {
            '/settings': (context) => const SettingsScreen(),
            '/personality': (context) => const PersonalityScreen(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          if (!state.user.hasSeenWelcome) {
            return WelcomeScreen(user: state.user);
          } else {
            return const ChatScreen();
          }
        } else if (state is AuthUnauthenticated) {
          return const LoginScreen();
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}