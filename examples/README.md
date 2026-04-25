# Resengi Examples

Live demos of the Resengi open-source packages, embedded as iframes in the Open Source page of the main website.

This is the source project. The built output goes to `../flutter-examples/` at the website root and is referenced by `opensource.html`.

## Showcased packages

- [`hand_drawn_toolkit`](https://pub.dev/packages/hand_drawn_toolkit): hand-drawn sketchy lines, borders, containers
- [`page_turn_animation`](https://pub.dev/packages/page_turn_animation): realistic page turn / curl animation
- [`recurrence_kit`](https://pub.dev/packages/recurrence_kit): recurrence rule system with picker UI
- [`flip_calendar`](https://pub.dev/packages/flip_calendar): calendar widget with page-turn animations

## First-time setup

```bash
flutter pub get
```

## Building for production

```bash
flutter build web --release --output=../flutter-examples
```

In development, the build output directory is git-ignored; the production deploy pipeline (`.github/workflows/deploy.yml`) runs this command on every push to `main` and deploys the result to GitHub Pages.

## Local development

```bash
flutter run -d chrome
```

Then append `?demo=<slug>` to the URL to load a specific demo, or leave it off to see the landing-page index.

## How it works

A single Flutter app is built once. Which of the four demos renders is controlled by the `demo` query parameter in the URL:

| URL | What renders |
|---|---|
| `/flutter-examples/?demo=hand-drawn-toolkit` | `HandDrawnToolkitDemo` |
| `/flutter-examples/?demo=page-turn-animation` | `PageTurnDemo` |
| `/flutter-examples/?demo=recurrence-kit` | `RecurrenceKitDemo` |
| `/flutter-examples/?demo=flip-calendar` | `FlipCalendarDemo` |
| `/flutter-examples/` (no slug) | A small dev-only landing page listing all four demos |

Each iframe on `opensource.html` loads one of these URLs, so a visitor who clicks "Load interactive demo" on, say, the `recurrence_kit` card ends up with an iframe containing just that one demo.

## Project structure

- `lib/main.dart`: entry point. Reads `?demo=<slug>`, looks up a `Widget Function()` in the `_demos` map, runs that widget (or the `_LandingPage` fallback).
- `lib/demos/hand_drawn_toolkit_demo.dart`: `HandDrawnToolkitDemo`
- `lib/demos/page_turn_animation_demo.dart`: `PageTurnDemo`
- `lib/demos/recurrence_kit_demo.dart`: `RecurrenceKitDemo`
- `lib/demos/flip_calendar_demo.dart`: `FlipCalendarDemo`

Each demo file is a near-verbatim adaptation of the corresponding package's own `example/lib/main.dart`. The only changes are (1) the `void main() => runApp(...)` wrapper is stripped and (2) the root widget class is renamed to match the routing map.

## Updating a demo when a package publishes a new version

The four demos in `lib/demos/` are adaptations of each package's own example app. To keep them in sync with upstream:

1. Bump the corresponding version in `pubspec.yaml`.
2. Open the package's `example/lib/main.dart` in its repo; copy out any changes.
3. Re-adapt the matching `lib/demos/<package>_demo.dart`:
   - Strip the `void main() => runApp(...)` wrapper.
   - Rename the root widget class to match the existing `*Demo` class name.
   - Leave everything else (imports, helpers, constants) byte-for-byte.
4. Run `flutter pub get` and test locally via `flutter run -d chrome`, visiting each `?demo=<slug>` URL.
5. Commit. CI rebuilds and deploys.

## Important! Keep slug names in sync

The slug keys in `lib/main.dart`'s `_demos` map are the single source of truth for which demos exist, BUT they must also stay in sync with the `data-slug` attributes in `opensource.html`. If you add or remove a demo, update both sides.