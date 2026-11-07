import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/date_helpers.dart';
import '../models/incident.dart';
import '../providers/incident_provider.dart';
import 'incident_style.dart';
import 'status_chip.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.incident,
    this.showReporter = false,
    this.onTap,
  });

  final Incident incident;
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
          errorBuilder: (context, error, stackTrace) => _iconBox(theme),
        ),
      );
    }
    if (incident.hasInlinePhoto) {
      return _InlineThumbnail(
        incidentId: incident.id,
        size: _thumbSize,
        fallback: _iconBox(theme),
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

class _InlineThumbnail extends StatefulWidget {
  const _InlineThumbnail({
    required this.incidentId,
    required this.size,
    required this.fallback,
  });

  final String incidentId;
  final double size;
  final Widget fallback;

  @override
  State<_InlineThumbnail> createState() => _InlineThumbnailState();
}

class _InlineThumbnailState extends State<_InlineThumbnail> {
  Future<Uint8List?>? _photoFuture;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  @override
  void didUpdateWidget(covariant _InlineThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.incidentId != widget.incidentId) {
      _loadPhoto();
    }
  }

  void _loadPhoto() {
    _photoFuture = context.read<IncidentProvider>().loadInlinePhoto(
      widget.incidentId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _photoFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return widget.fallback;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => widget.fallback,
          ),
        );
      },
    );
  }
}
