import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

/// Single home for the chart visual theme: colors, sizing, and typography.
///
/// All tunable chart values live here. Grid layout in `main.dart` and
/// visual rendering in `charts.dart` both pull from this file, so changes
/// to e.g. chart height flow through automatically.

// ══ Color palette ═══════════════════════════════════════════════════════════

/// Named palette slot per expense category. Pastel hues tuned to stay
/// distinguishable both as solid strokes and as low-alpha fills.
const Map<String, Color> _namedCategoryColors = {
  'Software / AI Tools': Color(0xFF8CB5A0), // sage green
  'Software / Productivity': Color(0xFFD9A5A0), // dusty rose
  'Communications': Color(0xFFE3C895), // warm sand
  'Infrastructure / Domains': Color(0xFFB8A5D9), // dusty lavender
};

/// Fallback palette, used in sorted-category order for any category not
/// in [_namedCategoryColors]. Extend this list to support more new
/// spending areas without touching the named map.
const List<Color> _fallbackPalette = [
  Color(0xFF8FB8C4), // muted teal
  Color(0xFFD4A582), // soft terracotta
  Color(0xFF9BB5D4), // dusty blue
  Color(0xFFE0B8BE), // blush pink
  Color(0xFFD4C88F), // pale mustard
  Color(0xFFE5A89A), // soft coral
];

/// Last-resort color if both named and fallback palettes are exhausted.
const Color _finalFallback = Color(0xFF98A2B3);

/// Neutral color for single-series charts where category doesn't apply —
/// e.g. cumulative spend.
const Color kNeutralSeriesColor = Color(0xFF7B9EAC);

/// Muted red for the company-books line (which is negative-trending
/// until revenue data arrives).
const Color kNegativeSeriesColor = Color(0xFFC47D7D);

/// Builds a deterministic category → color map from a set of categories.
///
/// Named categories receive their fixed hue. Unnamed categories are
/// assigned fallback colors in alphabetical order, so the same category
/// always gets the same color across charts regardless of which chart
/// is built first or which rows appear first in the CSV.
Map<String, Color> buildCategoryPalette(Iterable<String> categories) {
  final result = <String, Color>{};
  final unnamed = <String>[];

  for (final cat in categories) {
    if (_namedCategoryColors.containsKey(cat)) {
      result[cat] = _namedCategoryColors[cat]!;
    } else if (!unnamed.contains(cat)) {
      unnamed.add(cat);
    }
  }

  unnamed.sort();
  for (var i = 0; i < unnamed.length; i++) {
    result[unnamed[i]] =
        i < _fallbackPalette.length ? _fallbackPalette[i] : _finalFallback;
  }

  return result;
}

// ══ Chart sizing ════════════════════════════════════════════════════════════

/// Height of one chart cell within the grid.
const double kChartHeight = 360.0;

/// Spacing between grid cells, both vertical and horizontal.
const double kChartSpacing = 40.0;

/// Horizontal padding around the whole grid. Explicitly narrows each
/// chart's width so the grid feels less edge-to-edge and gives columns
/// real breathing room.
const double kGridHorizontalGutter = 40.0;

/// Vertical padding above and below the grid.
const double kGridVerticalPadding = 24.0;

/// Grid uses 2 columns at widths >= this breakpoint; 1 column below.
const double kTwoColBreakpoint = 560.0;

// ══ Visual tuning ═══════════════════════════════════════════════════════════

/// Fill alpha for segments of stacked bars. Higher than the single-bar
/// alpha because stacked segments are narrower and need more saturation
/// to stay distinguishable.
const double kStackedBarFillAlpha = 0.35;

/// Fill alpha for single (non-stacked) bar charts.
const double kSingleBarFillAlpha = 0.25;

// ══ Typography ══════════════════════════════════════════════════════════════

/// Font size for chart titles (rendered by the card widget above the
/// CustomPaint, not by the hand_drawn_toolkit painter).
const double kChartTitleFontSize = 17.0;

/// Font size for the tap-hint / hit-label line under each title.
const double kHitLabelFontSize = 13.0;

/// Color for chart titles.
const Color kChartTitleColor = Color(0xFF101828);

/// Color for the tap hint when no value is currently selected.
const Color kHitLabelIdleColor = Color(0xFF98A2B3);

/// Color for the hit label when a value is selected.
const Color kHitLabelActiveColor = Color(0xFF344054);

// ══ Grid height math (single source of truth) ═══════════════════════════════

/// How many columns the grid will use at a given available width.
int columnsForWidth(double width) =>
    width >= kTwoColBreakpoint ? 2 : 1;

/// Total content height (including vertical padding) for a grid of
/// [chartCount] charts rendered at a given [maxWidth]. This is the same
/// value used by both the layout widgets and the iframe-height message,
/// so they can never drift apart.
double computeGridHeight({required double maxWidth, required int chartCount}) {
  final cols = columnsForWidth(maxWidth);
  final rows = (chartCount / cols).ceil();
  final gridBody = rows * kChartHeight + (rows - 1) * kChartSpacing;
  return gridBody + 2 * kGridVerticalPadding;
}

// ══ "Nice" y-axis bounds ════════════════════════════════════════════════════
// The hand_drawn_toolkit chart painter divides the axis range into 4 equal
// segments (5 labeled ticks). If (maxY − minY) is a not-round number, tick
// labels come out like 102 / 204 / 306 instead of 100 / 200 / 300. These
// helpers pick minY / maxY / step so the ticks land on familiar round
// numbers drawn from the [1, 2, 2.5, 5] × 10ⁿ family.

/// Result of [niceYAxis]: a y-axis range whose labels divide cleanly.
class NiceAxis {
  const NiceAxis({
    required this.minY,
    required this.maxY,
    required this.step,
  });

  final double minY;
  final double maxY;
  final double step;
}

/// Returns a "nice" y-axis covering the data range [dataMin, dataMax].
///
/// For non-negative data (the default when [dataMin] is omitted), the
/// axis starts at 0. For data that crosses zero (or is entirely below
/// zero, like the company-books chart pre-revenue), the axis spans both
/// sides of zero with the same clean step.
///
/// The tick step is drawn from [1, 2, 2.5, 5] × 10ⁿ which is the standard
/// used by most plotting libraries. The smallest step that covers the
/// data is selected so the plot uses as much of its vertical space as
/// possible while still landing on round labels.
NiceAxis niceYAxis({double dataMin = 0, required double dataMax}) {
  // Empty/flat-at-zero data: give the axis a sensible default shape so
  // an otherwise-blank chart still draws tick labels.
  if (dataMin == 0 && dataMax == 0) {
    return const NiceAxis(minY: 0, maxY: 10, step: 2.5);
  }

  // Flat non-zero data: expand slightly so there's a visible range.
  if ((dataMax - dataMin).abs() < 1e-9) {
    final margin = dataMax.abs() * 0.1;
    dataMin -= margin;
    dataMax += margin;
  }

  // If all data is on or above zero, pin the axis bottom to zero so the
  // chart doesn't awkwardly float above empty negative space.
  if (dataMin >= 0) dataMin = 0;

  for (final step in _niceSteps()) {
    // Walk allocations of 4 divisions between the negative and positive
    // sides of zero. Iterating `below` from 0 upward picks the tightest
    // fit: positive-only data gets minY=0; zero-crossing data uses the
    // minimum negative extent that still covers `dataMin`.
    for (var below = 0; below <= 4; below++) {
      final above = 4 - below;
      final minY = -below * step;
      final maxY = above * step;
      if (minY <= dataMin && maxY >= dataMax) {
        return NiceAxis(minY: minY, maxY: maxY, step: step);
      }
    }
  }

  // Unreachable for finite data, but fall back safely.
  return NiceAxis(
    minY: dataMin,
    maxY: dataMax,
    step: (dataMax - dataMin) / 4,
  );
}

/// Enumerates candidate tick steps in ascending order, drawn from the
/// [1, 2, 2.5, 5] × 10ⁿ family. The range of exponents covers everything
/// from fractions of a cent to billions.
Iterable<double> _niceSteps() sync* {
  const mantissas = [1.0, 2.0, 2.5, 5.0];
  for (var exp = -6; exp <= 9; exp++) {
    final base = math.pow(10, exp).toDouble();
    for (final m in mantissas) {
      yield m * base;
    }
  }
}

// ══ Line-chart grid ═════════════════════════════════════════════════════════

/// Grid configuration for line charts: main tick lines plus three
/// intermediate sub-lines between each pair of ticks, both horizontally
/// and vertically. Matches the `_subGrid` pattern used by the denser
/// examples in the hand_drawn_toolkit demo. Bar charts don't accept a
/// grid config.
const GridConfig kLineGridConfig = GridConfig(
  horizontalSubGridLinesBetweenTicks: 3,
  verticalSubGridLinesBetweenTicks: 3,
);