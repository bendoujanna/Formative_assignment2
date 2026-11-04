import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';

enum AuthStatus { loading, signedOut, needsVerification, signedIn }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService, UserRepository? userRepository})
    : _authService = authService ?? AuthService(),
      _userRepository = userRepository ?? UserRepository() {
    _subscription = _authService.authStateChanges.listen(_onAuthChanged);
  }

  final AuthService _authService;
  final UserRepository _userRepository;
  StreamSubscription<User?>? _subscription;

  AuthStatus _status = AuthStatus.loading;
  User? _firebaseUser;
  AppUser? _profile;
  bool _isBusy = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  AppUser? get profile => _profile;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  bool get isStaff => _profile?.isStaff ?? false;

  // Actions called by the screens
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _runAuthAction(() async {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      await _userRepository.createStudentProfile(
        uid: user.uid,
        name: name,
        email: user.email ?? email,
      );
    });
  }

  Future<bool> login({required String email, required String password}) {
    return _runAuthAction(() async {
      await _authService.signIn(email: email, password: password);
    });
  }

  Future<void> signOut() => _authService.signOut();

  /// Called by the "I have verified my email" button
  Future<bool> checkEmailVerified() async {
    _errorMessage = null;
    _setBusy(true);
    try {
      final user = await _authService.reloadUser();
      _setBusy(false);
      await _applyUser(user);
    } on FirebaseAuthException catch (e) {
      _errorMessage = _messageForCode(e.code);
    } catch (e) {
      debugPrint('Email check failed: $e');
      _errorMessage = 'Could not check your email status. Please try again.';
    } finally {
      _setBusy(false);
    }
    return _status == AuthStatus.signedIn;
  }

  Future<bool> resendVerificationEmail() async {
    _errorMessage = null;
    _setBusy(true);
    try {
      await _authService.sendVerificationEmail();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _messageForCode(e.code);
      return false;
    } catch (e) {
      debugPrint('Resend failed: $e');
      _errorMessage = 'Could not send the email. Please try again.';
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // Internals
  /// Runs a login or register action with the same loading and error handling.
  Future<bool> _runAuthAction(Future<void> Function() action) async {
    _errorMessage = null;
    _setBusy(true);
    var succeeded = true;

    try {
      await action();
    } on FirebaseAuthException catch (e) {
      _errorMessage = _messageForCode(e.code);
      succeeded = false;
    } catch (e) {
      debugPrint('Auth action failed: $e');
      _errorMessage = 'Something went wrong. Please try again.';
      succeeded = false;
    }

    _setBusy(false);
    // Whatever happened, bring the app state in line with Firebase.
    await _applyUser(_authService.currentUser);
    return succeeded && _errorMessage == null;
  }

  Future<void> _onAuthChanged(User? user) async {
    // While login or register is running, that method updates the state itself.
    if (_isBusy) return;
    await _applyUser(user);
  }

  Future<void> _applyUser(User? user) async {
    _firebaseUser = user;

    if (user == null) {
      _profile = null;
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }

    try {
      // If the profile is missing (for example an interrupted sign-up),
      // create it now so the person is never locked out.
      _profile =
          await _userRepository.getUser(user.uid) ??
          await _userRepository.createStudentProfile(
            uid: user.uid,
            name: user.displayName ?? _nameFromEmail(user.email),
            email: user.email ?? '',
          );
      _status = user.emailVerified
          ? AuthStatus.signedIn
          : AuthStatus.needsVerification;
      notifyListeners();
    } catch (e) {
      debugPrint('Profile load failed: $e');
      _errorMessage =
          'Could not load your profile. Check your connection and try again.';
      // Signing out triggers _onAuthChanged(null), which shows the login screen.
      await _authService.signOut();
    }
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  String _nameFromEmail(String? email) {
    final local = (email ?? '').split('@').first;
    return local.isEmpty ? 'Student' : local;
  }

  /// Turns Firebase error codes into messages a student can understand.
  String _messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'That password is too weak. Use at least 8 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
