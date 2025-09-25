import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up a new user
  Future<User?> signUp({
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
      if (credential.user != null) {
        final newUser = User(
          id: credential.user!.uid,
          userName: usersName,
          email: email,
          aiPalName: aiPalName,
          hasSeenWelcome: false,
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(newUser.toJson());
        return newUser;
      }
    } catch (e) {
      // Handle exceptions
      print(e);
    }
    return null;
  }

  // Log in a user
  Future<User?> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        final userDoc =
            await _firestore.collection('users').doc(credential.user!.uid).get();
        if (userDoc.exists) {
          return User.fromJson(userDoc.data()!);
        }
      }
    } catch (e) {
      // Handle exceptions
      print(e);
    }
    return null;
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