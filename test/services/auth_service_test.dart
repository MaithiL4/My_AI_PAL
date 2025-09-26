
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_ai_pal/models/user.dart' as app_user;
import 'package:my_ai_pal/services/auth_service.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([
  firebase_auth.FirebaseAuth,
  firebase_auth.UserCredential,
  firebase_auth.User,
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
])
void main() {
  late AuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUserCredential mockUserCredential;
  late MockUser mockUser;
  late MockCollectionReference<Map<String, dynamic>> mockCollectionReference;
  late MockDocumentReference<Map<String, dynamic>> mockDocumentReference;
  late MockDocumentSnapshot<Map<String, dynamic>> mockDocumentSnapshot;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    authService = AuthService(
      firebaseAuth: mockFirebaseAuth,
      firestore: mockFirestore,
    );
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    mockCollectionReference = MockCollectionReference<Map<String, dynamic>>();
    mockDocumentReference = MockDocumentReference<Map<String, dynamic>>();
    mockDocumentSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
  });

  group('AuthService', () {
    group('login', () {
      test('should return a User when login is successful', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password';
        const uid = '123';
        final userJson = {
          'id': uid,
          'userName': 'Test User',
          'email': email,
          'aiPalName': 'Test Pal',
          'hasSeenWelcome': false,
        };

        when(mockFirebaseAuth.signInWithEmailAndPassword(email: email, password: password))
            .thenAnswer((_) async => mockUserCredential);
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockUser.uid).thenReturn(uid);
        when(mockFirestore.collection('users')).thenReturn(mockCollectionReference);
        when(mockCollectionReference.doc(uid)).thenReturn(mockDocumentReference);
        when(mockDocumentReference.get()).thenAnswer((_) async => mockDocumentSnapshot);
        when(mockDocumentSnapshot.exists).thenReturn(true);
        when(mockDocumentSnapshot.data()).thenReturn(userJson);

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result, isA<app_user.User>());
        expect(result!.id, uid);
      });
    });
  });
}
