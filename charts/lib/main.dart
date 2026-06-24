import 'dart:js_interop';

import 'package:analytics_toolkit/analytics_toolkit.dart';
import 'package:flutter/material.dart';
import 'package:hand_drawn_analytics/hand_drawn_analytics.dart';
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
  /// The source catalog. The scope detects data-source changes by identity and
  /// derives its query runner from the current instances, so [_sources] and
  /// [_cache] are held as stable fields: a fresh list per rebuild would read as
  /// a new data source and refetch every chart.
  final List<SourceDef> _sources = [expensesSource];

  /// One cache per page, fed by the CSV loader. The bridge widgets read records
  /// through the scope's runner, which composes `cache.getOrFetch`.
  final SourceSnapshotCache _cache = SourceSnapshotCache(
    fetcher: fetchExpenseRecords,
  );

  /// Loads the records once to derive the charts' date range and to surface a
  /// load failure to the parent page up front (rather than the parent waiting
  /// on its own timeout). The chart widgets fetch their own data through
  /// [_cache]; this reads only the date span.
  late final Future<(DateTime, DateTime)> _dateSpan = _loadDateSpan();

  Future<(DateTime, DateTime)> _loadDateSpan() async {
    final records = await fetchExpenseRecords(kExpensesSourceId);
    return expenseDateSpan(records);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnalyticsScope(
        sources: _sources,
        cache: _cache,
        colorResolver: categoryColorResolver,
        child: FutureBuilder<(DateTime, DateTime)>(
          future: _dateSpan,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              // Tell the parent page to swap in its fallback UI immediately
              // rather than waiting for the 8-second load-failure timer.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _postToParent(const {'type': 'resengi-charts-error'});
              });
              return const _ErrorState();
            }
            final span = snapshot.data;
            if (span == null) return const SizedBox.shrink(); // loading
            // The four measures require a date range; use the data's own span,
            // so the monthly charts densify across exactly the months present.
            return _ChartsGrid(
              dateRange: FixedOverride(
                range: CustomRange(start: span.$1, end: span.$2),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Responsive grid of financial charts.
///
/// Each chart is a bridge widget that runs its query against the enclosing
/// [AnalyticsScope]. Sizing, spacing, breakpoints, and padding live in
/// `chart_theme.dart`. After layout, the exact content height is posted to the
/// parent page so the hosting iframe sizes itself with no hand-computed CSS.
class _ChartsGrid extends StatelessWidget {
  const _ChartsGrid({required this.dateRange});

  final DateRangeMode dateRange;

  @override
  Widget build(BuildContext context) {
    final charts = <Widget>[
      buildMonthlyExpensesChart(dateRange),
      buildCategoryTotalsChart(dateRange),
      buildCumulativeSpendChart(dateRange),
      buildCompanyBooksChart(dateRange),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = columnsForWidth(width);
        final innerWidth = width - 2 * kGridHorizontalGutter;
        final cellWidth =
            (innerWidth - kChartSpacing * (columns - 1)) / columns;

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

/// Sends a structured message to the parent page. The listener in
/// `financials.html` validates origin, source iframe, and message shape;
/// target-origin is pinned to our own origin.
void _postToParent(Map<String, Object?> message) {
  final parent = web.window.parent;
  if (parent == null) return;
  parent.postMessage(message.jsify(), web.window.location.origin.toJS);
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

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
