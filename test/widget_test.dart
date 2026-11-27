import 'package:calendar_appointment_app/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('New visitors can advance through onboarding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(onCompleted: () {})),
    );

    expect(find.text('Welcome to Appointly'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('100% Secure & Offline'), findsOneWidget);
  });
}
