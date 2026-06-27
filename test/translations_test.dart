import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_appointment_app/utils/translations.dart';

void main() {
  group('Translations Tests', () {
    test('Look up English translation', () {
      expect(Translations.get('appTitle', 'en'), 'My Appointments');
      expect(Translations.get('calendarTab', 'en'), 'Calendar');
    });

    test('Look up Malay (ms) translation', () {
      expect(Translations.get('calendarTab', 'ms'), 'Kalendar');
      expect(Translations.get('clientsTab', 'ms'), 'Pelanggan');
    });

    test('Look up Chinese (zh) translation', () {
      expect(Translations.get('calendarTab', 'zh'), '日历');
      expect(Translations.get('clientsTab', 'zh'), '客户管理');
    });

    test('Fallback to English if language is missing/unsupported', () {
      // 'fr-ca' is unsupported, should fallback to English 'en'
      expect(Translations.get('calendarTab', 'fr-ca'), 'Calendar');
    });

    test('Fallback to English if key is missing in supported language', () {
      // Test with random key
      expect(Translations.get('non_existent_key_xyz', 'ms'), 'non_existent_key_xyz');
    });
  });
}
