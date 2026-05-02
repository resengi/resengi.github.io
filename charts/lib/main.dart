import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'chart_theme.dart';
import 'charts.dart';
import 'data.dart';

void main() {
  runApp(const ChartsApp());
}

class ChartsApp extends StatelessWidget {
  const ChartsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily:
              '-apple-system, BlinkMacSystemFont, Segoe UI, '
              'Helvetica, Arial, sans-serif',
          bodyColor: const Color(0xFF344054),
          displayColor: const Color(0xFF101828),
        ),
      ),
      home: const ChartsView(),
    );
  }
}

class ChartsView extends StatefulWidget {
  const ChartsView({super.key});

  @override
  State<ChartsView> createState() => _ChartsViewState();
}

class _ChartsViewState extends State<ChartsView> {
  late Future<FinancialData> _data;

  @override
  void initState() {
    super.initState();
    _data = loadFinancialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<FinancialData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) {
            // Tell the parent page to swap in its fallback UI immediately
            // rather than waiting for the 8-second load-failure timer.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _postToParent(const {'type': 'resengi-charts-error'});
            });
            return _ErrorState(error: snapshot.error);
          }
          return _ChartsGrid(data: snapshot.data!);
        },
      ),
    );
  }
}

/// Responsive grid of financial charts.
///
/// The grid uses [LayoutBuilder] to pick a column count from the available
/// width via [columnsForWidth]. Chart sizing, spacing, breakpoints, and
/// padding all live in `chart_theme.dart`.
///
/// After the grid lays out, we post the exact content height to the
/// parent page via `window.postMessage`, so the iframe hosting this app
/// can size itself to fit with no hand-computed CSS heights.
class _ChartsGrid extends StatelessWidget {
  const _ChartsGrid({required this.data});

  final FinancialData data;

  @override
  Widget build(BuildContext context) {
    // Build the shared category palette once from all categories present
    // in the data, so every chart that shows a category uses the same
    // color for it.
    final categoriesInData = data.expenses.map((e) => e.category).toSet();
    final palette = buildCategoryPalette(categoriesInData);

    final charts = <Widget>[
      buildMonthlyExpensesChart(data.expenses, palette),
      buildCategoryTotalsChart(data.expenses, palette),
      buildCumulativeSpendChart(data.expenses),
      buildCompanyBooksChart(data.expenses),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = columnsForWidth(width);
        final innerWidth = width - 2 * kGridHorizontalGutter;
        final cellWidth =
            (innerWidth - kChartSpacing * (columns - 1)) / columns;

        // Post the content height to the parent page after this frame
        // paints. Recomputed on every layout change (e.g. window resize);
        // parent handler is idempotent.
        final requiredHeight = computeGridHeight(
          maxWidth: width,
          chartCount: charts.length,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _postToParent({
            'type': 'resengi-charts-ready',
            'height': requiredHeight.round(),
          });
        });

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: kGridHorizontalGutter,
            vertical: kGridVerticalPadding,
          ),
          child: Wrap(
            spacing: kChartSpacing,
            runSpacing: kChartSpacing,
            children: [
              for (final chart in charts)
                SizedBox(width: cellWidth, height: kChartHeight, child: chart),
            ],
          ),
        );
      },
    );
  }
}

/// Sends a structured message to the parent page.
///
/// The parent-page listener in `financials.html` validates origin,
/// source iframe, and message shape before acting on anything we send.
/// Target-origin is pinned to our own origin (iframes of this app are
/// always served same-origin with the parent page) so nothing ever
/// leaks to an unexpected parent.
void _postToParent(Map<String, Object?> message) {
  final parent = web.window.parent;
  if (parent == null) return;
  parent.postMessage(message.jsify(), web.window.location.origin.toJS);
}

class _ErrorState extends StatelessWidget {
  final Object? error;
  const _ErrorState({this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Unable to load financial data. The underlying CSV is still '
          'available for download above.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }
}
