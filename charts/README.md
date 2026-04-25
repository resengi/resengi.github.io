# Resengi Charts

Live hand-drawn charts for the Financials page, powered by
[hand_drawn_toolkit](https://pub.dev/packages/hand_drawn_toolkit).

This is the source project. GitHub Actions builds the web bundle on
every push to `main` and publishes it to `/flutter-charts/` on the
deployed site, where it is loaded by `financials.html` inside an
iframe. The built output (`flutter-charts/`) is gitignored and never
committed. CI is the source of truth.

## First-time setup

```bash
flutter pub get
```

## Local preview build

To preview the chart bundle locally before pushing:

```bash
flutter build web --release --output=../flutter-charts
```

This drops the compiled bundle at the repo root in `flutter-charts/`,
the same path CI produces. Serve the repo root with any static server
(e.g. `python3 -m http.server`) and open `/financials.html` to see
the iframe load the local bundle.

The `../flutter-charts/` directory is gitignored, it is for local
preview only. Do not commit it. Pushing `charts/lib/` changes is
enough; CI will rebuild and publish on merge.

## Local development (hot reload)

```bash
flutter run -d chrome
```

The Flutter dev server fetches the CSV from the same origin. For that to
work during local development, either:

1. Run a simple web server from the website root (e.g.
   `python3 -m http.server`) and open the Flutter dev build alongside
   it, or
2. Point the CSV path in `lib/data.dart` at an absolute URL on a dev
   server.

## Files

- `lib/main.dart`: app entry point, loading/error states, chart layout
- `lib/data.dart`: CSV fetching and parsing (`FinancialData`,
  `ExpenseRow`)
- `lib/charts.dart`: the four chart widget builders
- `lib/chart_theme.dart`: shared chart styling

## Updating charts

**Data changes** (rows added to `data/expenses.csv`): no rebuild
needed. The deployed app reads the CSV on every page load and
reflects the change automatically.

**Chart code changes** (colors, chart types, labels): edit files
under `charts/lib/`, commit, and push. CI rebuilds
`/flutter-charts/` on deploy. Use the local preview build above to
verify before pushing.