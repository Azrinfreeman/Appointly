import 'package:hive_ce/hive.dart';

part 'appointment.g.dart';

@HiveType(typeId: 1)
enum RecurrenceType {
  @HiveField(0)
  none,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
}

@HiveType(typeId: 0)
class Appointment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final String clientName;

  @HiveField(3)
  final String phoneNumber;

  @HiveField(4)
  final String location;

  @HiveField(5)
  final int? hour;

  @HiveField(6)
  final int? minute;

  @HiveField(7)
  final RecurrenceType? recurrenceType;

  @HiveField(8)
  final List<DateTime>? excludedDates;

  @HiveField(9)
  final int? reminderMinutesBefore;

  Appointment({
    required this.id,
    required this.date,
    required this.clientName,
    required this.phoneNumber,
    required this.location,
    this.hour,
    this.minute,
    this.recurrenceType = RecurrenceType.none,
    this.excludedDates,
    this.reminderMinutesBefore = 1440,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'clientName': clientName,
      'phoneNumber': phoneNumber,
      'location': location,
      'hour': hour,
      'minute': minute,
      'recurrenceType': recurrenceType?.name ?? 'none',
      'excludedDates': excludedDates?.map((d) => d.toIso8601String()).toList(),
      'reminderMinutesBefore': reminderMinutesBefore ?? 1440,
    };
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final recTypeStr = json['recurrenceType'] as String?;
    final recType = RecurrenceType.values.firstWhere(
      (e) => e.name == recTypeStr,
      orElse: () => RecurrenceType.none,
    );
    final exclDatesRaw = json['excludedDates'] as List?;
    final exclDates = exclDatesRaw?.map((d) => DateTime.parse(d as String)).toList();

    return Appointment(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      clientName: json['clientName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      location: json['location'] as String,
      hour: json['hour'] as int?,
      minute: json['minute'] as int?,
      recurrenceType: recType,
      excludedDates: exclDates,
      reminderMinutesBefore: json['reminderMinutesBefore'] as int? ?? 1440,
    );
  }
}

