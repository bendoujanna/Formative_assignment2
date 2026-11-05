import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Shown after registering until the email address is verified.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  Future<void> _checkVerified(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final verified = await auth.checkEmailVerified();

    // When verified, AuthGate moves on to the home screen by itself.
    if (!verified) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Your email is not verified yet.'),
        ),
      );
    }
  }

  Future<void> _resend(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final sent = await auth.resendVerificationEmail();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          sent
              ? 'Verification email sent. Check your inbox and spam folder.'
              : auth.errorMessage ?? 'Could not send the email.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final email = auth.firebaseUser?.email ?? 'your email';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to $email. Open it, then come back and tap the button below. If you cannot find the email, check your spam folder.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: auth.isBusy
                        ? null
                        : () => _checkVerified(context),
                    child: auth.isBusy
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Text('I have verified my email'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: auth.isBusy ? null : () => _resend(context),
                    child: const Text('Resend verification email'),
                  ),
                  TextButton(
                    onPressed: auth.isBusy ? null : auth.signOut,
                    child: const Text('Use a different account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
