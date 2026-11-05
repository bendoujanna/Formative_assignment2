import 'package:flutter/material.dart';

import '../models/incident.dart';

IconData categoryIcon(IncidentCategory category) {
  switch (category) {
    case IncidentCategory.facilities:
      return Icons.apartment;
    case IncidentCategory.furniture:
      return Icons.chair_alt;
    case IncidentCategory.water:
      return Icons.water_drop_outlined;
    case IncidentCategory.electricity:
      return Icons.bolt;
    case IncidentCategory.sanitation:
      return Icons.delete_outline;
    case IncidentCategory.safety:
      return Icons.shield_outlined;
  }
}

class StatusColors {
  const StatusColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

StatusColors statusColors(IncidentStatus status) {
  switch (status) {
    case IncidentStatus.submitted:
      return const StatusColors(
        background: Color(0xFFFFF1D6),
        foreground: Color(0xFF9A6300),
      );
    case IncidentStatus.inProgress:
      return const StatusColors(
        background: Color(0xFFE3ECFF),
        foreground: Color(0xFF2D5BD6),
      );
    case IncidentStatus.resolved:
      return const StatusColors(
        background: Color(0xFFDDF5E5),
        foreground: Color(0xFF1B7A3E),
      );
  }
}
