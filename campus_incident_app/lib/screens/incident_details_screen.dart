import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/incident_photo.dart';
import '../widgets/incident_style.dart';
import '../widgets/status_chip.dart';
import '../widgets/status_timeline.dart';

class IncidentDetailsScreen extends StatelessWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});

  final String incidentId;

  static Future<void> open(BuildContext context, String incidentId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IncidentDetailsScreen(incidentId: incidentId),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Incident incident) async {
    final provider = context.read<IncidentProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete report?'),
        content: Text('"${incident.title}" will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await provider.deleteReport(incident);
    if (success) {
      messenger.showSnackBar(const SnackBar(content: Text('Report deleted')));
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.actionErrorMessage ?? 'Could not delete the report.',
          ),
        ),
      );
    }
  }

  Future<void> _showStatusSheet(BuildContext context, Incident incident) async {
    final provider = context.read<IncidentProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StatusSheet(incident: incident),
    );

    if (saved == true) {
      messenger.showSnackBar(const SnackBar(content: Text('Status updated')));
    } else if (saved == false) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.actionErrorMessage ?? 'Could not update the status.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = context.watch<IncidentProvider>().findById(incidentId);
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    if (incident == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Incident Details')),
        body: const EmptyState(
          icon: Icons.search_off,
          message: 'This report no longer exists.',
        ),
      );
    }

    final isStaff = auth.isStaff;
    final canDelete =
        !isStaff &&
        incident.reporterId == auth.profile?.uid &&
        incident.status == IncidentStatus.submitted;
    final staffNote = incident.staffNote;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
        actions: [
          if (canDelete)
            IconButton(
              tooltip: 'Delete report',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, incident),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            incident.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusChip(status: incident.status),
              if (incident.isUrgent) const _UrgentChip(),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: categoryIcon(incident.category),
                    label: 'Category',
                    value: incident.category.label,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.place_outlined,
                    label: 'Location',
                    value: incident.fullLocation,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Submitted',
                    value: DateFormat('MMM d, yyyy - h:mm a')
                        .format(incident.createdAt),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Reported by',
                    value: incident.reporterName,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Status Timeline',
            child: StatusTimeline(incident: incident),
          ),
          if (staffNote != null && staffNote.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Message from staff',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staffNote, style: theme.textTheme.bodyMedium),
                  if (incident.updatedByName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '- ${incident.updatedByName}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Description',
            child: Text(
              incident.description,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (incident.hasAnyPhoto) ...[
            const SizedBox(height: 16),
            Text(
              'Attached Photo',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            IncidentPhoto(incident: incident),
          ],
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: isStaff
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => _showStatusSheet(context, incident),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Update status'),
                ),
              ),
            )
          : null,
    );
  }
}

class _UrgentChip extends StatelessWidget {
  const _UrgentChip();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'Urgent',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusSheet extends StatefulWidget {
  const _StatusSheet({required this.incident});

  final Incident incident;

  @override
  State<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends State<_StatusSheet> {
  late final TextEditingController _noteController = TextEditingController(
    text: widget.incident.staffNote ?? '',
  );
  late IncidentStatus _selected = widget.incident.status;
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<IncidentProvider>();
    setState(() => _isSaving = true);

    final success = await provider.updateStatus(
      widget.incident,
      _selected,
      note: _noteController.text,
    );

    if (mounted) Navigator.pop(context, success);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Update status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<IncidentStatus>(
              segments: [
                for (final status in IncidentStatus.values)
                  ButtonSegment(value: status, label: Text(status.label)),
              ],
              selected: {_selected},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _selected = selection.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLength: 200,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Message to the student (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
