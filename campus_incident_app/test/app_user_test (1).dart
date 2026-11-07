import 'package:campus_incident_app/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppUser userWith(Map<String, dynamic> map) => AppUser.fromMap('u1', map);

  group('role', () {
    test('a staff profile is recognised', () {
      final user = userWith({
        'name': 'Sam',
        'email': 's@alueducation.com',
        'role': 'staff',
      });
      expect(user.role, UserRole.staff);
      expect(user.isStaff, isTrue);
    });

    test('a student profile is not staff', () {
      final user = userWith({
        'name': 'Amina',
        'email': 'a@alustudent.com',
        'role': 'student',
      });
      expect(user.isStaff, isFalse);
    });

    test('an unknown or missing role becomes student (least privilege)', () {
      expect(userWith({'role': 'admin'}).role, UserRole.student);
      expect(userWith({}).role, UserRole.student);
    });
  });

  group('initials', () {
    test('two words give two letters', () {
      expect(userWith({'name': 'Amina Bako'}).initials, 'AB');
    });

    test('one word gives one letter', () {
      expect(userWith({'name': 'amina'}).initials, 'A');
    });

    test('extra spaces and more than two words are handled', () {
      expect(userWith({'name': '  Amina   Bako Hassan '}).initials, 'AB');
    });

    test('an empty name gives a question mark', () {
      expect(userWith({'name': ''}).initials, '?');
    });
  });
}
