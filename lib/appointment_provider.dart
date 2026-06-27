import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'appointment.dart';
import 'database_service.dart';
import 'utils/translations.dart';

class PastOccurrence {
  final Appointment appointment;
  final DateTime date;

  PastOccurrence({required this.appointment, required this.date});
}

class ClientProfile {
  final String name;
  final String phoneNumber;
  final String lastLocation;
  final List<Appointment> appointments;

  ClientProfile({
    required this.name,
    required this.phoneNumber,
    required this.lastLocation,
    required this.appointments,
  });
}

class AppointmentProvider extends ChangeNotifier {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _use24HourFormat = false;
  String _themeMode = 'system';
  String _languageCode = 'en';
  List<PastOccurrence> _pastOccurrences = [];

  AppointmentProvider() {
    _use24HourFormat = DatabaseService.get24HourFormat();
    _themeMode = DatabaseService.getThemeMode();
    _languageCode = DatabaseService.settingsBox.get('languageCode', defaultValue: 'en') as String;
    _updatePastOccurrences();

    // Listen to changes in the database and settings boxes
    DatabaseService.box.listenable().addListener(_onDatabaseChanged);
    DatabaseService.settingsBox.listenable().addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    DatabaseService.box.listenable().removeListener(_onDatabaseChanged);
    DatabaseService.settingsBox.listenable().removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onDatabaseChanged() {
    _updatePastOccurrences();
    notifyListeners();
  }

  void _onSettingsChanged() {
    _use24HourFormat = DatabaseService.get24HourFormat();
    _themeMode = DatabaseService.getThemeMode();
    _languageCode = DatabaseService.settingsBox.get('languageCode', defaultValue: 'en') as String;
    notifyListeners();
  }

  void _updatePastOccurrences() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<PastOccurrence> pastList = [];

    for (final appt in DatabaseService.box.values) {
      final apptDate = DateTime(appt.date.year, appt.date.month, appt.date.day);
      if (!apptDate.isBefore(today)) continue;

      final recType = appt.recurrenceType ?? RecurrenceType.none;
      if (recType == RecurrenceType.none) {
        pastList.add(PastOccurrence(appointment: appt, date: apptDate));
      } else if (recType == RecurrenceType.weekly) {
        DateTime temp = apptDate;
        final yesterday = today.subtract(const Duration(days: 1));
        while (!temp.isAfter(yesterday)) {
          final isExcluded = appt.excludedDates?.any((d) => 
              d.year == temp.year && d.month == temp.month && d.day == temp.day) ?? false;
          if (!isExcluded) {
            pastList.add(PastOccurrence(appointment: appt, date: temp));
          }
          temp = temp.add(const Duration(days: 7));
        }
      } else if (recType == RecurrenceType.monthly) {
        DateTime temp = apptDate;
        final yesterday = today.subtract(const Duration(days: 1));
        while (!temp.isAfter(yesterday)) {
          final isExcluded = appt.excludedDates?.any((d) => 
              d.year == temp.year && d.month == temp.month && d.day == temp.day) ?? false;
          if (!isExcluded) {
            pastList.add(PastOccurrence(appointment: appt, date: temp));
          }
          int nextMonth = temp.month + 1;
          int nextYear = temp.year;
          if (nextMonth > 12) {
            nextMonth = 1;
            nextYear += 1;
          }
          final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
          final targetDay = apptDate.day;
          final actualDay = targetDay <= lastDayOfNextMonth ? targetDay : lastDayOfNextMonth;
          temp = DateTime(nextYear, nextMonth, actualDay);
        }
      }
    }

    pastList.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) return dateCompare;
      
      final apptA = a.appointment;
      final apptB = b.appointment;
      if (apptA.hour == null && apptB.hour == null) return 0;
      if (apptA.hour == null) return 1;
      if (apptB.hour == null) return -1;
      if (apptA.hour != apptB.hour) {
        return apptA.hour!.compareTo(apptB.hour!);
      }
      return (apptA.minute ?? 0).compareTo(apptB.minute ?? 0);
    });

    _pastOccurrences = pastList;
  }

  // Getters
  DateTime get selectedDay => _selectedDay;
  DateTime get focusedDay => _focusedDay;
  CalendarFormat get calendarFormat => _calendarFormat;
  bool get use24HourFormat => _use24HourFormat;
  String get themeMode => _themeMode;
  List<PastOccurrence> get pastOccurrences => _pastOccurrences;
  String get languageCode => _languageCode;

  String translate(String key) {
    return Translations.get(key, _languageCode);
  }

  List<ClientProfile> get clientProfiles {
    final Map<String, List<Appointment>> grouped = {};
    for (final appt in DatabaseService.box.values) {
      final cleanPhone = appt.phoneNumber.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.isEmpty) continue;
      grouped.putIfAbsent(cleanPhone, () => []).add(appt);
    }

    final List<ClientProfile> profiles = [];
    grouped.forEach((phone, appts) {
      appts.sort((a, b) => b.date.compareTo(a.date));
      final latest = appts.first;
      profiles.add(ClientProfile(
        name: latest.clientName,
        phoneNumber: latest.phoneNumber,
        lastLocation: latest.location,
        appointments: appts,
      ));
    });

    profiles.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return profiles;
  }

  List<Appointment> get appointmentsForSelectedDay {
    return DatabaseService.getAppointmentsForDate(_selectedDay);
  }

  // Setters / State Modification Methods
  Future<void> setLanguageCode(String code) async {
    _languageCode = code;
    await DatabaseService.settingsBox.put('languageCode', code);
    notifyListeners();
  }

  void setSelectedDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
  }

  void setCalendarFormat(CalendarFormat format) {
    _calendarFormat = format;
    notifyListeners();
  }

  Future<void> toggle24HourFormat(bool value) async {
    _use24HourFormat = value;
    await DatabaseService.set24HourFormat(value);
    notifyListeners();
  }

  Future<void> cycleThemeMode() async {
    String nextMode;
    if (_themeMode == 'system') {
      nextMode = 'light';
    } else if (_themeMode == 'light') {
      nextMode = 'dark';
    } else {
      nextMode = 'system';
    }
    _themeMode = nextMode;
    await DatabaseService.setThemeMode(nextMode);
    notifyListeners();
  }

  Future<void> addAppointment(Appointment appt) async {
    await DatabaseService.addAppointment(appt);
    _updatePastOccurrences();
    notifyListeners();
  }

  Future<void> deleteAppointment(String id) async {
    await DatabaseService.deleteAppointment(id);
    _updatePastOccurrences();
    notifyListeners();
  }

  Future<void> deleteOccurrence(Appointment appt, DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final currentExclusions = List<DateTime>.from(appt.excludedDates ?? []);
    currentExclusions.add(normalizedDate);

    final updatedAppt = Appointment(
      id: appt.id,
      date: appt.date,
      clientName: appt.clientName,
      phoneNumber: appt.phoneNumber,
      location: appt.location,
      hour: appt.hour,
      minute: appt.minute,
      recurrenceType: appt.recurrenceType,
      excludedDates: currentExclusions,
    );

    await DatabaseService.addAppointment(updatedAppt);
    _updatePastOccurrences();
    notifyListeners();
  }

  Future<int> importBackup(String jsonStr) async {
    final result = await DatabaseService.importAppointmentsJson(jsonStr);
    if (result > 0) {
      _updatePastOccurrences();
      notifyListeners();
    }
    return result;
  }
}
