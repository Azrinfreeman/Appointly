import 'package:flutter/material.dart';
import '../appointment.dart';
import '../appointment_provider.dart';
import 'appointment_card.dart';
import 'empty_state.dart';

class HistoryView extends StatelessWidget {
  final AppointmentProvider provider;
  final Function(Appointment) onEdit;
  final Function(Appointment, DateTime) onDelete;

  const HistoryView({
    super.key,
    required this.provider,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pastOccurrences = provider.pastOccurrences;

    if (pastOccurrences.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.history_outlined,
        title: 'No History Yet',
        description: 'Past client sessions and completed visits will show up here.',
      );
    }

    return ListView.builder(
      itemCount: pastOccurrences.length,
      itemBuilder: (context, index) {
        final occurrence = pastOccurrences[index];
        return AppointmentCard(
          appointment: occurrence.appointment,
          occurrenceDate: occurrence.date,
          showDate: true,
          use24HourFormat: provider.use24HourFormat,
          onEdit: () => onEdit(occurrence.appointment),
          onDelete: () => onDelete(occurrence.appointment, occurrence.date),
        );
      },
    );
  }
}
