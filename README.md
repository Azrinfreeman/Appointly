# Appointly — Calendar & Client Appointments

**A Flutter mobile application for managing appointments, recurring schedules, and client details with local device storage.**

Appointly combines a calendar, appointment history, and client views in one application. Users can create a booking, choose a reminder, reuse contact details, and export appointment records as JSON. The repository retains its existing name, `CalendarAppointmentApp`.

## Features in the source

- **Calendar and booking form:** client name, phone number, location/notes, date, optional time, and editing controls.
- **Recurring schedules:** one-time, weekly, and monthly appointments, with controls to delete one occurrence or the entire series and undo a deletion.
- **Local persistence:** Hive CE stores appointments and settings; Provider connects database changes to the UI.
- **Client views and search:** appointments can be searched by client name, and client profiles are grouped using normalized phone digits.
- **Device integrations:** contact selection can prefill the form; call, SMS, and WhatsApp buttons open external applications.
- **Local reminders:** configurable offsets include one or two hours, one or two days, or no reminder, using timezone-aware scheduling code.
- **Backup and restore:** share appointment JSON as text and paste it back through Settings.
- **Personalization:** system/light/dark themes, 12/24-hour time, and translation dictionaries for ten languages, including English and Bahasa Melayu.

These are implemented source features, not a claim that every flow has passed device testing. Android and iOS project directories are included; both platform builds remain unverified in this documentation pass.

## A typical workflow

1. Complete onboarding and select a date in the calendar.
2. Add an appointment with client details, an optional time, recurrence, and reminder offset.
3. Review bookings in Calendar, History, or Clients; use search to find a client.
4. Open a client action when needed, or export appointment data from Settings.

Use fictional contact details when recording a portfolio demo. Screenshots and a device walkthrough have not yet been added.

## Implementation map

| Responsibility | Source |
| --- | --- |
| Startup, initialization errors, onboarding, and themes | [main.dart](lib/main.dart) |
| Calendar navigation and deletion/undo interactions | [calendar_screen.dart](lib/calendar_screen.dart) |
| Appointment input and contact selection | [appointment_form.dart](lib/appointment_form.dart) |
| Record schema and JSON serialization | [appointment.dart](lib/appointment.dart) |
| Hive persistence, date queries, search, and import/export | [database_service.dart](lib/database_service.dart) |
| Reactive state, client grouping, and history occurrences | [appointment_provider.dart](lib/appointment_provider.dart) |
| Permission requests and reminder scheduling | [notification_service.dart](lib/notification_service.dart) |
| Backup, language, and display settings | [settings_view.dart](lib/widgets/settings_view.dart) |
| Translation dictionaries and formatting | [translations.dart](lib/utils/translations.dart) and [helpers.dart](lib/utils/helpers.dart) |

## Development setup

The package is named `calendar_appointment_app`, version **1.0.0+1**, with a Dart SDK constraint of **`>=3.3.0 <4.0.0`** in [pubspec.yaml](pubspec.yaml). A tested Flutter SDK version is not pinned. That Dart constraint alone does not establish compatibility with every framework API or dependency used by the app.

Start with a Flutter SDK and platform toolchain compatible with the checked-in project, then resolve dependencies:

```sh
flutter --version
flutter doctor
flutter pub get
```

No `pubspec.lock` is currently checked in, so dependency resolution may vary. The ignore rules now allow the root lockfile to be committed after a successful, reviewed resolution. Preserve [appointment.g.dart](lib/appointment.g.dart) and [hive_registrar.g.dart](lib/hive_registrar.g.dart); generated adapters are already present.

The checked-in Android configuration uses compile/target SDK **36**, Android Gradle Plugin **9.0.1**, Gradle **9.1.0**, Kotlin plugin **2.3.20**, and Java source/target compatibility **17**. Android wrapper scripts and the wrapper JAR are not tracked. Verify toolchain compatibility and restore the missing wrapper tooling in a separate setup change before expecting a clean Android build. See [app/build.gradle.kts](android/app/build.gradle.kts), [settings.gradle.kts](android/settings.gradle.kts), and [gradle-wrapper.properties](android/gradle/wrapper/gradle-wrapper.properties).

After dependencies and platform setup are working, select a mobile target and run:

```sh
flutter devices
flutter run -d <device-id>
```

The iOS project requires a macOS/Xcode environment for build validation. Notification permissions, alarm behavior, contact selection, and external-app actions need separate device checks. The Android release configuration currently uses debug signing; it is not a production distribution configuration.

## Checks and current status

Existing focused tests cover appointment JSON serialization, formatting helpers, and translation lookup. Commands to run after preparing the SDK are:

```sh
flutter analyze
flutter test test/appointment_test.dart test/helpers_test.dart test/translations_test.dart
flutter test
```

Do not treat these commands as recorded passing results. Source inspection found two existing test mismatches: the widget smoke test still expects the starter counter app, and a translation assertion expects `My Appointments` while the current English title is `Appointly`. See [PROJECT_STATUS.md](docs/PROJECT_STATUS.md) for these findings and the device checks still needed.

This documentation pass did not run dependency resolution, analysis, tests, or platform builds because Flutter/Dart was not available on PATH in the review environment. Application code and platform configuration were left unchanged.

## Data and integrations

Appointment records and settings are stored locally. The inspected app code has no application backend or cloud-sync implementation; contact actions and the share sheet can still pass information to external apps selected by the user.

JSON exports contain client names, phone numbers, locations, and schedule details in plain text. They contain appointment records, not application settings. Imports write records by ID and can overwrite matching records; import is not transactional and may leave partial changes if a later record fails. Use disposable data when testing restore.

The inspected Hive initialization does not configure a database encryption cipher. Local storage should not be presented as a verified encryption or security guarantee. Reminders may also display client information in notifications.

## Licensing

No repository-wide license file is currently included. Dependency licenses do not automatically license this application's source or artwork. Confirm ownership and intended licensing before distributing or reusing the project.
