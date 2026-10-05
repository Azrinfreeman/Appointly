# Project status and demo checks

This document records source observations from base commit `74bb39ea921adb0a4717f0405eebf0af3a84b52a`. The documentation branch changes the README, this status document, and one lockfile ignore exception. It does not change application behavior.

## Validation performed

- Inspected the appointment model, Hive database service, Provider state, reminder service, forms, settings, platform configuration, and existing tests.
- Reviewed feature descriptions against their corresponding source files.
- Flutter/Dart execution, dependency resolution, analysis, automated tests, and Android/iOS builds were not performed; Flutter/Dart was not available on PATH in the review environment.

## Existing setup and test gaps

| Finding | Evidence and next step |
| --- | --- |
| No tested Flutter SDK pin or resolved lockfile | [pubspec.yaml](../pubspec.yaml) declares a Dart range; `pubspec.lock` is absent. Resolve dependencies with a compatible SDK, record the version, and review the generated lockfile. |
| Missing Android wrapper tooling | Wrapper scripts and JAR are absent from tracked files. Restore them in a separate setup change and validate the checked-in Gradle/AGP/Kotlin combination. |
| Starter widget test is outdated | [widget_test.dart](../test/widget_test.dart) expects a counter and `+` button; [main.dart](../lib/main.dart) initializes storage, notifications, and onboarding. Replace it with a meaningful app test that isolates platform services. |
| Translation assertion is outdated | [translations_test.dart](../test/translations_test.dart) expects `My Appointments`; [translations.dart](../lib/utils/translations.dart) defines the English title as `Appointly`. Reconcile the test with intended branding. |
| Release signing is for development | [Android build configuration](../android/app/build.gradle.kts) uses debug signing for release. Prepare a separate distribution configuration before publishing a build. |

These are source findings, not captured compiler or test failures. No new CI workflow has been added to imply a passing build.

## Pending functional verification

- [ ] Initialize the app on a disposable device/emulator profile; exercise onboarding and the initialization error/retry path.
- [ ] Add, edit, search, and delete a one-time appointment; verify persistence after restart and deletion undo.
- [ ] Exercise weekly/monthly recurrence and excluded occurrences across Calendar and History. Check month-end dates: the calendar query matches the original day number, while history generation clamps to a shorter month's final day.
- [ ] Verify reminder offsets, denied permissions, timezone handling, restart/reboot behavior, and recurring appointments whose original start date is in the past. Confirm notification payloads and cancellation on Android and iOS separately.
- [ ] Pick a fictional contact and test external-app actions without sending real messages or placing calls.
- [ ] Export appointment JSON and restore into a disposable database. Test matching IDs, malformed records, and partial-import behavior; confirm settings are not included.
- [ ] Check themes, time formats, and translation coverage, including layout and text direction for the offered languages.
- [ ] Review the in-app privacy wording against storage, notifications, external sharing, and backup behavior before distribution.
- [ ] Record a device demo and screenshots using fictional data, alongside the tested SDK, dependency lockfile, device, and build outcome.

## Visibility

The repository was private at inspection. This documentation change does not change visibility, repository name, or licensing. Publication can be considered separately after ownership and repository-content review and explicit approval.
