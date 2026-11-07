import 'dart:async';
import 'dart:typed_data';

import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/auth_provider.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/services/incident_repository.dart';
import 'package:campus_incident_app/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class FakeIncidentRepository implements IncidentRepository {
  final StreamController<List<Incident>> myController =
      StreamController<List<Incident>>.broadcast();
  final StreamController<List<Incident>> allController =
      StreamController<List<Incident>>.broadcast();

  int watchMyCalls = 0;
  int watchAllCalls = 0;
  int inlinePhotoFetchCalls = 0;
  IncidentStatus? lastUpdatedStatus;
  String? lastUpdatedNote;
  String? deletedId;

  @override
  Stream<List<Incident>> watchMyIncidents(String uid) {
    watchMyCalls++;
    return myController.stream;
  }

  @override
  Stream<List<Incident>> watchAllIncidents() {
    watchAllCalls++;
    return allController.stream;
  }

  @override
  Future<void> create(Incident incident, {Uint8List? inlinePhoto}) async {}

  @override
  Future<void> updateStatus({
    required String incidentId,
    required IncidentStatus status,
    required String staffName,
    String? note,
  }) async {
    lastUpdatedStatus = status;
    lastUpdatedNote = note;
  }

  @override
  Future<void> delete(Incident incident) async {
    deletedId = incident.id;
  }

  @override
  Future<Uint8List?> getInlinePhoto(String incidentId) async {
    inlinePhotoFetchCalls++;
    return Uint8List.fromList([1, 2, 3, 4]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStorageService implements StorageService {
  @override
  Future<UploadedPhoto> uploadIncidentPhoto({
    required String uid,
    required XFile file,
  }) async {
    return const UploadedPhoto(url: 'https://example.com/p.jpg', path: 'p.jpg');
  }

  @override
  Future<void> deletePhoto(String path) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeIncidentRepository fakeRepo;
  late FakeStorageService fakeStorage;
  late IncidentProvider provider;

  const studentUser = AppUser(
    uid: 'student-1',
    name: 'Amina Bako',
    email: 'amina@alustudent.com',
    role: UserRole.student,
  );

  const staffUser = AppUser(
    uid: 'staff-1',
    name: 'Sam Staff',
    email: 'staff@alueducation.com',
    role: UserRole.staff,
  );

  final sampleIncidents = [
    Incident(
      id: '1',
      title: 'Water shortage',
      description: 'There has been no water since this morning.',
      category: IncidentCategory.water,
      location: 'Student residence',
      status: IncidentStatus.submitted,
      reporterId: 'student-1',
      reporterName: 'Amina Bako',
      createdAt: DateTime(2026, 11, 3, 10, 0),
    ),
    Incident(
      id: '2',
      title: 'Broken projector',
      description: 'Projector in Room 204 does not turn on.',
      category: IncidentCategory.electricity,
      location: 'Classroom block',
      locationDetails: 'Room 204',
      status: IncidentStatus.inProgress,
      reporterId: 'student-1',
      reporterName: 'Amina Bako',
      createdAt: DateTime(2026, 11, 4, 9, 0),
    ),
    Incident(
      id: '3',
      title: 'Overflowing bin',
      description: 'Main bin outside the cafeteria is full.',
      category: IncidentCategory.sanitation,
      location: 'Cafeteria',
      status: IncidentStatus.resolved,
      reporterId: 'student-2',
      reporterName: 'Kofi Mensah',
      createdAt: DateTime(2026, 11, 5, 14, 0),
    ),
  ];

  setUp(() {
    fakeRepo = FakeIncidentRepository();
    fakeStorage = FakeStorageService();
    provider = IncidentProvider(repository: fakeRepo, storage: fakeStorage);
  });

  tearDown(() {
    provider.dispose();
    fakeRepo.myController.close();
    fakeRepo.allController.close();
  });

  group('role streams', () {
    test('students watch only their own reports, staff watch all reports', () {
      provider.updateAuth(AuthStatus.signedIn, studentUser);
      expect(fakeRepo.watchMyCalls, 1);
      expect(fakeRepo.watchAllCalls, 0);

      provider.updateAuth(AuthStatus.signedIn, staffUser);
      expect(fakeRepo.watchAllCalls, 1);
    });
  });

  group('search and filters', () {
    test('filters by status, category, and search text', () async {
      provider.updateAuth(AuthStatus.signedIn, staffUser);
      fakeRepo.allController.add(sampleIncidents);
      await Future<void>.delayed(Duration.zero);

      expect(provider.totalCount, 3);
      expect(provider.countFor(IncidentStatus.inProgress), 1);

      provider.setStatusFilter(IncidentStatus.submitted);
      expect(provider.filteredIncidents.map((i) => i.id), ['1']);

      provider.setStatusFilter(null);
      provider.setCategoryFilter(IncidentCategory.electricity);
      expect(provider.filteredIncidents.map((i) => i.id), ['2']);

      provider.setCategoryFilter(null);
      provider.setSearchQuery('room 204');
      expect(provider.filteredIncidents.map((i) => i.id), ['2']);
    });
  });

  group('permissions and caching', () {
    test('only staff can update status', () async {
      provider.updateAuth(AuthStatus.signedIn, studentUser);
      final studentAttempt = await provider.updateStatus(
        sampleIncidents.first,
        IncidentStatus.inProgress,
      );
      expect(studentAttempt, isFalse);
      expect(fakeRepo.lastUpdatedStatus, isNull);

      provider.updateAuth(AuthStatus.signedIn, staffUser);
      final staffAttempt = await provider.updateStatus(
        sampleIncidents.first,
        IncidentStatus.inProgress,
        note: 'Plumber dispatched',
      );
      expect(staffAttempt, isTrue);
      expect(fakeRepo.lastUpdatedStatus, IncidentStatus.inProgress);
      expect(fakeRepo.lastUpdatedNote, 'Plumber dispatched');
    });

    test('inline photos are fetched once and cached in memory', () async {
      await provider.loadInlinePhoto('inc-1');
      await provider.loadInlinePhoto('inc-1');

      expect(fakeRepo.inlinePhotoFetchCalls, 1);
    });
  });
}
