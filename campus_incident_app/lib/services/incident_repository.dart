import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/incident.dart';

class IncidentRepository {
  IncidentRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection(AppConstants.incidentsCollection);

  Stream<List<Incident>> watchMyIncidents(String uid) {
    return _incidents
        .where('reporterId', isEqualTo: uid)
        .snapshots()
        .map(_toSortedList);
  }

  /// Staff see every report.
  Stream<List<Incident>> watchAllIncidents() {
    return _incidents.snapshots().map(_toSortedList);
  }

  Future<void> create(Incident incident) async {
    await _incidents.doc().set(incident.toCreateMap());
  }

  Future<void> delete(String incidentId) async {
    await _incidents.doc(incidentId).delete();
  }

  List<Incident> _toSortedList(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final list = snapshot.docs
        .map((doc) => Incident.fromMap(doc.id, doc.data()))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
