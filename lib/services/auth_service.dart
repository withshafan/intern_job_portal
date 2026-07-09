import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_model;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user (Firebase User object)
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign up with email/password and create user document in Firestore
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // 'admin' or 'intern'
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? firebaseUser = result.user;
      if (firebaseUser != null) {
        // Create user document in Firestore
        app_model.User newUser = app_model.User(
          id: firebaseUser.uid,
          name: name,
          email: email,
          role: role,
        );
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toMap());
        return firebaseUser;
      }
      return null;
    } catch (e) {
      print('SignUp error: $e');
      return null;
    }
  }

  // Sign in with email/password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('SignIn error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user document data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }
}
