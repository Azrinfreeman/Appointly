import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../appointment.dart';
import '../appointment_provider.dart';
import '../utils/helpers.dart';

class ClientDetailsScreen extends StatelessWidget {
  final ClientProfile profile;

  const ClientDetailsScreen({super.key, required this.profile});

  Future<void> _launchUrl(BuildContext context, String urlString, String errorMsg) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppointmentProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cleanPhone = profile.phoneNumber.replaceAll(RegExp(r'\D'), '');

    // Partition appointments into past and upcoming
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final List<Appointment> upcoming = [];
    final List<Appointment> past = [];

    for (final appt in profile.appointments) {
      final apptDate = DateTime(appt.date.year, appt.date.month, appt.date.day);
      if (apptDate.isBefore(today)) {
        past.add(appt);
      } else {
        upcoming.add(appt);
      }
    }

    // Sort upcoming chronologically, past reverse chronologically
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    past.sort((a, b) => b.date.compareTo(a.date));

    final initials = profile.name.trim().isNotEmpty
        ? profile.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.translate('clientDetails')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Profile Card
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatPhoneNumber(profile.phoneNumber),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Contact Actions Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.phone,
                    label: provider.translate('call'),
                    color: Colors.blue,
                    onTap: () => _launchUrl(
                      context,
                      'tel:${profile.phoneNumber}',
                      'Could not initiate call. Device not supported?',
                    ),
                  ),
                  _ActionButton(
                    icon: Icons.message,
                    label: provider.translate('sms'),
                    color: Colors.orange,
                    onTap: () => _launchUrl(
                      context,
                      'sms:${profile.phoneNumber}',
                      'Could not initiate SMS. Device not supported?',
                    ),
                  ),
                  _ActionButton(
                    icon: Icons.chat,
                    label: provider.translate('whatsApp'),
                    color: Colors.green,
                    onTap: () => _launchUrl(
                      context,
                      'https://wa.me/$cleanPhone',
                      'Could not launch WhatsApp. Is it installed?',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Total visits summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        provider.translate('totalVisits'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${profile.appointments.length}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Upcoming Visits list
              Text(
                provider.translate('upcomingVisits'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (upcoming.isEmpty)
                Text(
                  provider.translate('noUpcomingVisits'),
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcoming.length,
                  itemBuilder: (context, index) {
                    final appt = upcoming[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.event_note, color: Colors.blue),
                        title: Text(formatDate(appt.date)),
                        subtitle: Text(appt.location),
                        trailing: Text(formatTime(appt.hour, appt.minute, provider.use24HourFormat)),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Past Visits & Notes History
              Text(
                provider.translate('visitNotes'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (past.isEmpty)
                Text(
                  provider.translate('noPastVisits'),
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: past.length,
                  itemBuilder: (context, index) {
                    final appt = past[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatDate(appt.date),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  formatTime(appt.hour, appt.minute, provider.use24HourFormat),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Text(
                              appt.location,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
