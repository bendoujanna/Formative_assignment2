import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../widgets/incident_style.dart';
import '../widgets/status_chip.dart';
import 'report_form_screen.dart';

class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final incidents = context.watch<IncidentProvider>();
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hello, ${auth.profile?.name ?? ''}',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(label: Text(auth.isStaff ? 'Staff' : 'Student')),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ReportFormScreen())),
            icon: const Icon(Icons.add),
            label: const Text('Report an issue'),
          ),
          const SizedBox(height: 24),
          Text(
            auth.isStaff ? 'All reports' : 'My reports',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (incidents.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (incidents.errorMessage != null)
            Text(incidents.errorMessage!)
          else if (incidents.incidents.isEmpty)
            const Text('No reports yet.')
          else
            for (final incident in incidents.incidents)
              _ReportTile(incident: incident),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('MMM d, h:mm a').format(incident.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(child: Icon(categoryIcon(incident.category))),
        title: Text(
          incident.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${incident.fullLocation} - $when',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: StatusChip(status: incident.status),
      ),
    );
  }
}
