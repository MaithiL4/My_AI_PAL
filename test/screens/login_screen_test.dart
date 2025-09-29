import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/screens/login_screen.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:my_ai_pal/screens/chat_screen.dart';

import 'login_screen_test.mocks.dart';

@GenerateMocks([AuthBloc, NavigatorObserver])
void main() {
  late MockAuthBloc mockAuthBloc;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockNavigatorObserver = MockNavigatorObserver();
    when(mockAuthBloc.stream).thenAnswer((_) => Stream.empty());
    when(mockNavigatorObserver.navigator).thenReturn(null);
  });

  Future<void> pumpLoginScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: const LoginScreen(),
        ),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );
  }

  testWidgets('renders correctly', (WidgetTester tester) async {
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    await pumpLoginScreen(tester);

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('shows a snackbar when fields are empty', (WidgetTester tester) async {
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    await pumpLoginScreen(tester);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Please fill in all fields.'), findsOneWidget);
  });

  testWidgets('shows a loading indicator when loading', (WidgetTester tester) async {
    when(mockAuthBloc.state).thenReturn(AuthLoading());
    await pumpLoginScreen(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('adds AuthLoginRequested event on login button tap', (WidgetTester tester) async {
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    await pumpLoginScreen(tester);

    await tester.enterText(find.byType(TextField).first, 'test@test.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.byType(ElevatedButton));

    verify(mockAuthBloc.add(any)).called(1);
  });

  testWidgets('shows a snackbar on failed login', (WidgetTester tester) async {
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    final controller = StreamController<AuthState>.broadcast();
    when(mockAuthBloc.stream).thenAnswer((_) => controller.stream);

    await pumpLoginScreen(tester);

    controller.add(AuthFailure(message: 'Login failed'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Login failed'), findsOneWidget);
    
    controller.close();
  });
}