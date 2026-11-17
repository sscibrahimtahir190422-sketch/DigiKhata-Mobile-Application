# DigiKhata premium UI upgrade

## Scope
This package includes the complete `lib/` tree based on the uploaded DigiKhata source and the previous dashboard update. All repositories, viewmodels, models, bindings, Supabase calls and routes are preserved byte-for-byte from the previous package.

The shared Material 3 theme is refined for a cohesive emerald/ivory brand. Each existing screen with a direct `return Scaffold(...)` gets a presentation-only entrance animation. The dashboard keeps the previously redesigned premium layout. `lib/core/widgets/premium_ui.dart` provides reusable panels, titles, empty states, and skeletons for continued design work.

**Not a fully redesigned individual layout for every screen.** Those layouts remain largely unchanged except for theme and motion; this is intentionally conservative to protect behavior.

## Install
1. Back up or commit your current project.
2. Merge the `lib/` directory into the project, reviewing the diff before replacing any newer local changes.
3. Keep your existing working `pubspec.yaml`, Android/iOS branding, and assets.
4. Run `flutter pub get`, `dart format lib`, `flutter analyze`, `flutter test`, and `flutter run`.
5. If analyzer errors arise, restore from your backup and send the output.

No Flutter SDK or device test was available here, so compilation and behavioral compatibility are not certified.
