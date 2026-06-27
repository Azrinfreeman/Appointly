import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../appointment.dart';
import '../appointment_provider.dart';
import '../utils/helpers.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final DateTime occurrenceDate;
  final bool showDate;
  final bool use24HourFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.occurrenceDate,
    required this.showDate,
    required this.use24HourFormat,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse('https://wa.me/$cleanPhone');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not launch WhatsApp. Is it installed?')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppointmentProvider>(context);
    final isRecurring = appointment.recurrenceType != null &&
        appointment.recurrenceType != RecurrenceType.none;
    final segColors = getSegmentColors(appointment.hour, context);

    return Dismissible(
      key: Key('${appointment.id}_${occurrenceDate.millisecondsSinceEpoch}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.blue[600],
        child: const Icon(Icons.edit, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red[600],
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit();
          return false;
        } else {
          onDelete();
          return false;
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                color: segColors.baseColor,
              ),
              Expanded(
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              appointment.clientName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          if (isRecurring)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text(
                                  appointment.recurrenceType == RecurrenceType.weekly 
                                      ? provider.translate('weekly').split(' ').first 
                                      : provider.translate('monthly').split(' ').first,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          Text(
                            formatTime(appointment.hour, appointment.minute, use24HourFormat),
                            style: TextStyle(
                              color: segColors.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          showDate
                              ? '${formatDate(occurrenceDate)}\n${appointment.location}\n${formatPhoneNumber(appointment.phoneNumber)}'
                              : '${appointment.location}\n${formatPhoneNumber(appointment.phoneNumber)}',
                        ),
                      ),
                      onLongPress: onDelete,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit, size: 16),
                              label: Text(provider.translate('edit')),
                              onPressed: onEdit,
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                              label: Text(provider.translate('exportToCalendar'), style: const TextStyle(color: Colors.blue)),
                              onPressed: () => exportToIcs(context, appointment, occurrenceDate),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                              label: Text(provider.translate('delete'), style: const TextStyle(color: Colors.red)),
                              onPressed: onDelete,
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.message, size: 16),
                              label: Text(provider.translate('whatsApp')),
                              onPressed: () => _openWhatsApp(context, appointment.phoneNumber),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
