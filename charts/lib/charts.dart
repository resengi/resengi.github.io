import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'chart_theme.dart';
import 'data.dart';

// ══ Chart builders ══════════════════════════════════════════════════════════
// Each builder returns a Widget that fills its grid cell. Bar-chart builders
// take a shared category palette so that "AI Tools" is the same color in
// every chart that mentions it.

// ---------- 1. Monthly expenses (stacked bar) ----------

Widget buildMonthlyExpensesChart(
  List<ExpenseRow> expenses,
  Map<String, Color> palette,
) {
  if (expenses.isEmpty) {
    return const _EmptyChart(
      title: 'Monthly company expenses',
      message: 'No expense data yet.',
    );
  }

  // Group (month, category) → summed company amount.
  final grouped = <String, Map<String, double>>{};
  final categories = <String>{};
  for (final row in expenses) {
    final monthKey =
        '${row.date.year}-${row.date.month.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(monthKey, () => <String, double>{});
    grouped[monthKey]![row.category] =
        (grouped[monthKey]![row.category] ?? 0) + row.companyAmount;
    categories.add(row.category);
  }

  final orderedMonths = grouped.keys.toList()..sort();
  final orderedCategories = categories.toList()..sort();

  // Per-month stacked total, used to size the y-axis.
  final tallestMonth = orderedMonths
      .map((m) => grouped[m]!.values.fold<double>(0, (a, b) => a + b))
      .fold<double>(0, math.max);
  final axis = niceYAxis(dataMax: tallestMonth);

  final bars = orderedMonths
      .map(
        (month) => BarGroup(
          label: _shortMonthLabel(month),
          segments: orderedCategories
              .where((cat) => (grouped[month]?[cat] ?? 0) > 0)
              .map(
                (cat) => BarSegment(
                  category: cat,
                  value: grouped[month]![cat]!,
                  color: palette[cat] ?? Colors.grey,
                  fillAlpha: kStackedBarFillAlpha,
                ),
              )
              .toList(),
        ),
      )
      .toList();

  final legend = orderedCategories
      .map((cat) => LegendEntry(label: cat, color: palette[cat] ?? Colors.grey))
      .toList();

  return InteractiveBarChartCard(
    title: 'Monthly company expenses',
    tapHint: 'Tap a segment for the exact amount.',
    seed: 42,
    valueFormatter: _formatUsd,
    legendConfig: ChartLegendConfig.externalBottomBoxed,
    data: BarChartData(
      title: '',
      yAxisLabel: 'USD',
      maxY: axis.maxY,
      bars: bars,
      legend: legend,
      yValueFormatter: (v) => '\$${v.toInt()}',
    ),
  );
}

// ---------- 2. Total spend by category (bar) ----------

Widget buildCategoryTotalsChart(
  List<ExpenseRow> expenses,
  Map<String, Color> palette,
) {
  if (expenses.isEmpty) {
    return const _EmptyChart(
      title: 'Total spend by category',
      message: 'No expense data yet.',
    );
  }

  final totals = <String, double>{};
  for (final row in expenses) {
    totals[row.category] = (totals[row.category] ?? 0) + row.companyAmount;
  }
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final axis = niceYAxis(dataMax: entries.first.value);

  final bars = entries
      .map(
        (e) => BarGroup(
          label: e.key,
          segments: [
            BarSegment(
              category: e.key,
              value: e.value,
              color: palette[e.key] ?? Colors.grey,
              fillAlpha: kSingleBarFillAlpha,
            ),
          ],
        ),
      )
      .toList();

  return InteractiveBarChartCard(
    title: 'Total spend by category',
    tapHint: 'Tap a bar for the exact total.',
    seed: 43,
    valueFormatter: _formatUsd,
    xLabelConfig: ChartLabelConfig.diagonalLeft,
    legendConfig: ChartLegendConfig.hidden,
    data: BarChartData(
      title: '',
      yAxisLabel: 'USD',
      maxY: axis.maxY,
      bars: bars,
      // legend currently commented out beacuse it is hidden but can be brought back.
      // legend: entries
      //     .map(
      //       (e) =>
      //           LegendEntry(label: e.key, color: palette[e.key] ?? Colors.grey),
      //     )
      //     .toList(),
      // yValueFormatter: (v) => '\$${v.toInt()}',
    ),
  );
}

// ---------- 3. Cumulative spend (line) ----------

Widget buildCumulativeSpendChart(List<ExpenseRow> expenses) {
  if (expenses.isEmpty) {
    return const _EmptyChart(
      title: 'Cumulative spend',
      message: 'No expense data yet.',
    );
  }

  final (monthlyTotals, months) = _monthlyTotals(expenses);

  final points = <LinePoint>[];
  final labels = <String>[];
  var running = 0.0;
  for (var i = 0; i < months.length; i++) {
    running += monthlyTotals[months[i]]!;
    points.add(LinePoint(x: i.toDouble(), y: running));
    labels.add(_shortMonthLabel(months[i]));
  }

  final axis = niceYAxis(dataMax: running);

  return InteractiveLineChartCard(
    title: 'Cumulative spend',
    tapHint: 'Tap a point for the exact total.',
    seed: 45,
    unit: '',
    valueFormatter: _formatUsd,
    data: LineChartData(
      title: '',
      yAxisLabel: 'USD',
      minX: 0,
      maxX: (months.length - 1).toDouble().clamp(1, double.infinity),
      minY: axis.minY,
      maxY: axis.maxY,
      xLabels: labels,
      series: [
        LineSeriesData(
          name: 'Cumulative spend',
          color: kNeutralSeriesColor,
          points: points,
        ),
      ],
    ),
  );
}

// ---------- 4. Company books (line) ----------
//
// Running net (revenue − spend) over time.

Widget buildCompanyBooksChart(List<ExpenseRow> expenses) {
  if (expenses.isEmpty) {
    return const _EmptyChart(
      title: 'Company books',
      message: 'No expense data yet.',
    );
  }

  final (monthlyTotals, months) = _monthlyTotals(expenses);

  final points = <LinePoint>[];
  final labels = <String>[];
  var running = 0.0;
  for (var i = 0; i < months.length; i++) {
    running += monthlyTotals[months[i]]!;
    points.add(LinePoint(x: i.toDouble(), y: -running));
    labels.add(_shortMonthLabel(months[i]));
  }

  // Axis spans the actual data range. While revenue data doesn't exist
  // yet, maxY ends up at 0 (zero line at the plot's top edge); once
  // revenue arrives and pushes points above zero, maxY expands
  // naturally. This gives the tightest "nice" fit at every stage.
  final values = points.map((p) => p.y).toList();
  final rawMin = values.reduce(math.min);
  final rawMax = values.reduce(math.max);
  final axis = niceYAxis(dataMin: rawMin, dataMax: rawMax);

  return InteractiveLineChartCard(
    title: 'Company books',
    tapHint: 'Tap a point for the exact net.',
    seed: 46,
    unit: '',
    valueFormatter: _formatSignedUsd,
    data: LineChartData(
      title: '',
      yAxisLabel: 'USD',
      minX: 0,
      maxX: (months.length - 1).toDouble().clamp(1, double.infinity),
      minY: axis.minY,
      maxY: axis.maxY,
      xLabels: labels,
      axisDisplay: const AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
      series: [
        LineSeriesData(
          name: 'Net',
          color: kNegativeSeriesColor,
          showFill: false,
          points: points,
        ),
      ],
    ),
  );
}

// ══ Interactive card widgets ════════════════════════════════════════════════
// Each card renders its own title (so we control the font size) plus a
// tap-hint line that turns into the selected value when the user taps a
// data element. Modeled on the `_InteractiveBarChart` and
// `_InteractiveLineChart` patterns from the hand_drawn_toolkit demo.

class InteractiveBarChartCard extends StatefulWidget {
  const InteractiveBarChartCard({
    super.key,
    required this.title,
    required this.tapHint,
    required this.data,
    required this.valueFormatter,
    this.seed = 42,
    this.xLabelConfig = ChartLabelConfig.horizontal,
    this.legendConfig = ChartLegendConfig.inlineBottom,
  });

  final String title;
  final String tapHint;
  final BarChartData data;
  final String Function(double value) valueFormatter;
  final int seed;
  final ChartLabelConfig xLabelConfig;
  final ChartLegendConfig legendConfig;

  @override
  State<InteractiveBarChartCard> createState() =>
      _InteractiveBarChartCardState();
}

class _InteractiveBarChartCardState extends State<InteractiveBarChartCard> {
  String? _hitLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChartTitle(widget.title),
        const SizedBox(height: 4),
        _HitLabel(
          text: _hitLabel ?? widget.tapHint,
          isActive: _hitLabel != null,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final painter = HandDrawnBarChartPainter(
                data: widget.data,
                seed: widget.seed,
                xLabelConfig: widget.xLabelConfig,
                legendConfig: widget.legendConfig,
              );
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final layout = painter.computeLayout(size);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final hit = layout.hitTest(details.localPosition);
                  if (hit == null) {
                    setState(() => _hitLabel = null);
                    return;
                  }
                  final s = hit.segment;
                  final formatted = widget.valueFormatter(s.value);
                  // For stacked bars, group label and segment category
                  // differ (e.g. "Feb '26" vs "Communications"). For
                  // single bars, they're the same.
                  final label = s.barLabel == s.category
                      ? '${s.barLabel}: $formatted'
                      : '${s.barLabel} · ${s.category}: $formatted';
                  setState(() => _hitLabel = label);
                },
                child: CustomPaint(size: size, painter: painter),
              );
            },
          ),
        ),
      ],
    );
  }
}

class InteractiveLineChartCard extends StatefulWidget {
  const InteractiveLineChartCard({
    super.key,
    required this.title,
    required this.tapHint,
    required this.data,
    required this.valueFormatter,
    this.seed = 42,
    this.unit = '',
    this.grid = kLineGridConfig,
    this.legendConfig = ChartLegendConfig.inlineBottom,
  });

  final String title;
  final String tapHint;
  final LineChartData data;
  final String Function(double value) valueFormatter;
  final int seed;
  final String unit;
  final GridConfig grid;
  final ChartLegendConfig legendConfig;

  @override
  State<InteractiveLineChartCard> createState() =>
      _InteractiveLineChartCardState();
}

class _InteractiveLineChartCardState extends State<InteractiveLineChartCard> {
  String? _hitLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChartTitle(widget.title),
        const SizedBox(height: 4),
        _HitLabel(
          text: _hitLabel ?? widget.tapHint,
          isActive: _hitLabel != null,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final painter = HandDrawnLineChartPainter(
                data: widget.data,
                seed: widget.seed,
                grid: widget.grid,
                legendConfig: widget.legendConfig,
              );
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final layout = painter.computeLayout(size);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final hit = layout.hitTest(details.localPosition);
                  // Per UX spec: only respond to hits on actual points.
                  // Taps between points (LineSegmentHit) are ignored, and
                  // taps with no hit clear the label.
                  if (hit is! LinePointHit) {
                    if (hit == null) setState(() => _hitLabel = null);
                    return;
                  }
                  final labels = widget.data.xLabels;
                  final xLabel = hit.pointIndex < labels.length
                      ? labels[hit.pointIndex]
                      : hit.point.x.toStringAsFixed(1);
                  final formatted = widget.valueFormatter(hit.point.y);
                  final suffix = widget.unit.isEmpty ? '' : ' ${widget.unit}';
                  setState(() => _hitLabel = '$xLabel: $formatted$suffix');
                },
                child: CustomPaint(size: size, painter: painter),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ══ Shared card sub-widgets ═════════════════════════════════════════════════

class _ChartTitle extends StatelessWidget {
  const _ChartTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: kChartTitleFontSize,
        fontWeight: FontWeight.w600,
        color: kChartTitleColor,
      ),
    );
  }
}

class _HitLabel extends StatelessWidget {
  const _HitLabel({required this.text, required this.isActive});
  final String text;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: kHitLabelFontSize,
        color: isActive ? kHitLabelActiveColor : kHitLabelIdleColor,
        fontStyle: isActive ? FontStyle.normal : FontStyle.italic,
      ),
    );
  }
}

// ══ Label & formatter helpers ═══════════════════════════════════════════════

String _shortMonthLabel(String yyyyMm) {
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final parts = yyyyMm.split('-');
  final monthIdx = int.parse(parts[1]) - 1;
  final yearShort = parts[0].substring(2);
  return "${monthNames[monthIdx]} '$yearShort";
}

String _formatUsd(double v) {
  final whole = v.truncateToDouble() == v;
  return whole ? '\$${v.toInt()}' : '\$${v.toStringAsFixed(2)}';
}

String _formatSignedUsd(double v) {
  final sign = v < 0 ? '-' : '';
  final abs = v.abs();
  final whole = abs.truncateToDouble() == abs;
  return whole ? '$sign\$${abs.toInt()}' : '$sign\$${abs.toStringAsFixed(2)}';
}

/// Groups expenses by YYYY-MM and returns both the month → total map and
/// the sorted list of month keys. Used by the cumulative-spend and
/// company-books charts, which share the same monthly binning.
(Map<String, double>, List<String>) _monthlyTotals(List<ExpenseRow> expenses) {
  final totals = <String, double>{};
  for (final row in expenses) {
    final key = '${row.date.year}-${row.date.month.toString().padLeft(2, '0')}';
    totals[key] = (totals[key] ?? 0) + row.companyAmount;
  }
  final sorted = totals.keys.toList()..sort();
  return (totals, sorted);
}

// ══ Empty state ═════════════════════════════════════════════════════════════

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChartTitle(title),
        const SizedBox(height: 4),
        const _HitLabel(text: '', isActive: false),
        const SizedBox(height: 8),
        Expanded(
          child: Center(
            child: Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
