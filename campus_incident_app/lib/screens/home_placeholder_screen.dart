import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: auth.signOut,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hello, ${profile?.name ?? ''}',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(profile?.email ?? '', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Chip(label: Text(auth.isStaff ? 'Staff' : 'Student')),
          ],
        ),
      ),
    );
  }
}
