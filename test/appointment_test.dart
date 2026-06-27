import 'package:flutter_test/flutter_test.dart';
import 'package:calendar_appointment_app/appointment.dart';

void main() {
  group('Appointment Model Tests', () {
    test('JSON serialization round-trip', () {
      final appt = Appointment(
        id: 'test-uuid-1234',
        date: DateTime(2026, 6, 27),
        clientName: 'Alice Chin',
        phoneNumber: '60123456789',
        location: 'Kuala Lumpur Clinic',
        hour: 14,
        minute: 30,
        recurrenceType: RecurrenceType.weekly,
        reminderMinutesBefore: 120,
      );

      final jsonMap = appt.toJson();
      expect(jsonMap['id'], 'test-uuid-1234');
      expect(jsonMap['clientName'], 'Alice Chin');
      expect(jsonMap['reminderMinutesBefore'], 120);

      final decoded = Appointment.fromJson(jsonMap);
      expect(decoded.id, 'test-uuid-1234');
      expect(decoded.clientName, 'Alice Chin');
      expect(decoded.phoneNumber, '60123456789');
      expect(decoded.location, 'Kuala Lumpur Clinic');
      expect(decoded.hour, 14);
      expect(decoded.minute, 30);
      expect(decoded.recurrenceType, RecurrenceType.weekly);
      expect(decoded.reminderMinutesBefore, 120);
    });

    test('JSON deserialization defaults for older schema records', () {
      // Mock an older database record JSON that does NOT have the reminderMinutesBefore field
      final oldJson = {
        'id': 'test-uuid-old',
        'date': '2026-06-27T00:00:00.000',
        'clientName': 'Bob Marley',
        'phoneNumber': '60199999999',
        'location': 'Jamaica',
        'hour': 10,
        'minute': 0,
        'recurrenceType': 'none',
        'excludedDates': [],
      };

      final decoded = Appointment.fromJson(oldJson);
      expect(decoded.id, 'test-uuid-old');
      expect(decoded.clientName, 'Bob Marley');
      // Should default to 1 day before (1440 minutes)
      expect(decoded.reminderMinutesBefore, 1440);
    });
  });
}
