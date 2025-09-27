import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'error_service.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Sign up a new user
  Future<User> signUp({
    required String email,
    required String password,
    required String usersName,
    required String aiPalName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw Exception('User not created');
      }
      final newUser = User(
        id: credential.user!.uid,
        userName: usersName,
        email: email,
        aiPalName: aiPalName,
        hasSeenWelcome: false,
        personalityTraits: const ['Friendly', 'Supportive'],
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(newUser.toJson());
      return newUser;
    } catch (e, stackTrace) {
      ErrorService.handleError(e, stackTrace);
      rethrow;
    }
  }

  // Log in a user
  Future<User> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw Exception('User not found');
      }
      final userDoc =
          await _firestore.collection('users').doc(credential.user!.uid).get();
      if (userDoc.exists) {
        return User.fromJson(userDoc.data()!);
      }
      throw Exception('User not found in database');
    } catch (e, stackTrace) {
      ErrorService.handleError(e, stackTrace);
      rethrow;
    }
  }

  // Log out the current user
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  // Get the currently logged-in user
  Stream<User?> get currentUser {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser != null) {
        final userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (userDoc.exists) {
          return User.fromJson(userDoc.data()!);
        }
      }
      return null;
    });
  }

  // Mark welcome screen as shown for the user
  Future<void> markWelcomeAsSeen(User user) async {
    await _firestore
        .collection('users')
        .doc(user.id)
        .update({'hasSeenWelcome': true});
  }
}