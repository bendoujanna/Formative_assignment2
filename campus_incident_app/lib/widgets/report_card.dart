import 'package:flutter/material.dart';

import '../core/date_helpers.dart';
import '../models/incident.dart';
import 'incident_style.dart';
import 'status_chip.dart';

/// One report as a card: picture or category icon, title, place, time, status.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.incident,
    this.showReporter = false,
    this.onTap,
  });

  final Incident incident;

  /// Staff see who sent the report. Students only see their own reports.
  final bool showReporter;

  final VoidCallback? onTap;

  static const double _thumbSize = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleColor = theme.colorScheme.onSurfaceVariant;

    final timeText = timeAgo(incident.createdAt);
    final detailsText = showReporter
        ? '$timeText - ${incident.reporterName}'
        : timeText;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(theme),
              const SizedBox(width: 12),
              // Expanded gives the text the space left after the picture and
              // the status chip, so long titles are cut with dots, not overflow.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            incident.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (incident.isUrgent)
                          Tooltip(
                            message: 'Urgent',
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: theme.colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: subtleColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            incident.fullLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subtleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: subtleColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            detailsText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: subtleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: incident.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme) {
    if (incident.hasPhoto) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          incident.photoUrl!,
          width: _thumbSize,
          height: _thumbSize,
          fit: BoxFit.cover,
          // If the picture cannot load, fall back to the category icon.
          errorBuilder: (context, error, stackTrace) => _iconBox(theme),
        ),
      );
    }
    return _iconBox(theme);
  }

  Widget _iconBox(ThemeData theme) {
    return Container(
      width: _thumbSize,
      height: _thumbSize,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        categoryIcon(incident.category),
        color: theme.colorScheme.primary,
        size: 28,
      ),
    );
  }
}
