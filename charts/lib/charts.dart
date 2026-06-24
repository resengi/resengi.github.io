import 'package:analytics_toolkit/analytics_toolkit.dart' show DateRangeMode;
import 'package:flutter/material.dart';
import 'package:hand_drawn_analytics/hand_drawn_analytics.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'chart_theme.dart';
import 'queries.dart';

// ── Chart builders ────────────────────────────────────────────────────────────
// Each returns a card (website-owned title + tap-hint chrome) wrapping a bridge
// widget that runs its query against the enclosing AnalyticsScope. The bridge
// fills the chart data; the scope supplies the runner, palette, formatters, and
// the category color resolver, so no per-widget wiring of those is needed.

/// 1. Monthly company expenses, stacked bar by category per month.
Widget buildMonthlyExpensesChart(DateRangeMode dateRange) => _ChartCard(
  title: 'Monthly company expenses',
  tapHint: 'Tap a segment for the exact amount.',
  chartBuilder: (onHit, onClear) => HandDrawnAnalyticsBarChart(
    query: monthlyExpensesQuery(),
    mode: BarMode.stacked,
    dateRangeMode: dateRange,
    chart: const HandDrawnBarChart(
      data: null,
      seed: 42,
      legendConfig: ChartLegendConfig.externalBottomBoxed,
    ),
    fillAlpha: kStackedBarFillAlpha,
    yValueFormatter: formatUsd,
    onTap: (hit) => onHit(_describeBarHit(hit, showCategory: true)),
    onTapMiss: onClear,
  ),
);

/// 2. Total spend by category: single bar, sorted descending, legend hidden.
Widget buildCategoryTotalsChart(DateRangeMode dateRange) => _ChartCard(
  title: 'Total spend by category',
  tapHint: 'Tap a bar for the exact total.',
  chartBuilder: (onHit, onClear) => HandDrawnAnalyticsBarChart(
    query: categoryTotalsQuery(),
    mode: BarMode.single,
    dateRangeMode: dateRange,
    chart: const HandDrawnBarChart(
      data: null,
      seed: 43,
      xLabelConfig: ChartLabelConfig.diagonalLeft,
      legendConfig: ChartLegendConfig.hidden,
    ),
    fillAlpha: kSingleBarFillAlpha,
    yValueFormatter: formatUsd,
    onTap: (hit) => onHit(_describeBarHit(hit, showCategory: false)),
    onTapMiss: onClear,
  ),
);

/// 3. Cumulative spend: running total line (neutral color).
Widget buildCumulativeSpendChart(DateRangeMode dateRange) => _ChartCard(
  title: 'Cumulative spend',
  tapHint: 'Tap a point for the exact total.',
  chartBuilder: (onHit, onClear) => HandDrawnAnalyticsLineChart(
    query: cumulativeSpendQuery(),
    dateRangeMode: dateRange,
    chart: const HandDrawnLineChart(
      data: null,
      seed: 45,
      grid: kLineGridConfig,
    ),
    // Single-color palette so the one line resolves to the neutral hue; the
    // scope's category resolver returns null for month keys and defers here.
    palette: const BridgePalette(colors: [kNeutralSeriesColor]),
    yValueFormatter: formatUsd,
    onTap: (hit) {
      final label = _describeLineHit(hit, signed: false);
      if (label != null) onHit(label);
    },
    onTapMiss: onClear,
  ),
);

/// 4. Company books: running net line (negative-trending; zero-crossing axis).
Widget buildCompanyBooksChart(DateRangeMode dateRange) => _ChartCard(
  title: 'Company books',
  tapHint: 'Tap a point for the exact net.',
  chartBuilder: (onHit, onClear) => HandDrawnAnalyticsLineChart(
    query: companyBooksQuery(),
    dateRangeMode: dateRange,
    chart: const HandDrawnLineChart(
      data: null,
      seed: 46,
      grid: kLineGridConfig,
    ),
    palette: const BridgePalette(colors: [kNegativeSeriesColor]),
    // Draw the value axis at the zero line (the running net is signed).
    axisDisplay: const AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
    yValueFormatter: formatSignedUsd,
    onTap: (hit) {
      final label = _describeLineHit(hit, signed: true);
      if (label != null) onHit(label);
    },
    onTapMiss: onClear,
  ),
);

// ── Hit-result formatting ──────────────────────────────────────────────────────

String _describeBarHit(BarHitTestResult hit, {required bool showCategory}) {
  final s = hit.segment;
  final amount = formatUsd(s.value);
  // On the stacked chart the bar label is the month and the segment category
  // is the expense category, so both carry information. On a single-series bar
  // the segment category is just the measure, which the bar label already
  // conveys.
  return showCategory
      ? '${s.barLabel} · ${s.category}: $amount'
      : '${s.barLabel}: $amount';
}

String? _describeLineHit(LineHitTestResult hit, {required bool signed}) {
  // Only a point carries a value; a tap on the line between points is a
  // LineSegmentHit with no point, so ignore it.
  if (hit is! LinePointHit) return null;
  final y = hit.point.y;
  return signed ? formatSignedUsd(y) : formatUsd(y);
}

// ── Card chrome (website-owned title + tap-hint line) ──────────────────────────

/// Title + tap-hint/value line above a chart. The bridge widget renders only
/// the chart body and surfaces taps via `onTap`/`onTapMiss`; this card owns the
/// title and the line that turns into the tapped value.
class _ChartCard extends StatefulWidget {
  const _ChartCard({
    required this.title,
    required this.tapHint,
    required this.chartBuilder,
  });

  final String title;
  final String tapHint;

  /// Builds the chart, given callbacks to set/clear the hit-label text.
  final Widget Function(void Function(String) onHit, VoidCallback onClear)
  chartBuilder;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  String? _hit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChartTitle(widget.title),
        const SizedBox(height: 2),
        _HitLabel(text: _hit ?? widget.tapHint, active: _hit != null),
        const SizedBox(height: 8),
        Expanded(
          child: widget.chartBuilder(
            (text) => setState(() => _hit = text),
            () => setState(() => _hit = null),
          ),
        ),
      ],
    );
  }
}

class _ChartTitle extends StatelessWidget {
  const _ChartTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: kChartTitleFontSize,
        fontWeight: FontWeight.w600,
        color: kChartTitleColor,
      ),
    );
  }
}

class _HitLabel extends StatelessWidget {
  const _HitLabel({required this.text, required this.active});
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: kHitLabelFontSize,
        color: active ? kHitLabelActiveColor : kHitLabelIdleColor,
        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
