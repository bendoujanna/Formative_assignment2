import 'package:campus_incident_app/core/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email', () {
    test('accepts an ALU student address', () {
      expect(Validators.email('amina@alustudent.com'), isNull);
    });

    test('accepts an ALU staff address', () {
      expect(Validators.email('staff@alueducation.com'), isNull);
    });

    test('ignores capital letters and spaces around the address', () {
      expect(Validators.email('  Amina@AluStudent.com '), isNull);
    });

    test('rejects an address from another domain', () {
      expect(Validators.email('amina@gmail.com'), 'Use your ALU email address');
    });

    test('rejects empty and badly formed addresses', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('plainaddress'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('a b@alustudent.com'), isNotNull);
    });
  });

  group('passwords', () {
    test('a new password needs at least 8 characters', () {
      expect(Validators.newPassword('1234567'), isNotNull);
      expect(Validators.newPassword('12345678'), isNull);
    });

    test('empty passwords are rejected', () {
      expect(Validators.newPassword(''), isNotNull);
      expect(Validators.existingPassword(''), isNotNull);
      expect(Validators.existingPassword(null), isNotNull);
    });

    test('an existing password only has to be typed', () {
      expect(Validators.existingPassword('x'), isNull);
    });

    test('the confirmation must match', () {
      expect(
        Validators.confirmPassword('abc', 'abd'),
        'Passwords do not match',
      );
      expect(Validators.confirmPassword('abc', 'abc'), isNull);
      expect(Validators.confirmPassword('', 'abc'), isNotNull);
    });
  });

  group('name', () {
    test('needs at least 2 characters after trimming', () {
      expect(Validators.name(null), isNotNull);
      expect(Validators.name('  '), isNotNull);
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name('Al'), isNull);
    });
  });

  group('incident title', () {
    test('empty and spaces-only are rejected', () {
      expect(Validators.incidentTitle(null), isNotNull);
      expect(Validators.incidentTitle(''), isNotNull);
      expect(Validators.incidentTitle('     '), isNotNull);
    });

    test('2 characters is too short, 3 is accepted', () {
      expect(Validators.incidentTitle('ab'), isNotNull);
      expect(Validators.incidentTitle('abc'), isNull);
    });

    test('spaces around the text are ignored', () {
      expect(Validators.incidentTitle('  ab  '), isNotNull);
    });

    test('80 characters is accepted, 81 is rejected', () {
      expect(Validators.incidentTitle('a' * 80), isNull);
      expect(Validators.incidentTitle('a' * 81), isNotNull);
    });
  });

  group('incident description', () {
    test('empty is rejected', () {
      expect(Validators.incidentDescription(null), isNotNull);
      expect(Validators.incidentDescription('   '), isNotNull);
    });

    test('9 characters is too short, 10 is accepted', () {
      expect(Validators.incidentDescription('a' * 9), isNotNull);
      expect(Validators.incidentDescription('a' * 10), isNull);
    });

    test('500 characters is accepted, 501 is rejected', () {
      expect(Validators.incidentDescription('a' * 500), isNull);
      expect(Validators.incidentDescription('a' * 501), isNotNull);
    });
  });

  group('required choice', () {
    test('null returns the message, any value is accepted', () {
      expect(Validators.requiredChoice(null, 'Pick one'), 'Pick one');
      expect(Validators.requiredChoice('Library', 'Pick one'), isNull);
    });
  });
}
