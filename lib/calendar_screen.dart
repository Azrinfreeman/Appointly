import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';

import 'appointment.dart';
import 'appointment_form.dart';
import 'appointment_provider.dart';
import 'database_service.dart';

import 'widgets/empty_state.dart';
import 'widgets/appointment_card.dart';
import 'widgets/appointment_search_delegate.dart';
import 'widgets/history_view.dart';
import 'widgets/clients_screen.dart';
import 'widgets/settings_view.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _currentIndex = 0;

  Future<bool> _deleteWithUndo(
      BuildContext context, AppointmentProvider provider, Appointment appt, DateTime date) async {
    final isRecurring = appt.recurrenceType != null &&
        appt.recurrenceType != RecurrenceType.none;

    if (!isRecurring) {
      final originalAppt = appt;
      await provider.deleteAppointment(appt.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${provider.translate('deletedApptFor')} "${appt.clientName}"'),
            action: SnackBarAction(
              label: provider.translate('undo'),
              onPressed: () async {
                await provider.addAppointment(originalAppt);
              },
            ),
          ),
        );
      }
      return true;
    } else {
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(provider.translate('deleteRecurring')),
          content: Text(
            provider.translate('deleteRecurringPrompt').replaceAll('{}', appt.clientName),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: Text(provider.translate('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'one'),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: Text(provider.translate('thisOccurrenceOnly')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'all'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(provider.translate('allOccurrences')),
            ),
          ],
        ),
      );

      if (action == 'all') {
        final originalAppt = appt;
        await provider.deleteAppointment(appt.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${provider.translate('deletedAllOccurrencesFor')} "${appt.clientName}"'),
              action: SnackBarAction(
                label: provider.translate('undo'),
                onPressed: () async {
                  await provider.addAppointment(originalAppt);
                },
              ),
            ),
          );
        }
        return true;
      } else if (action == 'one') {
        final originalExclusions = List<DateTime>.from(appt.excludedDates ?? []);
        await provider.deleteOccurrence(appt, date);

        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${provider.translate('deletedThisOccurrenceFor')} "${appt.clientName}"'),
              action: SnackBarAction(
                label: provider.translate('undo'),
                onPressed: () async {
                  final revertedAppt = Appointment(
                    id: appt.id,
                    date: appt.date,
                    clientName: appt.clientName,
                    phoneNumber: appt.phoneNumber,
                    location: appt.location,
                    hour: appt.hour,
                    minute: appt.minute,
                    recurrenceType: appt.recurrenceType,
                    excludedDates: originalExclusions,
                    reminderMinutesBefore: appt.reminderMinutesBefore,
                  );
                  await provider.addAppointment(revertedAppt);
                },
              ),
            ),
          );
        }
        return true;
      }
      return false;
    }
  }

  void _showAddAppointmentDialog(BuildContext context, AppointmentProvider provider, {Appointment? appointment}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return AppointmentForm(
          appointment: appointment,
          initialDate: provider.selectedDay,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final selectedAppointments = provider.appointmentsForSelectedDay;

    String screenTitle = provider.translate('appTitle');
    if (_currentIndex == 1) {
      screenTitle = provider.translate('clientsHeader');
    } else if (_currentIndex == 2) {
      screenTitle = provider.translate('historyTab');
    } else if (_currentIndex == 3) {
      screenTitle = provider.translate('settingsHeader');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          screenTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: provider.translate('searchClient'),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: AppointmentSearchDelegate(
                    onAppointmentSelected: (date) {
                      provider.setFocusedDay(date);
                      provider.setSelectedDay(date);
                    },
                    use24HourFormat: provider.use24HourFormat,
                  ),
                );
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Calendar
          Column(
            children: [
              TableCalendar<Appointment>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: provider.focusedDay,
                calendarFormat: provider.calendarFormat,
                selectedDayPredicate: (day) => isSameDay(provider.selectedDay, day),
                eventLoader: DatabaseService.getAppointmentsForDate,
                onDaySelected: (selectedDay, focusedDay) {
                  provider.setSelectedDay(selectedDay);
                  provider.setFocusedDay(focusedDay);
                },
                onFormatChanged: (format) {
                  provider.setCalendarFormat(format);
                },
                onPageChanged: (focusedDay) {
                  provider.setFocusedDay(focusedDay);
                },
                headerStyle: HeaderStyle(
                  formatButtonDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle),
                        width: 16.0,
                        height: 16.0,
                        child: Center(
                          child: Text(
                            '${events.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10.0),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Expanded(
                child: selectedAppointments.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.calendar_today_outlined,
                        title: provider.translate('noClientsScheduled'),
                        description: provider.translate('takeBreak'),
                      )
                    : ListView.builder(
                        itemCount: selectedAppointments.length,
                        itemBuilder: (context, index) {
                          final appt = selectedAppointments[index];
                          return AppointmentCard(
                            appointment: appt,
                            occurrenceDate: provider.selectedDay,
                            showDate: false,
                            use24HourFormat: provider.use24HourFormat,
                            onEdit: () => _showAddAppointmentDialog(context, provider, appointment: appt),
                            onDelete: () => _deleteWithUndo(context, provider, appt, provider.selectedDay),
                          );
                        },
                      ),
              ),
            ],
          ),
          // Tab 1: Clients CRM
          ClientsScreen(provider: provider),
          // Tab 2: History
          HistoryView(
            provider: provider,
            onEdit: (appt) => _showAddAppointmentDialog(context, provider, appointment: appt),
            onDelete: (appt, date) => _deleteWithUndo(context, provider, appt, date),
          ),
          // Tab 3: Settings
          const SettingsView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_month),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: provider.translate('calendarTab'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people_rounded),
            label: provider.translate('clientsTab'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            selectedIcon: const Icon(Icons.history_rounded),
            label: provider.translate('historyTab'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: provider.translate('settingsTab'),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddAppointmentDialog(context, provider),
              icon: const Icon(Icons.add),
              label: Text(provider.translate('add')),
            )
          : null,
    );
  }
}
