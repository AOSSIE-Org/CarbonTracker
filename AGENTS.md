# CarbonTracker

Flutter/Dart mobile app. Local-first, privacy-focused fitness and carbon tracker.
State management: Riverpod. Local storage: SQLite via sqflite. No backend, no cloud.

## Commands

Install deps: `flutter pub get`
Run: `flutter run`
Test: `flutter test`
Analyze: `flutter analyze`
Format: `dart format .`

## Code Style

Follow Effective Dart. Use `flutter_lints`, don't introduce new lint warnings.

Prefer `const` constructors for widgets that don't change.
Use `final` for variables that aren't reassigned.

State management uses `NotifierProvider`, not `StateNotifierProvider`:

// Riverpod pattern used in this project:
final tripProvider = NotifierProvider<TripsNotifier, List<Trip>>(
TripsNotifier.new,
);

Extract large `build()` methods into smaller private widgets, don't let a single
build() method handle multiple concerns.

## Architecture

lib/features/ — contains a folder per individual feature (e.g. trip tracking,
fitness metrics, carbon insights, profile).

lib/core/ — shared code, split into: config/, data/, enums/, extensions/,
providers/, widgets/

Database logic lives separately:
lib/database/ — contains models/, database_helper.dart, database_exceptions.dart

DatabaseHelper is a singleton, never instantiate the SQLite connection directly,
always go through it.

Never call Health Connect / geolocation APIs directly from widgets, go through
the relevant provider.

## Testing

Testing setup exists (`flutter test` runs), but conventions are not yet established.
Only a couple of setup/scaffolding tests exist so far. Don't assume a testing pattern;
ask before writing tests in a specific style.

## Boundaries

Never commit API keys or secrets.
Never add cloud storage, analytics, or telemetry that transmits user data off-device.
This app is local-first by design (see PRIVACY.md).

## Git

Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
Branch format: `feature/short-description` or `fix/short-description`.
