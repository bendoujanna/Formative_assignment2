import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>(
      (auth) => auth.status,
    );

    switch (status) {
      case AuthStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.signedOut:
        return const AuthFlow();
      case AuthStatus.needsVerification:
        return const VerifyEmailScreen();
      case AuthStatus.signedIn:
        return const MainShell();
    }
  }
}

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  bool _showRegister = false;

  @override
  Widget build(BuildContext context) {
    if (_showRegister) {
      return RegisterScreen(
        onBackToLogin: () => setState(() => _showRegister = false),
      );
    }
    return LoginScreen(
      onCreateAccount: () => setState(() => _showRegister = true),
    );
  }
}
