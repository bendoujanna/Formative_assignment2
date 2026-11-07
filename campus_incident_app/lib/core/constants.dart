/// Values shared across the app
class AppConstants {
  static const List<String> allowedEmailDomains = [
    'alustudent.com',
    'alueducation.com',
  ];

  static const String usersCollection = 'users';
  static const String incidentsCollection = 'incidents';

  static const String photosCollection = 'photos';

  static const String incidentPhotosFolder = 'incident_photos';

  /// Switch for photo storage
  /// true  = photos go to cloudinary storage
  /// false = photos are compressed and saved inside Firestore instead
  static const bool useFirebaseStorage = true;

  static const int maxInlinePhotoBytes = 450000;
  static const double photoMaxWidth = useFirebaseStorage ? 1600 : 1024;
  static const int photoQuality = useFirebaseStorage ? 80 : 60;

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
