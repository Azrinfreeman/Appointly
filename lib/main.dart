import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'calendar_screen.dart';
import 'appointment_provider.dart';
import 'error_screen.dart';
import 'onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _initialized = false;
  bool _error = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    setState(() {
      _initialized = false;
      _error = false;
      _errorMessage = '';
    });
    try {
      await DatabaseService.init();
      await NotificationService().init();
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = true;
        _errorMessage = e.toString();
      });
    }
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return MaterialApp(
        title: 'Appointly',
        theme: ThemeData(useMaterial3: true),
        home: AppErrorScreen(
          errorMessage: _errorMessage,
          onRetry: _initApp,
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    if (!_initialized) {
      return MaterialApp(
        title: 'Appointly',
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    final onboardingCompleted = DatabaseService.settingsBox.get('onboardingCompleted', defaultValue: false) as bool;

    if (!onboardingCompleted) {
      return MaterialApp(
        title: 'Appointly',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: OnboardingScreen(
          onCompleted: () {
            setState(() {
              // Trigger rebuild to transit to main app calendar
            });
          },
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return ChangeNotifierProvider<AppointmentProvider>(
      create: (_) => AppointmentProvider(),
      child: Consumer<AppointmentProvider>(
        builder: (context, provider, _) {
          final themeMode = _parseThemeMode(provider.themeMode);

          return MaterialApp(
            title: 'Appointly',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
            themeMode: themeMode,
            home: const CalendarScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
