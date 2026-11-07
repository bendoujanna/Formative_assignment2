import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/incident.dart';

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step(
        label: 'Submitted',
        date: incident.createdAt,
        reached: true,
        isActive: false,
      ),
      _Step(
        label: 'In Progress',
        date: incident.inProgressAt,
        reached: incident.status != IncidentStatus.submitted,
        isActive: incident.status == IncidentStatus.inProgress,
      ),
      _Step(
        label: 'Resolved',
        date: incident.resolvedAt,
        reached: incident.status == IncidentStatus.resolved,
        isActive: false,
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: _StepView(
              step: steps[i],
              showLeftLine: i > 0,
              leftLineActive: steps[i].reached,
              showRightLine: i < steps.length - 1,
              rightLineActive: i < steps.length - 1 && steps[i + 1].reached,
            ),
          ),
      ],
    );
  }
}

class _Step {
  const _Step({
    required this.label,
    required this.date,
    required this.reached,
    required this.isActive,
  });

  final String label;
  final DateTime? date;
  final bool reached;
  final bool isActive;
}

class _StepView extends StatelessWidget {
  const _StepView({
    required this.step,
    required this.showLeftLine,
    required this.leftLineActive,
    required this.showRightLine,
    required this.rightLineActive,
  });

  final _Step step;
  final bool showLeftLine;
  final bool leftLineActive;
  final bool showRightLine;
  final bool rightLineActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final inactive = theme.colorScheme.outlineVariant;

    final date = step.date;
    final dateText = date != null
        ? DateFormat('MMM d\nh:mm a').format(date)
        : (step.reached ? '' : '-');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 3,
                color: showLeftLine
                    ? (leftLineActive ? primary : inactive)
                    : Colors.transparent,
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.reached ? primary : Colors.transparent,
                border: Border.all(
                  color: step.reached ? primary : inactive,
                  width: 2,
                ),
              ),
              child: step.reached
                  ? Icon(
                      step.isActive ? Icons.sync : Icons.check,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    )
                  : null,
            ),
            Expanded(
              child: Container(
                height: 3,
                color: showRightLine
                    ? (rightLineActive ? primary : inactive)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          step.label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: step.reached ? null : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          dateText,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
