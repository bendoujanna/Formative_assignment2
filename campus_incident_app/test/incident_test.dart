import 'package:campus_incident_app/models/incident.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Incident.fromMap', () {
    test('reads every field of a stored report', () {
      final created = DateTime(2026, 11, 3, 10, 30);

      final incident = Incident.fromMap('abc', {
        'title': 'Water shortage',
        'description': 'There has been no water since this morning.',
        'category': 'water',
        'location': 'Student residence',
        'locationDetails': 'Room 204',
        'isUrgent': false,
        'status': 'inProgress',
        'reporterId': 'u1',
        'reporterName': 'Amina Bako',
        'createdAt': Timestamp.fromDate(created),
        'hasInlinePhoto': true,
        'staffNote': 'A plumber is on the way.',
        'updatedByName': 'Facilities Staff',
      });

      expect(incident.id, 'abc');
      expect(incident.title, 'Water shortage');
      expect(incident.category, IncidentCategory.water);
      expect(incident.status, IncidentStatus.inProgress);
      expect(incident.fullLocation, 'Student residence, Room 204');
      expect(incident.reporterId, 'u1');
      expect(incident.createdAt, created);
      expect(incident.hasInlinePhoto, isTrue);
      expect(incident.hasPhoto, isFalse);
      expect(incident.hasAnyPhoto, isTrue);
      expect(incident.staffNote, 'A plumber is on the way.');
    });

    test('unknown or missing values fall back to safe defaults', () {
      final incident = Incident.fromMap('x', {
        'category': 'banana',
        'status': 'weird',
      });

      expect(incident.category, IncidentCategory.facilities);
      expect(incident.status, IncidentStatus.submitted);
      expect(incident.title, '');
      expect(incident.isUrgent, isFalse);
      expect(incident.hasAnyPhoto, isFalse);
    });

    test('a document without a server time yet uses the current time', () {
      final before = DateTime.now();
      final incident = Incident.fromMap('x', {});
      expect(incident.createdAt.isBefore(before), isFalse);
    });

    test('a photo address counts as a photo', () {
      final incident = Incident.fromMap('x', {
        'photoUrl': 'https://example.com/a.jpg',
      });
      expect(incident.hasPhoto, isTrue);
      expect(incident.hasAnyPhoto, isTrue);
    });
  });

  group('Incident.draft', () {
    Incident draftFor(IncidentCategory category) => Incident.draft(
      title: 'Broken light',
      description: 'The light in the corridor does not work.',
      category: category,
      location: 'Classroom block',
      reporterId: 'u1',
      reporterName: 'Amina Bako',
    );

    test('safety reports are flagged as urgent automatically', () {
      expect(draftFor(IncidentCategory.safety).isUrgent, isTrue);
    });

    test('other categories are not urgent', () {
      for (final category in IncidentCategory.values) {
        if (category == IncidentCategory.safety) continue;
        expect(draftFor(category).isUrgent, isFalse, reason: category.name);
      }
    });

    test('a new report starts as submitted and has no id yet', () {
      final draft = draftFor(IncidentCategory.water);
      expect(draft.status, IncidentStatus.submitted);
      expect(draft.id, '');
    });
  });

  group('labels and location', () {
    test('categories have readable labels', () {
      expect(IncidentCategory.facilities.label, 'Facilities');
      expect(IncidentCategory.electricity.label, 'Electricity');
      expect(IncidentCategory.safety.label, 'Safety');
    });

    test('statuses have readable labels', () {
      expect(IncidentStatus.submitted.label, 'Submitted');
      expect(IncidentStatus.inProgress.label, 'In Progress');
      expect(IncidentStatus.resolved.label, 'Resolved');
    });

    test('the location has no comma when there are no details', () {
      final incident = Incident.fromMap('x', {'location': 'Library'});
      expect(incident.fullLocation, 'Library');
    });
  });
}
