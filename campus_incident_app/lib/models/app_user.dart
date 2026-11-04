import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, staff }

/// The profile of a signed-in person, stored in users/{uid} in Firestore.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final DateTime? createdAt;

  bool get isStaff => role == UserRole.staff;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final roleName = map['role'] as String?;
    return AppUser(
      uid: uid,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      // An unknown or missing role becomes student: the safest default.
      role: UserRole.values.firstWhere(
        (r) => r.name == roleName,
        orElse: () => UserRole.student,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
