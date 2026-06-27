import 'package:flutter/material.dart';
import 'database_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _slides = [
    OnboardingData(
      icon: Icons.calendar_month_rounded,
      title: 'Welcome to Appointly',
      description: 'Your simple, elegant schedule companion built to keep client logs organized, structured, and at your fingertips.',
    ),
    OnboardingData(
      icon: Icons.security_rounded,
      title: '100% Secure & Offline',
      description: 'Your privacy is guaranteed. All records, names, locations, and phone numbers are stored offline on your device and never uploaded to any servers.',
    ),
    OnboardingData(
      icon: Icons.notifications_active_rounded,
      title: 'Smart Reminders & WhatsApp',
      description: 'Automatic reminders are scheduled 1 day before client visits. Seamlessly message clients via WhatsApp with a single tap.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    await DatabaseService.settingsBox.put('onboardingCompleted', true);
    widget.onCompleted();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: _currentPage < _slides.length - 1
                  ? TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text('Skip'),
                    )
                  : const SizedBox(height: 48), // Match spacing
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide.icon,
                            size: 80,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          slide.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String description;

  OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
