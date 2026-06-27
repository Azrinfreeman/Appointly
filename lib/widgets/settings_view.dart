import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../appointment_provider.dart';
import '../database_service.dart';
import '../privacy_policy_screen.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  IconData _getThemeIcon(String mode) {
    switch (mode) {
      case 'light':
        return Icons.light_mode;
      case 'dark':
        return Icons.dark_mode;
      case 'system':
      default:
        return Icons.settings_brightness;
    }
  }

  void _showLanguageDialog(BuildContext context, AppointmentProvider provider) {
    final languages = {
      'en': 'English',
      'ms': 'Bahasa Melayu',
      'zh': '中文 (Chinese)',
      'ta': 'தமிழ் (Tamil)',
      'es': 'Español (Spanish)',
      'fr': 'Français (French)',
      'ar': 'العربية (Arabic)',
      'ja': '日本語 (Japanese)',
      'hi': 'हिन्दी (Hindi)',
      'de': 'Deutsch (German)',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.translate('selectLanguage')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: languages.entries.map((entry) {
              final isSelected = provider.languageCode == entry.key;
              return ListTile(
                title: Text(
                  entry.value,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                onTap: () {
                  provider.setLanguageCode(entry.key);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showStatsDialog(BuildContext context, DateTime selected, AppointmentProvider provider) {
    final startOfWeek = selected.subtract(Duration(days: selected.weekday - 1));
    int weeklyCount = 0;
    final Map<int, int> weekdayCounts = {};

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final appts = DatabaseService.getAppointmentsForDate(day);
      weeklyCount += appts.length;
      weekdayCounts[day.weekday] = appts.length;
    }

    int busiestWeekday = 1;
    int maxCount = -1;
    final weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    weekdayCounts.forEach((weekday, count) {
      if (count > maxCount) {
        maxCount = count;
        busiestWeekday = weekday;
      }
    });

    final busiestDayName = maxCount > 0 ? weekdayNames[busiestWeekday - 1] : 'None';

    final lastDayOfMonth = DateTime(selected.year, selected.month + 1, 0);
    int monthlyCount = 0;
    for (int dayNum = 1; dayNum <= lastDayOfMonth.day; dayNum++) {
      final day = DateTime(selected.year, selected.month, dayNum);
      monthlyCount += DatabaseService.getAppointmentsForDate(day).length;
    }

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final currentMonthName = monthNames[selected.month - 1];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(provider.translate('workloadSummary')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.translate('weeklyOverview'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text('• ${provider.translate('totalApptsWeek')}: $weeklyCount'),
            Text('• ${provider.translate('busiestDay')}: $busiestDayName ($maxCount)'),
            const Divider(height: 24),
            Text(
              '${provider.translate('monthlyOverview')} ($currentMonthName)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text('• ${provider.translate('totalApptsMonth')}: $monthlyCount'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(provider.translate('close')),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final jsonStr = DatabaseService.exportAppointmentsJson();
      await Share.share(
        jsonStr,
        subject: 'Mom\'s Calendar Appointments Backup',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export backup: $e')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, AppointmentProvider provider) async {
    final TextEditingController controller = TextEditingController();
    final importResult = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.translate('importBackup')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the backup text (JSON) shared from the export feature below:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '[{"id": "...", ...}]',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: Text(provider.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              final count = await provider.importBackup(controller.text);
              if (context.mounted) {
                Navigator.pop(context, count);
              }
            },
            child: Text(provider.translate('add')),
          ),
        ],
      ),
    );

    if (importResult != null && importResult > 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.translate('importSuccessful').replaceAll('{}', '$importResult'))),
        );
      }
    } else if (importResult == -1) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.translate('importFailed'))),
        );
      }
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.grey.withValues(alpha: 0.05),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();

    String themeText = provider.translate('themeLight');
    if (provider.themeMode == 'dark') {
      themeText = provider.translate('themeDark');
    } else if (provider.themeMode == 'system') {
      themeText = provider.translate('themeSystem');
    }

    final currentLangMap = {
      'en': 'English',
      'ms': 'Bahasa Melayu',
      'zh': '中文 (Chinese)',
      'ta': 'தமிழ் (Tamil)',
      'es': 'Español (Spanish)',
      'fr': 'Français (French)',
      'ar': 'العربية (Arabic)',
      'ja': '日本語 (Japanese)',
      'hi': 'हिन्दी (Hindi)',
      'de': 'Deutsch (German)',
    };
    final currentLangName = currentLangMap[provider.languageCode] ?? 'English';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Preferences Section
          _buildSectionTitle(context, provider.translate('preferencesCategory')),
          _buildSettingCard([
            ListTile(
              leading: Icon(_getThemeIcon(provider.themeMode)),
              title: Text(provider.translate('theme')),
              subtitle: Text(themeText),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => provider.cycleThemeMode(),
            ),
            const Divider(height: 1, indent: 56),
            SwitchListTile(
              secondary: const Icon(Icons.access_time),
              title: Text(provider.translate('format24h')),
              value: provider.use24HourFormat,
              onChanged: (value) => provider.toggle24HourFormat(value),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(provider.translate('selectLanguage')),
              subtitle: Text(currentLangName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageDialog(context, provider),
            ),
          ]),

          // 2. Data section
          _buildSectionTitle(context, provider.translate('dataCategory')),
          _buildSettingCard([
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: Text(provider.translate('workloadStats')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showStatsDialog(context, DateTime.now(), provider),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: Text(provider.translate('exportBackup')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _exportBackup(context),
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: Text(provider.translate('importBackup')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _importBackup(context, provider),
            ),
          ]),

          // 3. About section
          _buildSectionTitle(context, provider.translate('aboutCategory')),
          _buildSettingCard([
            ListTile(
              leading: const Icon(Icons.security),
              title: Text(provider.translate('privacyPolicy')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                );
              },
            ),
            const Divider(height: 1, indent: 56),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(provider.translate('appVersion')),
              trailing: const Text(
                '1.0.0',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
