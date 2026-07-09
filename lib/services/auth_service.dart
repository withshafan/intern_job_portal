import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? getCurrentUser() => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email/password and create Firestore user doc
  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = result.user;
    if (firebaseUser != null) {
      final newUser = AppUser(
        id: firebaseUser.uid,
        name: name,
        email: email,
        role: role,
      );
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(newUser.toMap());
    }
    return firebaseUser;
  }

  // Sign in
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // Sign out
  Future<void> signOut() async => _auth.signOut();

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }
}
