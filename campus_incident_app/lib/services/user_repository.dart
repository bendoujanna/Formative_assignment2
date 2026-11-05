import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/app_user.dart';

/// Reads and writes user profiles in Firestore (users/{uid}).
class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.usersCollection);

  Future<AppUser?> getUser(String uid) async {
    final snapshot = await _users.doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    return AppUser.fromMap(uid, data);
  }

  Future<AppUser> createStudentProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _users.doc(uid).set({
      'name': name,
      'email': email,
      'role': UserRole.student.name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final created = await getUser(uid);
    return created ??
        AppUser(uid: uid, name: name, email: email, role: UserRole.student);
  }
}
