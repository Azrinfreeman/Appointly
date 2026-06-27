import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../appointment.dart';

class TimeSegmentColors {
  final Color baseColor;
  final Color containerColor;
  final Color textColor;
  final String segmentName;

  TimeSegmentColors({
    required this.baseColor,
    required this.containerColor,
    required this.textColor,
    required this.segmentName,
  });
}

String formatTime(int? hour, int? minute, bool use24h) {
  if (hour == null || minute == null) return 'No Time';
  if (use24h) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  } else {
    final period = hour >= 12 ? 'PM' : 'AM';
    var h = hour % 12;
    if (h == 0) h = 12;
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}

String formatDate(DateTime date) {
  final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${weekdayNames[date.weekday - 1]}, ${date.day} ${monthNames[date.month - 1]} ${date.year}';
}

TimeSegmentColors getSegmentColors(int? hour, BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (hour == null) {
    return TimeSegmentColors(
      baseColor: Colors.grey,
      containerColor: isDark ? Colors.grey[850]! : Colors.grey[100]!,
      textColor: isDark ? Colors.grey[300]! : Colors.grey[800]!,
      segmentName: 'Untimed',
    );
  }

  if (hour < 12) {
    return TimeSegmentColors(
      baseColor: Colors.amber[700]!,
      containerColor: isDark 
          ? Colors.amber.withValues(alpha: 0.12) 
          : Colors.amber.shade50,
      textColor: isDark ? Colors.amber[200]! : Colors.amber[900]!,
      segmentName: 'Morning',
    );
  } else if (hour < 17) {
    return TimeSegmentColors(
      baseColor: Colors.teal[600]!,
      containerColor: isDark 
          ? Colors.teal.withValues(alpha: 0.12) 
          : Colors.teal.shade50,
      textColor: isDark ? Colors.teal[200]! : Colors.teal[900]!,
      segmentName: 'Afternoon',
    );
  } else {
    return TimeSegmentColors(
      baseColor: Colors.indigo[600]!,
      containerColor: isDark 
          ? Colors.indigo.withValues(alpha: 0.12) 
          : Colors.indigo.shade50,
      textColor: isDark ? Colors.indigo[200]! : Colors.indigo[900]!,
      segmentName: 'Evening',
    );
  }
}

String formatPhoneNumber(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');

  if (digits.startsWith('60') && digits.length >= 11 && digits.length <= 12) {
    const country = '+60';
    final rest = digits.substring(2);
    if (rest.length == 9) {
      return '$country ${rest.substring(0, 2)}-${rest.substring(2, 5)} ${rest.substring(5)}';
    } else if (rest.length == 10) {
      return '$country ${rest.substring(0, 2)}-${rest.substring(2, 6)} ${rest.substring(6)}';
    }
  } else if (digits.startsWith('0') && digits.length >= 9 && digits.length <= 11) {
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)} ${digits.substring(6)}';
    } else if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)} ${digits.substring(7)}';
    }
  }

  if (digits.length == 10) {
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
  } else if (digits.length == 11 && digits.startsWith('1')) {
    return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
  }

  if (raw.startsWith('+')) {
    return raw;
  }
  if (digits.startsWith('60')) {
    return '+$digits';
  }
  return raw;
}

Future<void> exportToIcs(BuildContext context, Appointment appt, DateTime occurrenceDate) async {
  try {
    final now = DateTime.now();

    String toUtcFormat(DateTime date, {int? hour, int? minute}) {
      final utc = DateTime.utc(
        date.year,
        date.month,
        date.day,
        hour ?? 9,
        minute ?? 0,
      );
      final yr = utc.year.toString().padLeft(4, '0');
      final mo = utc.month.toString().padLeft(2, '0');
      final dy = utc.day.toString().padLeft(2, '0');
      final hr = utc.hour.toString().padLeft(2, '0');
      final mi = utc.minute.toString().padLeft(2, '0');
      final se = utc.second.toString().padLeft(2, '0');
      return '$yr$mo${dy}T$hr$mi${se}Z';
    }

    final startStr = toUtcFormat(occurrenceDate, hour: appt.hour, minute: appt.minute);
    final endHour = appt.hour != null ? (appt.hour! + 1) : 10;
    final endMinute = appt.minute ?? 0;
    final endStr = toUtcFormat(occurrenceDate, hour: endHour, minute: endMinute);
    final stampStr = toUtcFormat(now);

    final icsContent = 
      'BEGIN:VCALENDAR\n'
      'VERSION:2.0\n'
      'PRODID:-//Appointly//NONSGML Client//EN\n'
      'BEGIN:VEVENT\n'
      'UID:${appt.id}_${occurrenceDate.millisecondsSinceEpoch}\n'
      'DTSTAMP:$stampStr\n'
      'DTSTART:$startStr\n'
      'DTEND:$endStr\n'
      'SUMMARY:Appointment: ${appt.clientName}\n'
      'DESCRIPTION:Client: ${appt.clientName}\\nPhone: ${appt.phoneNumber}\\nNotes: ${appt.location}\n'
      'LOCATION:${appt.location}\n'
      'END:VEVENT\n'
      'END:VCALENDAR\n';

    final tempDir = await getTemporaryDirectory();
    final fileName = 'appointment_${appt.clientName.replaceAll(RegExp(r'[^\w]'), '_')}.ics';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(icsContent);

    final xFile = XFile(file.path, mimeType: 'text/calendar');
    await Share.shareXFiles([xFile], subject: 'Appointment for ${appt.clientName}');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export: $e')),
      );
    }
  }
}
