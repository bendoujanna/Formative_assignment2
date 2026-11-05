import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/report_card.dart';
import '../widgets/summary_card.dart';
import 'report_form_screen.dart';

/// The first tab: a greeting, a call to action, a summary and recent reports.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenReports});

  /// Switches the shell to the Reports tab.
  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final incidents = context.watch<IncidentProvider>();
    final theme = Theme.of(context);

    final profile = auth.profile;
    final isStaff = auth.isStaff;
    final firstName = (profile?.name ?? '').split(' ').first;
    final recent = incidents.incidents.take(3).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(theme, firstName, profile?.initials ?? '?', isStaff),
          const SizedBox(height: 20),
          if (isStaff)
            _HeroBanner(
              title: 'Staff dashboard',
              message:
                  '${incidents.countFor(IncidentStatus.submitted)} reports are waiting for review.',
              buttonLabel: 'Review reports',
              buttonIcon: Icons.fact_check_outlined,
              onPressed: () {
                incidents.setStatusFilter(IncidentStatus.submitted);
                onOpenReports();
              },
            )
          else
            _HeroBanner(
              title: 'See an issue on campus?',
              message: 'Report it and help improve our learning environment.',
              buttonLabel: 'Report an Issue',
              buttonIcon: Icons.add_circle_outline,
              onPressed: () => ReportFormScreen.open(context),
            ),
          const SizedBox(height: 24),
          Text(
            'Report Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummary(incidents, isStaff),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Reports',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  incidents.setStatusFilter(null);
                  onOpenReports();
                },
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildRecent(incidents, recent, isStaff),
        ],
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    String firstName,
    String initials,
    bool isStaff,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $firstName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isStaff ? 'Review reports and keep students updated.' : 'Help make our campus safer. Report issues and track their resolution.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            initials,
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(IncidentProvider incidents, bool isStaff) {
    // Tapping a card opens the Reports tab already filtered to that status.
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            icon: Icons.description_outlined,
            color: AppTheme.primary,
            value: incidents.totalCount,
            label: isStaff ? 'All Reports' : 'My Reports',
            onTap: () {
              incidents.setStatusFilter(null);
              onOpenReports();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SummaryCard(
            icon: Icons.schedule,
            color: const Color(0xFF2D5BD6),
            value: incidents.countFor(IncidentStatus.inProgress),
            label: 'In Progress',
            onTap: () {
              incidents.setStatusFilter(IncidentStatus.inProgress);
              onOpenReports();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SummaryCard(
            icon: Icons.check_circle_outline,
            color: const Color(0xFF1B7A3E),
            value: incidents.countFor(IncidentStatus.resolved),
            label: 'Resolved',
            onTap: () {
              incidents.setStatusFilter(IncidentStatus.resolved);
              onOpenReports();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SummaryCard(
            icon: Icons.error_outline,
            color: const Color(0xFFD9822B),
            value: incidents.countFor(IncidentStatus.submitted),
            label: 'Submitted',
            onTap: () {
              incidents.setStatusFilter(IncidentStatus.submitted);
              onOpenReports();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecent(
    IncidentProvider incidents,
    List<Incident> recent,
    bool isStaff,
  ) {
    if (incidents.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (incidents.errorMessage != null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        message: incidents.errorMessage!,
      );
    }
    if (recent.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        message: isStaff
            ? 'No reports have been submitted yet.'
            : 'No reports yet. Tap Report an Issue to send your first one.',
      );
    }
    return Column(
      children: [
        for (final incident in recent)
          ReportCard(incident: incident, showReporter: isStaff),
      ],
    );
  }
}

/// The big purple card at the top of the home screen.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF9B7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
            ),
            onPressed: onPressed,
            icon: Icon(buttonIcon),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
