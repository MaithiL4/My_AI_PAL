import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:my_ai_pal/services/ai_service.dart';
import 'package:my_ai_pal/services/ai_service_exception.dart';
import 'package:my_ai_pal/models/user.dart' as app_user;

import 'ai_service_test.mocks.dart';

@GenerateMocks([
  http.Client,
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  Connectivity,
])
void main() {
  late AIService aiService;
  late MockClient mockHttpClient;
  late MockFirebaseFirestore mockFirestore;
  late MockConnectivity mockConnectivity;
  late MockCollectionReference<Map<String, dynamic>> mockCollectionReference;
  late MockDocumentReference<Map<String, dynamic>> mockDocumentReference;
  late MockDocumentSnapshot<Map<String, dynamic>> mockDocumentSnapshot;

  setUp(() {
    mockHttpClient = MockClient();
    mockFirestore = MockFirebaseFirestore();
    mockConnectivity = MockConnectivity();
    aiService = AIService(
      httpClient: mockHttpClient,
      firestore: mockFirestore,
      connectivity: mockConnectivity,
      apiKey: 'test_api_key',
    );
    mockCollectionReference = MockCollectionReference<Map<String, dynamic>>();
    mockDocumentReference = MockDocumentReference<Map<String, dynamic>>();
    mockDocumentSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
  });

  group('AIService', () {
    group('getAIReply', () {
      test('should return an AI reply when successful', () async {
        // Arrange
        final user = app_user.User(
          id: '123',
          userName: 'Test User',
          email: 'test@example.com',
          aiPalName: 'Test Pal',
          hasSeenWelcome: true,
        );
        const userMessage = 'Hello';
        const aiReply = 'Hi there!';
        final history = <Map<String, String>>[];

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        when(mockDocumentSnapshot.exists).thenReturn(false);
        when(mockDocumentReference.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockFirestore.collection('memories')).thenReturn(mockCollectionReference);
        when(mockCollectionReference.doc(user.id)).thenReturn(mockDocumentReference);

        final mockChatCollectionReference = MockCollectionReference<Map<String, dynamic>>();
        final mockChatDocumentReference = MockDocumentReference<Map<String, dynamic>>();
        when(mockFirestore.collection('users')).thenReturn(mockChatCollectionReference);
        when(mockChatCollectionReference.doc(user.id)).thenReturn(mockChatDocumentReference);
        when(mockChatDocumentReference.collection('chats')).thenReturn(mockCollectionReference);
        when(mockCollectionReference.add(any)).thenAnswer((_) async => mockDocumentReference);


        final response = http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': aiReply}
              }
            ]
          }),
          200,
        );
        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => response);

        // Act
        final result = await aiService.getAIReply(
          userMessage: userMessage,
          user: user,
          history: history,
        );

        // Assert
        expect(result, aiReply);
      });

      test('should throw an AIServiceException when offline', () async {
        // Arrange
        final user = app_user.User(
          id: '123',
          userName: 'Test User',
          email: 'test@example.com',
          aiPalName: 'Test Pal',
          hasSeenWelcome: true,
        );
        const userMessage = 'Hello';
        final history = <Map<String, String>>[];

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act & Assert
        expect(
          () => aiService.getAIReply(
            userMessage: userMessage,
            user: user,
            history: history,
          ),
          throwsA(isA<AIServiceException>()),
        );
      });

      test('should throw an AIServiceException when API key is missing', () async {
        // Arrange
        aiService = AIService(
          httpClient: mockHttpClient,
          firestore: mockFirestore,
          connectivity: mockConnectivity,
          apiKey: null,
        );
        final user = app_user.User(
          id: '123',
          userName: 'Test User',
          email: 'test@example.com',
          aiPalName: 'Test Pal',
          hasSeenWelcome: true,
        );
        const userMessage = 'Hello';
        final history = <Map<String, String>>[];

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        // Act & Assert
        expect(
          () => aiService.getAIReply(
            userMessage: userMessage,
            user: user,
            history: history,
          ),
          throwsA(isA<AIServiceException>()),
        );
      });

      test('should throw an AIServiceException when API returns an error', () async {
        // Arrange
        final user = app_user.User(
          id: '123',
          userName: 'Test User',
          email: 'test@example.com',
          aiPalName: 'Test Pal',
          hasSeenWelcome: true,
        );
        const userMessage = 'Hello';
        final history = <Map<String, String>>[];

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        when(mockDocumentSnapshot.exists).thenReturn(false);
        when(mockDocumentReference.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockFirestore.collection('memories')).thenReturn(mockCollectionReference);
        when(mockCollectionReference.doc(user.id)).thenReturn(mockDocumentReference);

        final response = http.Response('Error', 500);
        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () => aiService.getAIReply(
            userMessage: userMessage,
            user: user,
            history: history,
          ),
          throwsA(isA<AIServiceException>()),
        );
      });
    });

    group('extractAndStoreMemories', () {
      test('should not throw when successful', () async {
        // Arrange
        final user = app_user.User(
          id: '123',
          userName: 'Test User',
          email: 'test@example.com',
          aiPalName: 'Test Pal',
          hasSeenWelcome: true,
        );
        final history = <Map<String, String>>[];
        const summary = 'This is a summary.';

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        when(mockDocumentSnapshot.exists).thenReturn(false);
        when(mockDocumentReference.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockFirestore.collection('memories')).thenReturn(mockCollectionReference);
        when(mockCollectionReference.doc(user.id)).thenReturn(mockDocumentReference);
        when(mockDocumentReference.set(any)).thenAnswer((_) async => {});

        final response = http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': summary}
              }
            ]
          }),
          200,
        );
        when(mockHttpClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => response);

        // Act & Assert
        expect(
          () => aiService.extractAndStoreMemories(
            user: user,
            conversation: history,
          ),
          returnsNormally,
        );
      });

      test('should return when offline', () async {
        // Arrange
        final user = app_user.User(
          id: '123',
          userName: 'Test User',
          email: 'test@example.com',
          aiPalName: 'Test Pal',
          hasSeenWelcome: true,
        );
        final history = <Map<String, String>>[];

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);

        // Act & Assert
        expect(
          () => aiService.extractAndStoreMemories(
            user: user,
            conversation: history,
          ),
          returnsNormally,
        );
        verifyZeroInteractions(mockHttpClient);
      });

      test('should return when API key is missing', () async {
        // Arrange
        aiService = AIService(
          httpClient: mockHttpClient,
          firestore: mockFirestore,
          connectivity: mockConnectivity,
          apiKey: null,
        );
        final user = app_user.User(
          id: '123',
          userName: 'Test User',
          email: 'test@example.com',
          aiPalName: 'Test Pal',
          hasSeenWelcome: true,
        );
        final history = <Map<String, String>>[];

        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        // Act & Assert
        expect(
          () => aiService.extractAndStoreMemories(
            user: user,
            conversation: history,
          ),
          returnsNormally,
        );
        verifyZeroInteractions(mockHttpClient);
      });
    });
  });
}
