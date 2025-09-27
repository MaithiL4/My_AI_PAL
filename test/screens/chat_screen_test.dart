import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:my_ai_pal/blocs/auth/auth_bloc.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:my_ai_pal/services/ai_service.dart';
import 'package:my_ai_pal/screens/chat_screen.dart';
import 'package:my_ai_pal/widgets/chat_bubble.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'chat_screen_test.mocks.dart';

@GenerateMocks([AuthBloc, AIService, NavigatorObserver])
void main() {
  late MockAuthBloc mockAuthBloc;
  late MockAIService mockAIService;
  late MockNavigatorObserver mockNavigatorObserver;
  late User user;
  late FakeFirebaseFirestore fakeFirestore;
  late MockClient mockHttpClient;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockAIService = MockAIService();
    mockNavigatorObserver = MockNavigatorObserver();
    user = User(id: '123', userName: 'Test', email: 'test@test.com', aiPalName: 'TestPal');
    fakeFirestore = FakeFirebaseFirestore();

    mockHttpClient = MockClient((request) async {
      if (request.url.toString().contains('api.dicebear.com')) {
        return http.Response(
          '''<svg viewBox="0 0 1 1" xmlns="http://www.w3.org/2000/svg"></svg>''',
          200,
          headers: {'content-type': 'image/svg+xml'},
        );
      }
      return http.Response('Not Found', 404);
    });

    when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: user));
    when(mockAuthBloc.stream).thenAnswer((_) => Stream.empty());
    when(mockNavigatorObserver.navigator).thenReturn(null);
    when(mockAIService.getAIReply(
      userMessage: anyNamed('userMessage'),
      user: anyNamed('user'),
      history: anyNamed('history'),
    )).thenAnswer((_) async => 'AI reply');
  });

  Future<void> pumpChatScreen(WidgetTester tester, {bool disableInitialGreeting = true}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            Provider<AIService>.value(value: mockAIService),
          ],
          child: ChatScreen(firestore: fakeFirestore, disableInitialGreeting: disableInitialGreeting),
        ),
        navigatorObservers: [mockNavigatorObserver],
      ),
    );
  }

  testWidgets('renders correctly', (WidgetTester tester) async {
    await pumpChatScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('displays messages from firestore', (WidgetTester tester) async {
    await fakeFirestore.collection('users').doc(user.id).collection('chats').add({
      'sender': user.userName,
      'text': 'Hello',
      'timestamp': Timestamp.now(),
    });
    await fakeFirestore.collection('users').doc(user.id).collection('chats').add({
      'sender': user.aiPalName,
      'text': 'Hi there!',
      'timestamp': Timestamp.now(),
    });

    await pumpChatScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ChatBubble), findsNWidgets(2));
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Hi there!'), findsOneWidget);
  });

  testWidgets('sends a message when the send button is tapped', (WidgetTester tester) async {
    await pumpChatScreen(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    verify(mockAIService.getAIReply(
      userMessage: 'Hello',
      user: user,
      history: anyNamed('history'),
    )).called(1);
  });

  testWidgets('loads more messages when scrolling to the top', (WidgetTester tester) async {
    for (int i = 0; i < 25; i++) {
      await fakeFirestore.collection('users').doc(user.id).collection('chats').add({
        'sender': user.userName,
        'text': 'Message $i',
        'timestamp': Timestamp.fromMillisecondsSinceEpoch(i * 1000),
      });
    }

    await pumpChatScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ChatBubble), findsNWidgets(20));

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.byType(ChatBubble), findsNWidgets(25));
  });

  testWidgets('shows initial greeting when there are no messages', (WidgetTester tester) async {
    await pumpChatScreen(tester, disableInitialGreeting: false);
    await tester.pumpAndSettle();

    verify(mockAIService.getAIReply(
      userMessage: 'Introduce yourself to your new friend, Test. Be warm and ask a question to start the conversation.',
      user: user,
      history: [],
    )).called(1);
  });
}