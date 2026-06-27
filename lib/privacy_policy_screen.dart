import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Appointly Privacy Policy',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Last Updated: June 2026',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const Divider(height: 32),
              _buildSection(
                context,
                '1. Offline-First Architecture',
                'Your privacy is our priority. "Appointly" is designed as an offline-first application. All data, client logs, schedule entries, and history notes are saved directly in local storage on your device (using secure localized database files). None of this data is sent to external servers or cloud repositories.',
              ),
              _buildSection(
                context,
                '2. Contacts Integration',
                'The application provides a feature allowing you to select client information from your device contacts directory. The contact detail picker is completely client-sided; contact records are accessed only after your explicit selection, and this info is strictly used to prefill the client creation form. We never upload or share your contacts list.',
              ),
              _buildSection(
                context,
                '3. Reminders & Notifications',
                'Reminders are scheduled natively on your device via local alarm services (such as exact alarms). The scheduling does not rely on third-party cloud push notification platforms. Notifications are generated locally by the app itself.',
              ),
              _buildSection(
                context,
                '4. Third-Party Integrations',
                'To coordinate appointment chats, the app launches direct links to the official WhatsApp messaging app (https://wa.me/). When using this, only the digits of the selected contact\'s phone number are passed locally to the URL launcher service.',
              ),
              _buildSection(
                context,
                '5. Updates & Changes',
                'We may update this policy periodically to reflect operational, legal, or regulatory adjustments. Please review this screen inside the app to check for updates.',
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'If you have any questions, contact us locally via your system settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
