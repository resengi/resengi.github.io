import 'package:analytics_toolkit/analytics_toolkit.dart'
    show BucketKey, StringBucketKey, EnumBucketKey;
import 'package:flutter/material.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart' show GridConfig;

/// Visual theme for the charts: colors, sizing, typography, and the shared grid
/// math. Purely presentational; aggregation and axis bounds are handled by the
/// analytics layer and the bridge.

// ══ Color palette ═══════════════════════════════════════════════════════════

/// Fixed hue per known expense category. Pastel tones tuned to read both as
/// solid strokes and low-alpha fills. Categories not listed here defer to the
/// bridge's positional palette (a stable, distinct color per series ordinal).
const Map<String, Color> _namedCategoryColors = {
  'Software / AI Tools': Color(0xFF8CB5A0), // sage green
  'Software / Productivity': Color(0xFFD9A5A0), // dusty rose
  'Communications': Color(0xFFE3C895), // warm sand
  'Infrastructure / Domains': Color(0xFFB8A5D9), // dusty lavender
};

/// Neutral color for single-series charts where category doesn't apply —
/// e.g. cumulative spend.
const Color kNeutralSeriesColor = Color(0xFF7B9EAC);

/// Muted red for the company-books line (the running net).
const Color kNegativeSeriesColor = Color(0xFFC47D7D);

/// A `SemanticColorResolver` that keeps each known category on its fixed hue
/// across every chart. The bridge passes the series/segment's bucket key (the
/// category, for the category-grouped charts); this reads its string value and
/// looks it up. Returning null defers to the bridge's positional palette, so an
/// unknown category still gets a stable, distinct color.
Color? categoryColorResolver(String? semanticTag, BucketKey? key) {
  final name = switch (key) {
    StringBucketKey(value: final v) => v,
    EnumBucketKey(value: final v) => v,
    _ => semanticTag,
  };
  if (name == null) return null;
  return _namedCategoryColors[name];
}

// ══ Money formatting ════════════════════════════════════════════════════════
// The bridge has no currency formatter, so the website supplies its own: as a
// per-widget `yValueFormatter` for axis ticks, and for the tap-hint label.

/// `$1,234` (whole dollars with thousands separators).
String formatUsd(double v) => '\$${_grouped(v.round().abs())}';

/// `-$1,234` / `$1,234` (signed whole dollars).
String formatSignedUsd(double v) =>
    '${v < 0 ? '-' : ''}\$${_grouped(v.round().abs())}';

String _grouped(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ══ Chart sizing ════════════════════════════════════════════════════════════

/// Height of one chart cell within the grid.
const double kChartHeight = 360.0;

/// Spacing between grid cells, both vertical and horizontal.
const double kChartSpacing = 40.0;

/// Horizontal padding around the whole grid.
const double kGridHorizontalGutter = 40.0;

/// Vertical padding above and below the grid.
const double kGridVerticalPadding = 24.0;

/// Grid uses 2 columns at widths >= this breakpoint; 1 column below.
const double kTwoColBreakpoint = 560.0;

// ══ Visual tuning ═══════════════════════════════════════════════════════════

/// Fill alpha for segments of stacked bars (passed to the bridge bar widget).
const double kStackedBarFillAlpha = 0.35;

/// Fill alpha for single (non-stacked) bar charts.
const double kSingleBarFillAlpha = 0.25;

// ══ Typography ══════════════════════════════════════════════════════════════

const double kChartTitleFontSize = 17.0;
const double kHitLabelFontSize = 13.0;
const Color kChartTitleColor = Color(0xFF101828);
const Color kHitLabelIdleColor = Color(0xFF98A2B3);
const Color kHitLabelActiveColor = Color(0xFF344054);

// ══ Grid height math (single source of truth) ═══════════════════════════════

/// How many columns the grid uses at a given available width.
int columnsForWidth(double width) => width >= kTwoColBreakpoint ? 2 : 1;

/// Total content height (including vertical padding) for [chartCount] charts at
/// a given [maxWidth]. Used by both the layout and the iframe-height message so
/// they can't drift.
double computeGridHeight({required double maxWidth, required int chartCount}) {
  final cols = columnsForWidth(maxWidth);
  final rows = (chartCount / cols).ceil();
  final gridBody = rows * kChartHeight + (rows - 1) * kChartSpacing;
  return gridBody + 2 * kGridVerticalPadding;
}

// ══ Line-chart grid ═════════════════════════════════════════════════════════

/// Grid config for line charts: main ticks plus three intermediate sub-lines
/// between each pair, both axes. Passed to the line template. (Bar charts
/// don't take a grid config.)
const GridConfig kLineGridConfig = GridConfig(
  horizontalSubGridLinesBetweenTicks: 3,
  verticalSubGridLinesBetweenTicks: 3,
);
