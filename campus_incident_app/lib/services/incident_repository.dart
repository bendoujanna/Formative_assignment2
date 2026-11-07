import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/incident.dart';

class IncidentRepository {
  IncidentRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection(AppConstants.incidentsCollection);

  CollectionReference<Map<String, dynamic>> get _photos =>
      _db.collection(AppConstants.photosCollection);

  Stream<List<Incident>> watchMyIncidents(String uid) {
    return _incidents
        .where('reporterId', isEqualTo: uid)
        .snapshots()
        .map(_toSortedList);
  }

  /// Staff see every report
  Stream<List<Incident>> watchAllIncidents() {
    return _incidents.snapshots().map(_toSortedList);
  }

  Future<void> create(Incident incident, {Uint8List? inlinePhoto}) async {
    final doc = _incidents.doc();

    if (inlinePhoto == null) {
      await doc.set(incident.toCreateMap());
      return;
    }

    final batch = _db.batch();
    batch.set(doc, incident.toCreateMap());
    batch.set(_photos.doc(doc.id), {
      'ownerId': incident.reporterId,
      'data': base64Encode(inlinePhoto),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  /// Staff change the status. Each stage keeps its own time, which is what
  /// the timeline on the details screen shows
  Future<void> updateStatus({
    required String incidentId,
    required IncidentStatus status,
    required String staffName,
    String? note,
  }) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedByName': staffName,
    };

    final trimmedNote = note?.trim() ?? '';
    if (trimmedNote.isNotEmpty) updates['staffNote'] = trimmedNote;

    switch (status) {
      case IncidentStatus.submitted:
        updates['inProgressAt'] = FieldValue.delete();
        updates['resolvedAt'] = FieldValue.delete();
      case IncidentStatus.inProgress:
        updates['inProgressAt'] = FieldValue.serverTimestamp();
        updates['resolvedAt'] = FieldValue.delete();
      case IncidentStatus.resolved:
        updates['resolvedAt'] = FieldValue.serverTimestamp();
    }

    await _incidents.doc(incidentId).update(updates);
  }

  Future<void> delete(Incident incident) async {
    final batch = _db.batch();
    batch.delete(_incidents.doc(incident.id));
    if (incident.hasInlinePhoto) batch.delete(_photos.doc(incident.id));
    await batch.commit();
  }

  Future<Uint8List?> getInlinePhoto(String incidentId) async {
    final snapshot = await _photos.doc(incidentId).get();
    final data = snapshot.data()?['data'];
    if (data is! String) return null;
    return base64Decode(data);
  }

  /// Newest first
  List<Incident> _toSortedList(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final list = snapshot.docs
        .map((doc) => Incident.fromMap(doc.id, doc.data()))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
