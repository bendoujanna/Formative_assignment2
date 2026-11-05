/// Values shared across the app
class AppConstants {
  static const List<String> allowedEmailDomains = [
    'alustudent.com',
    'alueducation.com',
  ];

  static const String usersCollection = 'users';
  static const String incidentsCollection = 'incidents';

  /// Folder in Firebase Storage where incident photos are kept
  static const String incidentPhotosFolder = 'incident_photos';

  /// Areas a student can pick when reporting a problem
  static const List<String> campusLocations = [
    'Classroom block',
    'Library',
    'Student residence',
    'Cafeteria',
    'Sports facilities',
    'Parking and grounds',
    'Other',
  ];
}
