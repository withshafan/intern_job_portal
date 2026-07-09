import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _currentUser;
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  String? get error => _error;
  bool get loading => _loading;
  bool get isAdmin => _currentUser?.role == 'admin';

  AuthProvider() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
      } else {
        _currentUser = await _userService.getCurrentUserData();
        _status = AuthStatus.authenticated;
      }
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.signIn(email: email, password: password);
    } on Exception catch (e) {
      _error = _friendlyError(e.toString());
      _setLoading(false);
      notifyListeners();
    }
    _setLoading(false);
  }

  Future<void> signup({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
      );
    } on Exception catch (e) {
      _error = _friendlyError(e.toString());
      _setLoading(false);
      notifyListeners();
    }
    _setLoading(false);
  }

  Future<void> logout() async {
    await _authService.signOut();
  }

  Future<void> refreshUser() async {
    _currentUser = await _userService.getCurrentUserData();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found')) return 'No account found with this email.';
    if (raw.contains('wrong-password')) return 'Incorrect password.';
    if (raw.contains('email-already-in-use')) return 'Email is already registered.';
    if (raw.contains('weak-password')) return 'Password is too weak (min 6 chars).';
    if (raw.contains('network-request-failed')) return 'No internet connection.';
    if (raw.contains('invalid-email')) return 'Invalid email address.';
    return 'Something went wrong. Please try again.';
  }
}
