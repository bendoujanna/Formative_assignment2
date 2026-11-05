import 'package:cloud_firestore/cloud_firestore.dart';

enum IncidentCategory {
  facilities,
  furniture,
  water,
  electricity,
  sanitation,
  safety,
}

/// submitted, then in progress, then resolved.
enum IncidentStatus { submitted, inProgress, resolved }

extension IncidentCategoryLabel on IncidentCategory {
  String get label {
    switch (this) {
      case IncidentCategory.facilities:
        return 'Facilities';
      case IncidentCategory.furniture:
        return 'Furniture';
      case IncidentCategory.water:
        return 'Water';
      case IncidentCategory.electricity:
        return 'Electricity';
      case IncidentCategory.sanitation:
        return 'Sanitation';
      case IncidentCategory.safety:
        return 'Safety';
    }
  }
}

extension IncidentStatusLabel on IncidentStatus {
  String get label {
    switch (this) {
      case IncidentStatus.submitted:
        return 'Submitted';
      case IncidentStatus.inProgress:
        return 'In Progress';
      case IncidentStatus.resolved:
        return 'Resolved';
    }
  }
}

/// One incident report, stored in incidents/{id} in Firestore.
class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.locationDetails = '',
    this.isUrgent = false,
    this.photoUrl,
    this.photoPath,
    this.status = IncidentStatus.submitted,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    this.updatedAt,
    this.inProgressAt,
    this.resolvedAt,
    this.staffNote,
    this.updatedByName,
  });

  factory Incident.draft({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    String locationDetails = '',
    String? photoUrl,
    String? photoPath,
    required String reporterId,
    required String reporterName,
  }) {
    return Incident(
      id: '',
      title: title,
      description: description,
      category: category,
      location: location,
      locationDetails: locationDetails,
      // Safety problems are flagged as urgent automatically
      isUrgent: category == IncidentCategory.safety,
      photoUrl: photoUrl,
      photoPath: photoPath,
      reporterId: reporterId,
      reporterName: reporterName,
      createdAt: DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final String locationDetails;
  final bool isUrgent;
  final String? photoUrl;
  final String? photoPath;
  final IncidentStatus status;
  final String reporterId;
  final String reporterName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? inProgressAt;
  final DateTime? resolvedAt;
  final String? staffNote;
  final String? updatedByName;

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Location as one line, for example "Student residence, Room 204".
  String get fullLocation =>
      locationDetails.isEmpty ? location : '$location, $locationDetails';

  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    return Incident(
      id: id,
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      category: _enumByName(
        IncidentCategory.values,
        map['category'] as String?,
        IncidentCategory.facilities,
      ),
      location: (map['location'] as String?) ?? '',
      locationDetails: (map['locationDetails'] as String?) ?? '',
      isUrgent: (map['isUrgent'] as bool?) ?? false,
      photoUrl: map['photoUrl'] as String?,
      photoPath: map['photoPath'] as String?,
      status: _enumByName(
        IncidentStatus.values,
        map['status'] as String?,
        IncidentStatus.submitted,
      ),
      reporterId: (map['reporterId'] as String?) ?? '',
      reporterName: (map['reporterName'] as String?) ?? '',
      createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(map['updatedAt']),
      inProgressAt: _toDate(map['inProgressAt']),
      resolvedAt: _toDate(map['resolvedAt']),
      staffNote: map['staffNote'] as String?,
      updatedByName: map['updatedByName'] as String?,
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'location': location,
      'locationDetails': locationDetails,
      'isUrgent': isUrgent,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoPath != null) 'photoPath': photoPath,
      'status': IncidentStatus.submitted.name,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

DateTime? _toDate(Object? value) => value is Timestamp ? value.toDate() : null;

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  return values.firstWhere((v) => v.name == name, orElse: () => fallback);
}
