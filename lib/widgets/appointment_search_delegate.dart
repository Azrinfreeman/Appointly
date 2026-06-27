import 'package:flutter/material.dart';
import '../appointment.dart';
import '../database_service.dart';
import '../utils/helpers.dart';

class AppointmentSearchDelegate extends SearchDelegate<Appointment?> {
  final Function(DateTime) onAppointmentSelected;
  final bool use24HourFormat;

  AppointmentSearchDelegate({
    required this.onAppointmentSelected,
    required this.use24HourFormat,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = DatabaseService.searchAppointments(query);

    if (results.isEmpty) {
      return const Center(
        child: Text('No matching appointments found.'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final appt = results[index];
        final formattedDate =
            '${appt.date.day}/${appt.date.month}/${appt.date.year}';
        final recStr = appt.recurrenceType == RecurrenceType.weekly
            ? ' (Weekly)'
            : appt.recurrenceType == RecurrenceType.monthly
                ? ' (Monthly)'
                : '';

        return ListTile(
          title: Text(appt.clientName + recStr),
          subtitle: Text('${appt.location} • Starts: $formattedDate\n${formatPhoneNumber(appt.phoneNumber)}'),
          isThreeLine: true,
          trailing: Text(
            formatTime(appt.hour, appt.minute, use24HourFormat),
            style: TextStyle(
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            onAppointmentSelected(appt.date);
            close(context, appt);
          },
        );
      },
    );
  }
}
