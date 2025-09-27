import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/screens/signup_screen.dart';

import 'signup_screen_test.mocks.dart';

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

  Future<void> pumpSignUpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: const SignUpScreen(),
        ),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );
  }

  testWidgets('renders correctly', (WidgetTester tester) async {
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    await pumpSignUpScreen(tester);

    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('shows a snackbar when fields are empty', (WidgetTester tester) async {
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    await pumpSignUpScreen(tester);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Please fill in all fields.'), findsOneWidget);
  });

  testWidgets('shows a loading indicator when loading', (WidgetTester tester) async {
    when(mockAuthBloc.state).thenReturn(AuthLoading());
    await pumpSignUpScreen(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('adds AuthSignUpRequested event on sign-up button tap', (WidgetTester tester) async {
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    await pumpSignUpScreen(tester);

    await tester.enterText(find.byType(TextField).at(0), 'test@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.enterText(find.byType(TextField).at(2), 'Test User');
    await tester.enterText(find.byType(TextField).at(3), 'Test Pal');
    await tester.tap(find.byType(ElevatedButton));

    verify(mockAuthBloc.add(any)).called(1);
  });

  testWidgets('shows a snackbar on failed sign-up', (WidgetTester tester) async {
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    final controller = StreamController<AuthState>.broadcast();
    when(mockAuthBloc.stream).thenAnswer((_) => controller.stream);

    await pumpSignUpScreen(tester);

    controller.add(AuthFailure(message: 'Sign-up failed'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Sign-up failed'), findsOneWidget);
    
    controller.close();
  });
}