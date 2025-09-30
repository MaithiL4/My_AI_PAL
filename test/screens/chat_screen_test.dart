import 'dart:async';

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

import '../services/ai_service_fake.dart';
import 'chat_screen_test.mocks.dart';

@GenerateMocks([AuthBloc, NavigatorObserver])
void main() {
  late MockAuthBloc mockAuthBloc;
  late FakeAIService fakeAIService;
  late MockNavigatorObserver mockNavigatorObserver;
  late User user;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    fakeAIService = FakeAIService();
    mockNavigatorObserver = MockNavigatorObserver();
    user = User(id: '123', userName: 'Test', email: 'test@test.com', aiPalName: 'TestPal');
    fakeFirestore = FakeFirebaseFirestore();

    when(mockAuthBloc.state).thenReturn(AuthAuthenticated(user: user));
    when(mockAuthBloc.stream).thenAnswer((_) => Stream.empty());
    when(mockNavigatorObserver.navigator).thenReturn(null);
  });

  Future<void> pumpChatScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            Provider<AIService>.value(value: fakeAIService),
          ],
          child: const ChatScreen(),
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

    fakeAIService.mockReply = 'AI reply';

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    final messages = await fakeFirestore.collection('users').doc(user.id).collection('chats').get();
    expect(messages.docs.length, 2);
    expect(messages.docs.any((doc) => doc.data()['text'] == 'Hello'), isTrue);
    expect(messages.docs.any((doc) => doc.data()['text'] == 'AI reply'), isTrue);
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
}
