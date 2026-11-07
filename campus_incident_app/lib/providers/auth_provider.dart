import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
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
  bool get isStaff => _profile?.isStaff ?? false;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  Future<void> _onAuthChanged(User? user) async {
    _firebaseUser = user;

    if (user == null) {
      _profile = null;
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }

    if (!_hasAllowedDomain(user.email)) {
      await _authService.signOut();
      _errorMessage = 'Please sign in with your ALU email address.';
      _status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }

    if (!user.emailVerified) {
      _status = AuthStatus.needsVerification;
      notifyListeners();
      return;
    }

    await _loadOrCreateProfile(user);
  }

  Future<void> _loadOrCreateProfile(User user) async {
    try {
      var userProfile = await _userRepository.getUser(user.uid);
      userProfile ??= await _userRepository.createStudentProfile(
        uid: user.uid,
        name: (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!.trim()
            : user.email!.split('@').first,
        email: user.email!.toLowerCase(),
      );
      _profile = userProfile;
      _status = AuthStatus.signedIn;
    } catch (_) {
      _errorMessage = 'Could not load your profile.';
      _status = AuthStatus.signedOut;
    }
    notifyListeners();
  }

  bool _hasAllowedDomain(String? email) {
    if (email == null || !email.contains('@')) return false;
    final domain = email.toLowerCase().split('@').last;
    return AppConstants.allowedEmailDomains.contains(domain);
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      await _userRepository.createStudentProfile(
        uid: user.uid,
        name: name,
        email: email,
      );
      _setBusy(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyAuthError(e);
      _setBusy(false);
      return false;
    } catch (_) {
      _errorMessage = 'Could not create your account. Please try again.';
      _setBusy(false);
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setBusy(true);
    try {
      await _authService.signIn(email: email, password: password);
      _setBusy(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _friendlyAuthError(e);
      _setBusy(false);
      return false;
    } catch (_) {
      _errorMessage = 'Login failed. Please try again.';
      _setBusy(false);
      return false;
    }
  }

  Future<bool> checkEmailVerified() async {
    _setBusy(true);
    try {
      final refreshed = await _authService.reloadUser();
      _firebaseUser = refreshed;
      if (refreshed != null && refreshed.emailVerified) {
        await _loadOrCreateProfile(refreshed);
        _setBusy(false);
        return true;
      }
      _errorMessage = 'Your email is not verified yet.';
      _setBusy(false);
      return false;
    } catch (_) {
      _errorMessage = 'Could not check verification status.';
      _setBusy(false);
      return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    _setBusy(true);
    try {
      await _authService.sendVerificationEmail();
      _setBusy(false);
      return true;
    } catch (_) {
      _errorMessage = 'Please wait a moment before requesting another email.';
      _setBusy(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this ALU email already exists.';
      case 'weak-password':
        return 'Password must be at least 8 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again in a few minutes.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
