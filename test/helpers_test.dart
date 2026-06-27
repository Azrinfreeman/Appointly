import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_appointment_app/utils/helpers.dart';

void main() {
  group('Time Formatting Tests', () {
    test('Format Time 12-Hour format', () {
      expect(formatTime(9, 30, false), '9:30 AM');
      expect(formatTime(13, 0, false), '1:00 PM');
      expect(formatTime(0, 5, false), '12:05 AM');
      expect(formatTime(12, 15, false), '12:15 PM');
      expect(formatTime(null, null, false), 'No Time');
    });

    test('Format Time 24-Hour format', () {
      expect(formatTime(9, 30, true), '09:30');
      expect(formatTime(13, 0, true), '13:00');
      expect(formatTime(0, 5, true), '00:05');
      expect(formatTime(null, null, true), 'No Time');
    });
  });

  group('Date Formatting Tests', () {
    test('Format Date correct weekday and format', () {
      // 2026-06-27 is Saturday
      final date = DateTime(2026, 6, 27);
      expect(formatDate(date), 'Sat, 27 Jun 2026');
    });
  });

  group('Phone Number Formatting Tests', () {
    test('Format Malaysian number starts with 60', () {
      expect(formatPhoneNumber('60123456789'), '+60 12-345 6789');
      expect(formatPhoneNumber('601112345678'), '+60 11-1234 5678');
    });

    test('Format local Malaysian number starts with 0', () {
      expect(formatPhoneNumber('0123456789'), '012-345 6789');
      expect(formatPhoneNumber('01112345678'), '011-1234 5678');
    });

    test('Format standard 10 digit US number', () {
      expect(formatPhoneNumber('5551234567'), '(555) 123-4567');
    });

    test('Leave already formatted or general string unchanged', () {
      expect(formatPhoneNumber('+60 12-345 6789'), '+60 12-345 6789');
      expect(formatPhoneNumber('123'), '123');
    });
  });
}
