import 'package:flutter/material.dart';

class AppErrorScreen extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const AppErrorScreen({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Initialization Failed',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We couldn\'t load the calendar database files or services. This can happen if local storage is low or permissions are missing.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Details: $errorMessage',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
