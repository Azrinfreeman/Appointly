import 'dart:convert';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'appointment.dart';
import 'notification_service.dart';

class DatabaseService {
  static const String _boxName = 'appointmentsBox';
  static const String _settingsBoxName = 'settingsBox';
  static late Box _settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(RecurrenceTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AppointmentAdapter());
    }
    await Hive.openBox<Appointment>(_boxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  static Box<Appointment> get box => Hive.box<Appointment>(_boxName);
  static Box get settingsBox => _settingsBox;

  static String getThemeMode() {
    return _settingsBox.get('themeMode', defaultValue: 'system') as String;
  }

  static Future<void> setThemeMode(String mode) async {
    await _settingsBox.put('themeMode', mode);
  }

  static bool get24HourFormat() {
    return _settingsBox.get('use24HourFormat', defaultValue: false) as bool;
  }

  static Future<void> set24HourFormat(bool value) async {
    await _settingsBox.put('use24HourFormat', value);
  }

  static Future<void> addAppointment(Appointment appointment) async {
    await box.put(appointment.id, appointment);
    await NotificationService().scheduleReminder(appointment);
  }

  static List<Appointment> getAppointmentsForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    final selected = box.values.where((appt) {
      final apptDate = DateTime(appt.date.year, appt.date.month, appt.date.day);

      // If the appointment starts after the queried date, it's not active yet
      if (apptDate.isAfter(normalizedDate)) return false;

      // Check if this specific occurrence was excluded
      final isExcluded = appt.excludedDates?.any((excludedDate) =>
          excludedDate.year == date.year &&
          excludedDate.month == date.month &&
          excludedDate.day == date.day) ?? false;

      if (isExcluded) return false;

      final recType = appt.recurrenceType ?? RecurrenceType.none;
      if (recType == RecurrenceType.none) {
        return apptDate.year == normalizedDate.year &&
            apptDate.month == normalizedDate.month &&
            apptDate.day == normalizedDate.day;
      } else if (recType == RecurrenceType.weekly) {
        return apptDate.weekday == normalizedDate.weekday;
      } else if (recType == RecurrenceType.monthly) {
        return apptDate.day == normalizedDate.day;
      }
      return false;
    }).toList();

    // Sort chronologically: timed appointments first (sorted by time), untimed at the end
    selected.sort((a, b) {
      if (a.hour == null && b.hour == null) return 0;
      if (a.hour == null) return 1;
      if (b.hour == null) return -1;

      if (a.hour != b.hour) {
        return a.hour!.compareTo(b.hour!);
      }
      return (a.minute ?? 0).compareTo(b.minute ?? 0);
    });

    return selected;
  }

  static List<Appointment> searchAppointments(String query) {
    if (query.isEmpty) return [];
    final lowercaseQuery = query.toLowerCase();

    final results = box.values.where((appt) {
      return appt.clientName.toLowerCase().contains(lowercaseQuery);
    }).toList();

    // Sort by date starting (most recent first)
    results.sort((a, b) => b.date.compareTo(a.date));
    return results;
  }

  static Future<void> deleteAppointment(String id) async {
    await NotificationService().cancelReminder(id);
    await box.delete(id);
  }

  static String exportAppointmentsJson() {
    final list = box.values.map((appt) => appt.toJson()).toList();
    return jsonEncode(list);
  }

  static Future<int> importAppointmentsJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) return 0;
      int importedCount = 0;
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final appt = Appointment.fromJson(item);
          await addAppointment(appt);
          importedCount++;
        }
      }
      return importedCount;
    } catch (e) {
      return -1;
    }
  }
}

