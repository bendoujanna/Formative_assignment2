import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/widgets/empty_state.dart';
import 'package:campus_incident_app/widgets/status_chip.dart';
import 'package:campus_incident_app/widgets/status_timeline.dart';
import 'package:campus_incident_app/widgets/summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatusChip shows the status label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusChip(status: IncidentStatus.inProgress)),
      ),
    );

    expect(find.text('In Progress'), findsOneWidget);
  });

  testWidgets(
    'StatusTimeline shows check for past steps and sync for active step',
    (tester) async {
      final incident = Incident(
        id: 'abc',
        title: 'Water shortage',
        description: 'No water since morning.',
        category: IncidentCategory.water,
        location: 'Student residence',
        status: IncidentStatus.inProgress,
        reporterId: 'u1',
        reporterName: 'Amina Bako',
        createdAt: DateTime(2026, 11, 3, 10, 0),
        inProgressAt: DateTime(2026, 11, 3, 14, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StatusTimeline(incident: incident)),
        ),
      );

      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
    },
  );

  testWidgets('SummaryCard shows value and runs onTap when pressed', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SummaryCard(
            icon: Icons.schedule,
            color: Colors.blue,
            value: 5,
            label: 'In Progress',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('5'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);

    await tester.tap(find.byType(SummaryCard));
    expect(tapped, isTrue);
  });

  testWidgets('EmptyState shows the icon and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox_outlined,
            message: 'No reports have been submitted yet.',
          ),
        ),
      ),
    );

    expect(find.text('No reports have been submitted yet.'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });
}
