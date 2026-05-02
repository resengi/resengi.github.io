import 'package:flutter/material.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

// ── Palette ───────────────────────────────────────────────────────────────
const _ink = Color(0xFF2C2C2C);
const _inkLight = Color(0xFF6B6B6B);
const _accent = Color(0xFF4A7C6F);
const _cardFill = Color(0xFFFAF7F2);

// ── Notebook grid ─────────────────────────────────────────────────────────
const _notebookFontSize = 15.0;
const _notebookLineHeight = 28.0;

// ── Sub-grid preset reused across a few charts ────────────────────────────
const _subGrid = GridConfig(
  horizontalSubGridLinesBetweenTicks: 3,
  verticalSubGridLinesBetweenTicks: 3,
);

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _formatDate(DateTime date) =>
    '${_months[date.month - 1]} ${date.day}, ${date.year}';

class HandDrawnToolkitDemo extends StatelessWidget {
  const HandDrawnToolkitDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hand Drawn Toolkit Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F0E8),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Georgia'),
        ),
      ),
      home: const JournalPage(),
    );
  }
}

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final List<_TaskItem> _tasks = [
    const _TaskItem('Read a chapter of a good book'),
    const _TaskItem('Sketch something from observation'),
    const _TaskItem('Take a 20-minute walk', status: _TaskStatus.completed),
    const _TaskItem('Write morning pages', status: _TaskStatus.skipped),
  ];

  void _cycleStatus(int index) =>
      setState(() => _tasks[index] = _tasks[index].cycled());

  final Map<String, String?> _hits = {};
  void _setHit(String id, String? label) {
    setState(() {
      if (label == null) {
        _hits.remove(id);
      } else {
        _hits[id] = label;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hand Drawn Toolkit',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 170,
                height: 8,
                child: CustomPaint(
                  painter: HandDrawnLinePainter(
                    color: _ink,
                    strokeWidth: 2.0,
                    irregularity: 2.0,
                    seed: 42,
                    buildPath: (size, h) => h.lineHorizontal(size),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _formatDate(DateTime.now()),
                style: const TextStyle(
                  fontSize: 14,
                  color: _inkLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              const HandDrawnDivider(color: _inkLight, seed: 42),
              const SizedBox(height: 24),

              const HandDrawnContainer(
                backgroundColor: _cardFill,
                strokeColor: _ink,
                strokeWidth: 1.8,
                irregularity: 3.0,
                seed: 6,
                padding: EdgeInsets.all(20),
                child: Text(
                  'Hand Drawn Toolkit is a lightweight Flutter package for '
                  'rendering sketchy, organic lines, borders, and containers. '
                  'It generates random perpendicular offsets along a path and '
                  'smooths them with a three-point moving average to produce '
                  'natural-looking wobble.\n\nThe package has zero external '
                  'dependencies and relies entirely on the Flutter SDK. All '
                  'randomness is seed-based, so identical parameters always '
                  'produce identical strokes.',
                  style: TextStyle(fontSize: 15, height: 1.6, color: _ink),
                ),
              ),

              const SizedBox(height: 28),
              const Text(
                'Key Components',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 14),
              const _GoalItem(
                seed: 9,
                text:
                    'HandDrawnContainer wraps any '
                    'child widget with a sketchy rectangular border and solid '
                    'background fill.',
              ),
              const SizedBox(height: 10),
              const _GoalItem(
                seed: 20,
                text:
                    'HandDrawnDivider is a drop-in '
                    "replacement for Flutter's Divider, supporting both "
                    'orientations.',
              ),
              const SizedBox(height: 10),
              const _GoalItem(
                seed: 49,
                text:
                    'HandDrawnLinePainter provides '
                    'full control via a buildPath callback for custom shapes.',
              ),

              const SizedBox(height: 28),
              const HandDrawnDivider(
                color: _inkLight,
                indent: 32,
                endIndent: 32,
                seed: 40,
              ),
              const SizedBox(height: 28),

              const Text(
                'Status Square',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap each square to cycle through empty, checked, '
                'and dashed.',
                style: TextStyle(fontSize: 14, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 16),
              HandDrawnContainer(
                backgroundColor: _cardFill,
                strokeColor: _ink,
                strokeWidth: 1.4,
                irregularity: 2.5,
                seed: 77,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HandDrawnNotebook(
                  lineHeight: _notebookLineHeight,
                  lineColor: const Color(0xFFB0AAA0),
                  irregularity: 2.0,
                  uniformLines: false,
                  seed: 50,
                  child: Column(
                    children: [
                      for (var i = 0; i < _tasks.length; i++)
                        _TaskRow(
                          task: _tasks[i],
                          seed: i * 13 + 5,
                          onTap: () => _cycleStatus(i),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              const HandDrawnDivider(
                color: _inkLight,
                indent: 32,
                endIndent: 32,
                seed: 55,
              ),
              const SizedBox(height: 28),

              const Text(
                'Text Field',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 16),
              const HandDrawnTextField(
                hintText: 'Title your entry…',
                backgroundColor: _cardFill,
                textColor: _ink,
                hintColor: _inkLight,
                dividerColor: Color(0xFFD8D3CB),
                fontSize: 16,
                seed: 33,
              ),
              const SizedBox(height: 12),
              const HandDrawnTextField(
                hintText: 'Write your thoughts…',
                maxLines: 4,
                backgroundColor: _cardFill,
                textColor: _ink,
                hintColor: _inkLight,
                dividerColor: Color(0xFFD8D3CB),
                fontSize: 14,
                seed: 34,
              ),

              const SizedBox(height: 28),
              const HandDrawnDivider(
                color: _inkLight,
                indent: 32,
                endIndent: 32,
                seed: 65,
              ),
              const SizedBox(height: 28),

              const Text(
                'Notebook',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 16),
              HandDrawnContainer(
                backgroundColor: _cardFill,
                strokeColor: _ink,
                strokeWidth: 1.4,
                irregularity: 2.5,
                seed: 88,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HandDrawnNotebook(
                  lineHeight: _notebookLineHeight,
                  lineColor: const Color(0xFFB0AAA0),
                  irregularity: 2.5,
                  seed: 10,
                  child: Column(
                    children: [
                      for (final text in [
                        'First line on the grid',
                        'Second line sits neatly',
                        'Third line, same wobble',
                      ])
                        NotebookRow(
                          lineHeight: _notebookLineHeight,
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: _notebookFontSize,
                              height: _notebookLineHeight / _notebookFontSize,
                              color: _ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              const HandDrawnDivider(
                color: _inkLight,
                indent: 32,
                endIndent: 32,
                seed: 70,
              ),
              const SizedBox(height: 28),

              // ══ CHARTS ═══════════════════════════════════════════════
              const Text(
                'Charts',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'All three chart types — bar, line, scatter — share a common '
                'axis, grid, and label system. Line and scatter charts can opt '
                'into zero-crossing axes for mixed positive/negative ranges, '
                'and any chart can customize its grid via GridConfig.',
                style: TextStyle(fontSize: 14, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 20),

              _sectionHeading('Bar Chart'),
              const SizedBox(height: 12),
              HandDrawnBarChart(
                data: _sampleSimpleBarData(),
                height: 240,
                seed: 1,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Stacked Bar Chart'),
              const SizedBox(height: 4),
              const Text(
                'Each bar is composed of multiple stacked segments. '
                'Legend renders in a boxed band below.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              HandDrawnBarChart(
                data: _sampleBarData(),
                legendConfig: ChartLegendConfig.externalBottomBoxed,
                height: 280,
                seed: 10,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Grouped Bar Chart'),
              const SizedBox(height: 4),
              const Text(
                'Multiple bars share one category label, with a right-side '
                'boxed legend. Q4 combines grouped + stacked — each region '
                'adds a stacked bonus segment.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              HandDrawnBarChart(
                data: _sampleGroupedBarData(),
                legendConfig: ChartLegendConfig.externalRightBoxed,
                height: 280,
                seed: 11,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Bar Chart with Negative Values'),
              const SizedBox(height: 4),
              const Text(
                'Positive segments stack up from y = 0; negative segments '
                'stack down. Zero values still occupy a slot.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              HandDrawnBarChart(
                data: _sampleNegativeBarData(),
                height: 260,
                seed: 12,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Bar Chart with Rotated Labels'),
              const SizedBox(height: 4),
              const Text(
                'Long category names stay readable when rotated; the X tick '
                "band's reserved height adjusts automatically.",
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              HandDrawnBarChart(
                data: _sampleRotatedLabelsBarData(),
                xLabelConfig: ChartLabelConfig.diagonalLeft,
                height: 280,
                seed: 13,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Line Chart'),
              const SizedBox(height: 12),
              HandDrawnLineChart(
                data: _sampleSimpleLineData(),
                grid: GridConfig.none,
                height: 240,
                seed: 2,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Multi-Series Line Chart'),
              const SizedBox(height: 12),
              HandDrawnLineChart(
                data: _sampleLineData(),
                grid: GridConfig.standard,
                height: 260,
                seed: 20,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Negative Y Line Chart'),
              const SizedBox(height: 4),
              const Text(
                'Horizontal axis drawn at y = 0; line fill anchors '
                'to the zero baseline.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              HandDrawnLineChart(
                data: _sampleNegYLineData(),
                grid: GridConfig.horizontalOnly,
                height: 260,
                seed: 21,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Negative X Line Chart'),
              const SizedBox(height: 4),
              const Text(
                'Vertical axis drawn at x = 0.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              HandDrawnLineChart(
                data: _sampleNegXLineData(),
                grid: GridConfig.verticalOnly,
                height: 260,
                seed: 22,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Negative X and Y Line Chart'),
              const SizedBox(height: 4),
              const Text(
                'Four-quadrant view with sub-grid lines between each '
                'tick on both axes for finer value reading.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              HandDrawnLineChart(
                data: _sampleNegXYLineData(),
                grid: _subGrid,
                height: 280,
                seed: 23,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Function Chart'),
              const SizedBox(height: 4),
              const Text(
                'FunctionSeriesData samples a function across the numeric x-domain. '
                '`displayXs` controls where visible dots are drawn — the curve itself '
                'stays smooth between them, rendered as one coherent hand-drawn stroke.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              HandDrawnLineChart(
                data: _sampleParabolaData(),
                grid: GridConfig.standard,
                height: 260,
                seed: 24,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Multi-Function Chart'),
              const SizedBox(height: 4),
              const Text(
                'Multiple functions render on one chart with auto-generated legend '
                'entries, exactly like multi-series line charts.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              HandDrawnLineChart(
                data: _sampleFunctionComparisonData(),
                grid: GridConfig.standard,
                height: 280,
                seed: 25,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Discontinuous Function'),
              const SizedBox(height: 4),
              const Text(
                'Non-finite evaluations split the curve into independent runs. No '
                'false bridge is drawn across x = 0 — each side is drawn as its own '
                'hand-drawn stroke with its own fill.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              HandDrawnLineChart(
                data: _sampleDiscontinuousFunctionData(),
                grid: _subGrid,
                height: 280,
                seed: 26,
                clipToChartArea: true,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Line Chart with Boxed Bottom Legend'),
              const SizedBox(height: 4),
              const Text(
                'External boxed legend below the chart, wrapping for many '
                'series.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              HandDrawnLineChart(
                data: _sampleLineData(),
                legendConfig: ChartLegendConfig.externalBottomBoxed,
                grid: GridConfig.standard,
                height: 280,
                seed: 27,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Line Chart with Boxed Right Legend'),
              const SizedBox(height: 4),
              const Text(
                'Right-side boxed legend; the plot area shrinks horizontally '
                'to make room.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              HandDrawnLineChart(
                data: _sampleLineData(),
                legendConfig: ChartLegendConfig.externalRightBoxed,
                grid: GridConfig.standard,
                height: 260,
                seed: 28,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Standalone Legend Composition'),
              const SizedBox(height: 4),
              const Text(
                "Suppress the chart's legend, then place HandDrawnLegend "
                'wherever the layout calls for it.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  HandDrawnLegend(
                    entries: ChartLegendEntries.fromLineChartData(
                      _sampleLineData(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  HandDrawnLineChart(
                    data: _sampleLineData(),
                    legendConfig: ChartLegendConfig.hidden,
                    grid: GridConfig.standard,
                    height: 240,
                    seed: 29,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _sectionHeading('Scatter Plot'),
              const SizedBox(height: 12),
              HandDrawnScatterPlot(
                data: _sampleScatterData(),
                grid: _subGrid,
                height: 260,
                seed: 30,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Negative Y Scatter Plot'),
              const SizedBox(height: 12),
              HandDrawnScatterPlot(
                data: _sampleNegYScatterData(),
                grid: GridConfig.standard,
                height: 260,
                seed: 31,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Negative X Scatter Plot'),
              const SizedBox(height: 12),
              HandDrawnScatterPlot(
                data: _sampleNegXScatterData(),
                grid: GridConfig.none,
                height: 260,
                seed: 32,
              ),
              const SizedBox(height: 24),

              _sectionHeading('Negative X and Y Scatter Plot'),
              const SizedBox(height: 12),
              HandDrawnScatterPlot(
                data: _sampleNegXYScatterData(),
                grid: GridConfig.verticalOnly,
                height: 280,
                seed: 33,
              ),

              const SizedBox(height: 28),
              const HandDrawnDivider(
                color: _inkLight,
                indent: 32,
                endIndent: 32,
                seed: 80,
              ),
              const SizedBox(height: 28),

              // ══ TABLE ═══════════════════════════════════════════════
              const Text(
                'Table',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 16),
              const HandDrawnTable(
                title: 'Reading Log',
                columns: [
                  HandDrawnTableColumn(header: 'TITLE', flex: 3),
                  HandDrawnTableColumn(
                    header: 'PAGES',
                    width: 100,
                    alignment: Alignment.centerRight,
                  ),
                  HandDrawnTableColumn(
                    header: 'RATING',
                    width: 100,
                    alignment: Alignment.center,
                  ),
                ],
                rows: [
                  HandDrawnTableRow(
                    cells: ['Dune', '412', '★★★★★'],
                    highlight: true,
                  ),
                  HandDrawnTableRow(cells: ['Neuromancer', '271', '★★★★']),
                  HandDrawnTableRow(cells: ['Foundation', '244', '★★★★']),
                  HandDrawnTableRow(cells: ['Snow Crash', '480', '★★★']),
                ],
                rowDividers: TableDividerStyle(
                  seed: 60,
                  irregularity: 2,
                  uniform: false,
                ),
                columnDividers: TableDividerStyle(seed: 70, irregularity: 2),
              ),
              const SizedBox(height: 20),
              _sectionHeading('Resizable Columns'),
              const SizedBox(height: 12),
              const _ResizableTableDemo(),

              const SizedBox(height: 28),
              const HandDrawnDivider(
                color: _inkLight,
                indent: 32,
                endIndent: 32,
                seed: 85,
              ),
              const SizedBox(height: 28),

              // ══ INTERACTIVE CHARTS ═════════════════════════════════
              const Text(
                'Interactive Charts',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Every chart type exposes computeLayout() and hitTest(), so '
                'consumers can build their own tap, hover, and drag behaviors. '
                'Below, each chart above is wired to report what '
                'you tap.',
                style: TextStyle(fontSize: 14, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 20),

              _sectionHeading('Bar Chart — tap a bar'),
              const SizedBox(height: 4),
              _hitLabel(_hits['bar_simple']),
              const SizedBox(height: 8),
              _InteractiveBarChart(
                data: _sampleSimpleBarData(),
                seed: 1,
                unitLabel: 'k steps',
                onHit: (l) => _setHit('bar_simple', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Stacked Bar Chart — tap a segment'),
              const SizedBox(height: 4),
              _hitLabel(_hits['bar_stacked']),
              const SizedBox(height: 8),
              _InteractiveBarChart(
                data: _sampleBarData(),
                seed: 10,
                legendConfig: ChartLegendConfig.externalBottomBoxed,
                onHit: (l) => _setHit('bar_stacked', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Grouped Bar Chart — tap a grouped segment'),
              const SizedBox(height: 4),
              _hitLabel(_hits['bar_grouped']),
              const SizedBox(height: 8),
              _InteractiveBarChart(
                data: _sampleGroupedBarData(),
                seed: 11,
                unitLabel: 'k',
                legendConfig: ChartLegendConfig.externalRightBoxed,
                onHit: (l) => _setHit('bar_grouped', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Bar Chart with Negative Values — tap a segment'),
              const SizedBox(height: 4),
              _hitLabel(_hits['bar_negative']),
              const SizedBox(height: 8),
              _InteractiveBarChart(
                data: _sampleNegativeBarData(),
                seed: 12,
                unitLabel: 'k',
                onHit: (l) => _setHit('bar_negative', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Bar Chart with Rotated Labels — tap a bar'),
              const SizedBox(height: 4),
              _hitLabel(_hits['bar_rotated']),
              const SizedBox(height: 8),
              _InteractiveBarChart(
                data: _sampleRotatedLabelsBarData(),
                seed: 13,
                unitLabel: 'k users',
                xLabelConfig: ChartLabelConfig.diagonalLeft,
                onHit: (l) => _setHit('bar_rotated', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Line Chart — tap the line'),
              const SizedBox(height: 4),
              _hitLabel(_hits['line_simple']),
              const SizedBox(height: 8),
              _InteractiveLineChart(
                data: _sampleSimpleLineData(),
                seed: 2,
                grid: GridConfig.none,
                onHit: (l) => _setHit('line_simple', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Multi-Series Line Chart — tap a series'),
              const SizedBox(height: 4),
              _hitLabel(_hits['line_multi']),
              const SizedBox(height: 8),
              _InteractiveLineChart(
                data: _sampleLineData(),
                seed: 20,
                grid: GridConfig.standard,
                onHit: (l) => _setHit('line_multi', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Negative Y Line Chart — tap the line'),
              const SizedBox(height: 4),
              _hitLabel(_hits['line_negy']),
              const SizedBox(height: 8),
              _InteractiveLineChart(
                data: _sampleNegYLineData(),
                seed: 21,
                grid: GridConfig.horizontalOnly,
                onHit: (l) => _setHit('line_negy', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Negative X Line Chart — tap the line'),
              const SizedBox(height: 4),
              _hitLabel(_hits['line_negx']),
              const SizedBox(height: 8),
              _InteractiveLineChart(
                data: _sampleNegXLineData(),
                seed: 22,
                grid: GridConfig.verticalOnly,
                onHit: (l) => _setHit('line_negx', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Negative X and Y Line Chart — tap the line'),
              const SizedBox(height: 4),
              _hitLabel(_hits['line_negxy']),
              const SizedBox(height: 8),
              _InteractiveLineChart(
                data: _sampleNegXYLineData(),
                seed: 23,
                grid: _subGrid,
                onHit: (l) => _setHit('line_negxy', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading(
                'Function Chart — tap a dot or anywhere along the curve',
              ),
              const SizedBox(height: 4),
              const Text(
                'Point hits target only the sparse visible dots. Segment hits target '
                'anywhere along the sampled curve.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 4),
              _hitLabel(_hits['line_function']),
              const SizedBox(height: 8),
              _InteractiveLineChart(
                data: _sampleParabolaData(),
                seed: 24,
                grid: GridConfig.standard,
                onHit: (l) => _setHit('line_function', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Multi-Function Chart — tap a series'),
              const SizedBox(height: 4),
              const Text(
                'Same point-vs-segment hit semantics as the single-function chart, '
                'but hits also report which series was tapped.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 4),
              _hitLabel(_hits['line_function_multi']),
              const SizedBox(height: 8),
              _InteractiveLineChart(
                data: _sampleFunctionComparisonData(),
                seed: 25,
                grid: GridConfig.standard,
                onHit: (l) => _setHit('line_function_multi', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Discontinuous Function — tap either side'),
              const SizedBox(height: 4),
              const Text(
                "There's no segment spanning the discontinuity — taps near x = 0 "
                'fall through, while each side responds independently.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 4),
              _hitLabel(_hits['line_discontinuous']),
              const SizedBox(height: 8),
              _InteractiveLineChart(
                data: _sampleDiscontinuousFunctionData(),
                seed: 26,
                grid: _subGrid,
                onHit: (l) => _setHit('line_discontinuous', l),
                clipToChartArea: true,
              ),
              const SizedBox(height: 24),

              _sectionHeading(
                'Line Chart with Boxed Bottom Legend — tap a series',
              ),
              const SizedBox(height: 4),
              _hitLabel(_hits['line_legend_bottom']),
              const SizedBox(height: 8),
              _InteractiveLineChart(
                data: _sampleLineData(),
                seed: 27,
                grid: GridConfig.standard,
                legendConfig: ChartLegendConfig.externalBottomBoxed,
                onHit: (l) => _setHit('line_legend_bottom', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading(
                'Line Chart with Boxed Right Legend — tap a series',
              ),
              const SizedBox(height: 4),
              _hitLabel(_hits['line_legend_right']),
              const SizedBox(height: 8),
              _InteractiveLineChart(
                data: _sampleLineData(),
                seed: 28,
                grid: GridConfig.standard,
                legendConfig: ChartLegendConfig.externalRightBoxed,
                onHit: (l) => _setHit('line_legend_right', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Standalone Legend Composition — tap a series'),
              const SizedBox(height: 4),
              _hitLabel(_hits['line_legend_standalone']),
              const SizedBox(height: 8),
              Column(
                children: [
                  HandDrawnLegend(
                    entries: ChartLegendEntries.fromLineChartData(
                      _sampleLineData(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InteractiveLineChart(
                    data: _sampleLineData(),
                    seed: 29,
                    grid: GridConfig.standard,
                    legendConfig: ChartLegendConfig.hidden,
                    onHit: (l) => _setHit('line_legend_standalone', l),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _sectionHeading('Scatter Plot — tap a point'),
              const SizedBox(height: 4),
              _hitLabel(_hits['scatter_simple']),
              const SizedBox(height: 8),
              _InteractiveScatterPlot(
                data: _sampleScatterData(),
                seed: 30,
                grid: _subGrid,
                onHit: (l) => _setHit('scatter_simple', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Negative Y Scatter Plot — tap a point'),
              const SizedBox(height: 4),
              _hitLabel(_hits['scatter_negy']),
              const SizedBox(height: 8),
              _InteractiveScatterPlot(
                data: _sampleNegYScatterData(),
                seed: 31,
                grid: GridConfig.standard,
                onHit: (l) => _setHit('scatter_negy', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Negative X Scatter Plot — tap a point'),
              const SizedBox(height: 4),
              _hitLabel(_hits['scatter_negx']),
              const SizedBox(height: 8),
              _InteractiveScatterPlot(
                data: _sampleNegXScatterData(),
                seed: 32,
                grid: GridConfig.none,
                onHit: (l) => _setHit('scatter_negx', l),
              ),
              const SizedBox(height: 24),

              _sectionHeading('Negative X and Y Scatter Plot — tap a point'),
              const SizedBox(height: 4),
              _hitLabel(_hits['scatter_negxy']),
              const SizedBox(height: 8),
              _InteractiveScatterPlot(
                data: _sampleNegXYScatterData(),
                seed: 33,
                grid: GridConfig.verticalOnly,
                onHit: (l) => _setHit('scatter_negxy', l),
              ),

              const SizedBox(height: 28),

              const HandDrawnContainer(
                backgroundColor: Color(0xFFF0F6F4),
                strokeColor: _accent,
                strokeWidth: 2.0,
                irregularity: 4.5,
                seed: 5,
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use a unique seed for each adjacent element to avoid '
                      'identical wobble patterns lining up. Irregularity '
                      'around 2.0–4.0 works for borders; 0.5–1.5 for '
                      'dividers and grid lines.',
                      style: TextStyle(fontSize: 14, height: 1.55, color: _ink),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              const Text(
                'Custom Paths',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: CustomPaint(
                  painter: HandDrawnLinePainter(
                    color: _ink,
                    strokeWidth: 3.0,
                    irregularity: 2.0,
                    seed: 100,
                    segments: 100,
                    buildPath: (size, h) {
                      final offsets = h.smoothedOffsets();
                      final dx = size.width / h.segments;
                      final path = Path()..moveTo(0, size.height);
                      for (int i = 1; i <= h.segments; i++) {
                        final t = i / h.segments;
                        final y = size.height * (1 - t) + offsets[i];
                        path.lineTo(dx * i, y);
                      }
                      return path;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ══ SAMPLE DATA ════════════════════════════════════════════════════════════

BarChartData _sampleSimpleBarData() {
  const blue = Color(0xFF6B9BD2);
  return const BarChartData(
    title: 'Daily Steps',
    yAxisLabel: 'Steps (k)',
    maxY: 12,
    bars: [
      BarGroup(
        label: 'Mon',
        segments: [BarSegment(category: 'Steps', value: 6.2, color: blue)],
      ),
      BarGroup(
        label: 'Tue',
        segments: [BarSegment(category: 'Steps', value: 8.5, color: blue)],
      ),
      BarGroup(
        label: 'Wed',
        segments: [BarSegment(category: 'Steps', value: 4.8, color: blue)],
      ),
      BarGroup(
        label: 'Thu',
        segments: [BarSegment(category: 'Steps', value: 9.3, color: blue)],
      ),
      BarGroup(
        label: 'Fri',
        segments: [BarSegment(category: 'Steps', value: 7.1, color: blue)],
      ),
    ],
    legend: [LegendEntry(label: 'Steps', color: blue)],
  );
}

BarChartData _sampleBarData() {
  return const BarChartData(
    title: 'Weekly Activity',
    yAxisLabel: 'Minutes',
    maxY: 120,
    bars: [
      BarGroup(
        label: 'Mon',
        segments: [
          BarSegment(category: 'Exercise', value: 30, color: Color(0xFF6BAF7A)),
          BarSegment(category: 'Reading', value: 25, color: Color(0xFF6B9BD2)),
          BarSegment(category: 'Creative', value: 15, color: Color(0xFFE8943A)),
        ],
      ),
      BarGroup(
        label: 'Tue',
        segments: [
          BarSegment(category: 'Exercise', value: 50, color: Color(0xFF6BAF7A)),
          BarSegment(category: 'Reading', value: 20, color: Color(0xFF6B9BD2)),
          BarSegment(category: 'Creative', value: 25, color: Color(0xFFE8943A)),
        ],
      ),
      BarGroup(
        label: 'Wed',
        segments: [
          BarSegment(category: 'Exercise', value: 25, color: Color(0xFF6BAF7A)),
          BarSegment(category: 'Reading', value: 40, color: Color(0xFF6B9BD2)),
          BarSegment(category: 'Creative', value: 20, color: Color(0xFFE8943A)),
        ],
      ),
      BarGroup(
        label: 'Thu',
        segments: [
          BarSegment(category: 'Exercise', value: 40, color: Color(0xFF6BAF7A)),
          BarSegment(category: 'Reading', value: 15, color: Color(0xFF6B9BD2)),
          BarSegment(category: 'Creative', value: 30, color: Color(0xFFE8943A)),
        ],
      ),
      BarGroup(
        label: 'Fri',
        segments: [
          BarSegment(category: 'Exercise', value: 45, color: Color(0xFF6BAF7A)),
          BarSegment(category: 'Reading', value: 30, color: Color(0xFF6B9BD2)),
          BarSegment(category: 'Creative', value: 10, color: Color(0xFFE8943A)),
        ],
      ),
    ],
    legend: [
      LegendEntry(label: 'Exercise', color: Color(0xFF6BAF7A)),
      LegendEntry(label: 'Reading', color: Color(0xFF6B9BD2)),
      LegendEntry(label: 'Creative', color: Color(0xFFE8943A)),
    ],
  );
}

BarChartData _sampleGroupedBarData() {
  const blue = Color(0xFF6B9BD2);
  const orange = Color(0xFFE8943A);
  const purple = Color(0xFF7B68C4);
  const green = Color(0xFF6BAF7A);
  return const BarChartData(
    title: 'Quarterly Revenue by Region',
    yAxisLabel: 'USD (k)',
    maxY: 100,
    bars: [],
    categories: [
      BarCategory(
        label: 'Q1',
        bars: [
          BarGroup(
            label: 'North',
            segments: [BarSegment(category: 'North', value: 42, color: blue)],
          ),
          BarGroup(
            label: 'South',
            segments: [BarSegment(category: 'South', value: 35, color: orange)],
          ),
          BarGroup(
            label: 'West',
            segments: [BarSegment(category: 'West', value: 28, color: purple)],
          ),
        ],
      ),
      BarCategory(
        label: 'Q2',
        bars: [
          BarGroup(
            label: 'North',
            segments: [BarSegment(category: 'North', value: 55, color: blue)],
          ),
          BarGroup(
            label: 'South',
            segments: [BarSegment(category: 'South', value: 48, color: orange)],
          ),
          BarGroup(
            label: 'West',
            segments: [BarSegment(category: 'West', value: 40, color: purple)],
          ),
        ],
      ),
      BarCategory(
        label: 'Q3',
        bars: [
          BarGroup(
            label: 'North',
            segments: [BarSegment(category: 'North', value: 38, color: blue)],
          ),
          BarGroup(
            label: 'South',
            segments: [BarSegment(category: 'South', value: 62, color: orange)],
          ),
          BarGroup(
            label: 'West',
            segments: [BarSegment(category: 'West', value: 45, color: purple)],
          ),
        ],
      ),
      BarCategory(
        label: 'Q4',
        bars: [
          BarGroup(
            label: 'North',
            segments: [
              BarSegment(category: 'North', value: 50, color: blue),
              BarSegment(category: 'Bonus', value: 10, color: green),
            ],
          ),
          BarGroup(
            label: 'South',
            segments: [
              BarSegment(category: 'South', value: 70, color: orange),
              BarSegment(category: 'Bonus', value: 12, color: green),
            ],
          ),
          BarGroup(
            label: 'West',
            segments: [
              BarSegment(category: 'West', value: 55, color: purple),
              BarSegment(category: 'Bonus', value: 8, color: green),
            ],
          ),
        ],
      ),
    ],
    legend: [
      LegendEntry(label: 'North', color: blue),
      LegendEntry(label: 'South', color: orange),
      LegendEntry(label: 'West', color: purple),
      LegendEntry(label: 'Bonus', color: green),
    ],
  );
}

BarChartData _sampleNegativeBarData() {
  const green = Color(0xFF6BAF7A);
  const red = Color(0xFFD46B6B);
  return const BarChartData(
    title: 'Quarterly P/L',
    yAxisLabel: 'USD (k)',
    minY: -30,
    maxY: 50,
    axisDisplay: AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
    bars: [
      // Mixed-sign stack: gains dominate.
      BarGroup(
        label: 'Q1',
        segments: [
          BarSegment(category: 'Gain', value: 30, color: green),
          BarSegment(category: 'Loss', value: -5, color: red),
        ],
      ),
      // All-negative bar.
      BarGroup(
        label: 'Q2',
        segments: [BarSegment(category: 'Loss', value: -18, color: red)],
      ),
      // Zero bar — occupies its slot, renders nothing.
      BarGroup(
        label: 'Q3',
        segments: [BarSegment(category: 'Gain', value: 0, color: green)],
      ),
      // All-positive bar.
      BarGroup(
        label: 'Q4',
        segments: [BarSegment(category: 'Gain', value: 38, color: green)],
      ),
    ],
    legend: [
      LegendEntry(label: 'Gain', color: green),
      LegendEntry(label: 'Loss', color: red),
    ],
  );
}

BarChartData _sampleRotatedLabelsBarData() {
  const blue = Color(0xFF6B9BD2);
  return const BarChartData(
    title: 'Monthly Active Users',
    yAxisLabel: 'Users (k)',
    maxY: 28,
    bars: [
      BarGroup(
        label: 'October 2024',
        segments: [BarSegment(category: 'Users', value: 13.1, color: blue)],
      ),
      BarGroup(
        label: 'November 2024',
        segments: [BarSegment(category: 'Users', value: 14.8, color: blue)],
      ),
      BarGroup(
        label: 'December 2024',
        segments: [BarSegment(category: 'Users', value: 16.2, color: blue)],
      ),
      BarGroup(
        label: 'January 2025',
        segments: [BarSegment(category: 'Users', value: 18.5, color: blue)],
      ),
      BarGroup(
        label: 'February 2025',
        segments: [BarSegment(category: 'Users', value: 19.7, color: blue)],
      ),
      BarGroup(
        label: 'March 2025',
        segments: [BarSegment(category: 'Users', value: 21.3, color: blue)],
      ),
    ],
    legend: [LegendEntry(label: 'Users', color: blue)],
  );
}

LineChartData _sampleSimpleLineData() {
  return const LineChartData(
    title: 'Weekly Runs',
    xAxisLabel: 'Day',
    yAxisLabel: 'Miles',
    minX: 0,
    maxX: 6,
    minY: 0,
    maxY: 8,
    xLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    series: [
      LineSeriesData(
        name: 'Miles',
        color: Color(0xFF4A7C6F),
        points: [
          LinePoint(x: 0, y: 3.1),
          LinePoint(x: 1, y: 4.5),
          LinePoint(x: 2, y: 2.8),
          LinePoint(x: 3, y: 5.2),
          LinePoint(x: 4, y: 3.9),
          LinePoint(x: 5, y: 6.8),
          LinePoint(x: 6, y: 4.1),
        ],
      ),
    ],
  );
}

LineChartData _sampleLineData() {
  return const LineChartData(
    title: 'Mood Tracker',
    xAxisLabel: 'Day',
    yAxisLabel: 'Score',
    minX: 0,
    maxX: 6,
    minY: 0,
    maxY: 10,
    xLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    series: [
      LineSeriesData(
        name: 'Energy',
        color: Color(0xFFE8943A),
        points: [
          LinePoint(x: 0, y: 6),
          LinePoint(x: 1, y: 7),
          LinePoint(x: 2, y: 5),
          LinePoint(x: 3, y: 8),
          LinePoint(x: 4, y: 7),
          LinePoint(x: 5, y: 9),
          LinePoint(x: 6, y: 8),
        ],
      ),
      LineSeriesData(
        name: 'Focus',
        color: Color(0xFF7B68C4),
        points: [
          LinePoint(x: 0, y: 5),
          LinePoint(x: 1, y: 6),
          LinePoint(x: 2, y: 4),
          LinePoint(x: 3, y: 7),
          LinePoint(x: 4, y: 8),
          LinePoint(x: 5, y: 6),
          LinePoint(x: 6, y: 7),
        ],
      ),
    ],
  );
}

LineChartData _sampleNegYLineData() {
  return const LineChartData(
    title: 'Monthly Profit / Loss',
    xAxisLabel: 'Month',
    yAxisLabel: 'USD (k)',
    minX: 0,
    maxX: 7,
    minY: -40,
    maxY: 60,
    xLabels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'],
    axisDisplay: AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
    series: [
      LineSeriesData(
        name: 'Net',
        color: Color(0xFF7B68C4),
        showFill: false,
        points: [
          LinePoint(x: 0, y: 25),
          LinePoint(x: 1, y: -15),
          LinePoint(x: 2, y: -30),
          LinePoint(x: 3, y: 10),
          LinePoint(x: 4, y: 35),
          LinePoint(x: 5, y: 50),
          LinePoint(x: 6, y: 20),
          LinePoint(x: 7, y: -5),
        ],
      ),
    ],
  );
}

LineChartData _sampleNegXLineData() {
  return const LineChartData(
    title: 'Population Density vs Distance from City Center',
    xAxisLabel: 'Distance (km)',
    yAxisLabel: 'People / km²',
    minX: -20,
    maxX: 20,
    minY: 0,
    maxY: 5000,
    axisDisplay: AxisDisplay(vertical: AxisDisplayMode.zeroCrossing),
    series: [
      LineSeriesData(
        name: 'East-West Transect',
        color: Color(0xFF4A7C6F),
        points: [
          LinePoint(x: -20, y: 300),
          LinePoint(x: -15, y: 900),
          LinePoint(x: -10, y: 2200),
          LinePoint(x: -5, y: 4200),
          LinePoint(x: 0, y: 4800),
          LinePoint(x: 5, y: 4100),
          LinePoint(x: 10, y: 2100),
          LinePoint(x: 15, y: 800),
          LinePoint(x: 20, y: 250),
        ],
      ),
    ],
  );
}

LineChartData _sampleNegXYLineData() {
  return const LineChartData(
    title: 'Pendulum Position Over Time',
    xAxisLabel: 'X displacement (cm)',
    yAxisLabel: 'Y displacement (cm)',
    minX: -10,
    maxX: 10,
    minY: -10,
    maxY: 10,
    axisDisplay: AxisDisplay(
      horizontal: AxisDisplayMode.zeroCrossing,
      vertical: AxisDisplayMode.zeroCrossing,
    ),
    series: [
      LineSeriesData(
        name: 'Path',
        color: Color(0xFFE8943A),
        showFill: false,
        points: [
          LinePoint(x: -8, y: -2),
          LinePoint(x: -6, y: 2),
          LinePoint(x: -3, y: 6),
          LinePoint(x: 0, y: 8),
          LinePoint(x: 3, y: 6),
          LinePoint(x: 6, y: 2),
          LinePoint(x: 8, y: -2),
          LinePoint(x: 6, y: -6),
          LinePoint(x: 3, y: -8),
          LinePoint(x: 0, y: -7),
          LinePoint(x: -3, y: -8),
          LinePoint(x: -6, y: -6),
        ],
      ),
    ],
  );
}

// Top-level function definitions. Using top-level functions rather than
// inline closures keeps FunctionSeriesData equality stable across widget
// rebuilds, so LineChartData == / hashCode behave as expected.
double _parabola(double x) => x * x;
double _cubic(double x) => 0.1 * x * x * x - x;
double _reciprocal(double x) => 1 / x;

LineChartData _sampleParabolaData() {
  return const LineChartData(
    title: 'Parabola: f(x) = x²',
    xAxisLabel: 'x',
    yAxisLabel: 'f(x)',
    minX: -5,
    maxX: 5,
    minY: 0,
    maxY: 25,
    axisDisplay: AxisDisplay(vertical: AxisDisplayMode.zeroCrossing),
    series: [],
    functionSeries: [
      FunctionSeriesData(
        name: 'f(x) = x²',
        color: Color(0xFF6B9BD2),
        function: _parabola,
        displayXs: [-4, -2, 0, 2, 4],
      ),
    ],
  );
}

LineChartData _sampleFunctionComparisonData() {
  return const LineChartData(
    title: 'Two Functions on One Chart',
    xAxisLabel: 'x',
    yAxisLabel: 'f(x)',
    minX: -5,
    maxX: 5,
    minY: -10,
    maxY: 25,
    axisDisplay: AxisDisplay(
      horizontal: AxisDisplayMode.zeroCrossing,
      vertical: AxisDisplayMode.zeroCrossing,
    ),
    series: [],
    functionSeries: [
      FunctionSeriesData(
        name: 'f(x) = x²',
        color: Color(0xFF6B9BD2),
        function: _parabola,
        displayXs: [-4, -2, 0, 2, 4],
      ),
      FunctionSeriesData(
        name: 'g(x) = 0.1x³ − x',
        color: Color(0xFFE8943A),
        function: _cubic,
        displayXs: [-4, -2, 0, 2, 4],
      ),
    ],
  );
}

LineChartData _sampleDiscontinuousFunctionData() {
  return const LineChartData(
    title: 'Discontinuity: f(x) = 1/x',
    xAxisLabel: 'x',
    yAxisLabel: 'f(x)',
    minX: -4,
    maxX: 4,
    minY: -5,
    maxY: 5,
    axisDisplay: AxisDisplay(
      horizontal: AxisDisplayMode.zeroCrossing,
      vertical: AxisDisplayMode.zeroCrossing,
    ),
    series: [],
    functionSeries: [
      FunctionSeriesData(
        name: 'f(x) = 1/x',
        color: Color(0xFF7B68C4),
        function: _reciprocal,
        displayXs: [-3, -2, -1, 1, 2, 3],
      ),
    ],
  );
}

ScatterPlotData _sampleScatterData() {
  return const ScatterPlotData(
    title: 'Sleep vs Productivity',
    xAxisLabel: 'Hours of Sleep',
    yAxisLabel: 'Productivity Score',
    minX: 4,
    maxX: 10,
    minY: 0,
    maxY: 100,
    points: [
      ScatterPoint(x: 5.0, y: 35),
      ScatterPoint(x: 5.5, y: 42),
      ScatterPoint(x: 6.0, y: 55),
      ScatterPoint(x: 6.5, y: 50),
      ScatterPoint(x: 7.0, y: 68),
      ScatterPoint(x: 7.0, y: 72),
      ScatterPoint(x: 7.5, y: 78, size: 7),
      ScatterPoint(x: 8.0, y: 82, size: 7),
      ScatterPoint(x: 8.0, y: 75),
      ScatterPoint(x: 8.5, y: 88, size: 8),
      ScatterPoint(x: 9.0, y: 85),
      ScatterPoint(x: 9.5, y: 80),
    ],
  );
}

ScatterPlotData _sampleNegYScatterData() {
  return const ScatterPlotData(
    title: 'Daily Temperature Variance',
    xAxisLabel: 'Day of month',
    yAxisLabel: 'Δ°C from average',
    minX: 1,
    maxX: 14,
    minY: -8,
    maxY: 8,
    axisDisplay: AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
    points: [
      ScatterPoint(x: 1, y: -3),
      ScatterPoint(x: 2, y: -5),
      ScatterPoint(x: 3, y: 2),
      ScatterPoint(x: 4, y: 4),
      ScatterPoint(x: 5, y: -1),
      ScatterPoint(x: 6, y: 6),
      ScatterPoint(x: 7, y: 5),
      ScatterPoint(x: 8, y: -2),
      ScatterPoint(x: 9, y: -6),
      ScatterPoint(x: 10, y: 1),
      ScatterPoint(x: 11, y: 3),
      ScatterPoint(x: 12, y: 7),
      ScatterPoint(x: 13, y: -4),
      ScatterPoint(x: 14, y: -7),
    ],
  );
}

ScatterPlotData _sampleNegXScatterData() {
  return const ScatterPlotData(
    title: 'Wind Speed vs East-West Position',
    xAxisLabel: 'Position (km, + = east)',
    yAxisLabel: 'Wind speed (km/h)',
    minX: -30,
    maxX: 30,
    minY: 0,
    maxY: 50,
    axisDisplay: AxisDisplay(vertical: AxisDisplayMode.zeroCrossing),
    points: [
      ScatterPoint(x: -28, y: 12),
      ScatterPoint(x: -22, y: 18),
      ScatterPoint(x: -15, y: 25),
      ScatterPoint(x: -8, y: 32),
      ScatterPoint(x: -3, y: 38),
      ScatterPoint(x: 0, y: 42, size: 7),
      ScatterPoint(x: 4, y: 40),
      ScatterPoint(x: 10, y: 35),
      ScatterPoint(x: 18, y: 28),
      ScatterPoint(x: 25, y: 20),
      ScatterPoint(x: 29, y: 14),
    ],
  );
}

ScatterPlotData _sampleNegXYScatterData() {
  return const ScatterPlotData(
    title: 'Sales vs Forecast Variance',
    xAxisLabel: 'Forecast Δ (units)',
    yAxisLabel: 'Sales Δ (units)',
    minX: -50,
    maxX: 50,
    minY: -40,
    maxY: 40,
    axisDisplay: AxisDisplay(
      horizontal: AxisDisplayMode.zeroCrossing,
      vertical: AxisDisplayMode.zeroCrossing,
    ),
    points: [
      ScatterPoint(x: -35, y: -25),
      ScatterPoint(x: -20, y: -10),
      ScatterPoint(x: -15, y: 8),
      ScatterPoint(x: -5, y: -3),
      ScatterPoint(x: 5, y: 12),
      ScatterPoint(x: 18, y: 22, size: 7),
      ScatterPoint(x: 25, y: -8),
      ScatterPoint(x: 30, y: 18),
      ScatterPoint(x: 40, y: 30, size: 8),
      ScatterPoint(x: -30, y: 15),
      ScatterPoint(x: -40, y: -32),
      ScatterPoint(x: 10, y: -5),
    ],
  );
}

// ══ INTERACTIVE CHART WIDGETS ══════════════════════════════════════════════

class _InteractiveBarChart extends StatelessWidget {
  const _InteractiveBarChart({
    required this.data,
    required this.onHit,
    this.seed = 10,
    this.unitLabel = 'min',
    this.xLabelConfig = ChartLabelConfig.horizontal,
    this.legendConfig = ChartLegendConfig.inlineBottom,
  });

  final BarChartData data;
  final ValueChanged<String?> onHit;
  final int seed;
  final String unitLabel;
  final ChartLabelConfig xLabelConfig;
  final ChartLegendConfig legendConfig;

  @override
  Widget build(BuildContext context) {
    final painter = HandDrawnBarChartPainter(
      data: data,
      seed: seed,
      xLabelConfig: xLabelConfig,
      legendConfig: legendConfig,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 240);
        final layout = painter.computeLayout(size);
        return GestureDetector(
          onTapDown: (details) {
            final hit = layout.hitTest(details.localPosition);
            if (hit != null) {
              final s = hit.segment;
              final header = data.hasGroupedBars
                  ? '${s.barLabel} / ${s.innerBarLabel}'
                  : s.barLabel;
              final fmt = s.value.truncateToDouble() == s.value ? 0 : 1;
              onHit(
                '$header — ${s.category}: '
                '${s.value.toStringAsFixed(fmt)} $unitLabel',
              );
            } else {
              onHit(null);
            }
          },
          child: CustomPaint(size: size, painter: painter),
        );
      },
    );
  }
}

class _InteractiveLineChart extends StatelessWidget {
  const _InteractiveLineChart({
    required this.data,
    required this.onHit,
    this.seed = 20,
    this.grid = GridConfig.standard,
    this.clipToChartArea = true,
    this.legendConfig = ChartLegendConfig.inlineBottom,
  });

  final LineChartData data;
  final ValueChanged<String?> onHit;
  final int seed;
  final GridConfig grid;
  final bool clipToChartArea;
  final ChartLegendConfig legendConfig;

  @override
  Widget build(BuildContext context) {
    final painter = HandDrawnLineChartPainter(
      data: data,
      seed: seed,
      grid: grid,
      clipToChartArea: clipToChartArea,
      legendConfig: legendConfig,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 240);
        final layout = painter.computeLayout(size);
        return GestureDetector(
          onTapDown: (details) {
            final hit = layout.hitTest(details.localPosition);
            if (hit != null) {
              final label = switch (hit) {
                LinePointHit(
                  :final seriesName,
                  :final pointIndex,
                  :final point,
                ) =>
                  '$seriesName point $pointIndex: '
                      '(${point.x.toStringAsFixed(1)}, '
                      '${point.y.toStringAsFixed(1)})',
                LineSegmentHit(
                  :final seriesName,
                  :final interpolatedX,
                  :final interpolatedY,
                ) =>
                  '$seriesName segment at '
                      'x=${interpolatedX.toStringAsFixed(1)}, '
                      'y=${interpolatedY.toStringAsFixed(1)}',
              };
              onHit(label);
            } else {
              onHit(null);
            }
          },
          child: CustomPaint(size: size, painter: painter),
        );
      },
    );
  }
}

class _InteractiveScatterPlot extends StatelessWidget {
  const _InteractiveScatterPlot({
    required this.data,
    required this.onHit,
    this.seed = 30,
    this.grid = GridConfig.standard,
  });

  final ScatterPlotData data;
  final ValueChanged<String?> onHit;
  final int seed;
  final GridConfig grid;

  @override
  Widget build(BuildContext context) {
    final painter = HandDrawnScatterPlotPainter(
      data: data,
      seed: seed,
      grid: grid,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 240);
        final layout = painter.computeLayout(size);
        return GestureDetector(
          onTapDown: (details) {
            final hit = layout.hitTest(details.localPosition);
            if (hit != null) {
              final p = hit.point.rawPoint;
              onHit(
                'Point ${hit.point.pointIndex}: '
                '(${p.x.toStringAsFixed(1)}, '
                '${p.y.toStringAsFixed(1)})',
              );
            } else {
              onHit(null);
            }
          },
          child: CustomPaint(size: size, painter: painter),
        );
      },
    );
  }
}

// ══ RESIZABLE TABLE DEMO ═══════════════════════════════════════════════════

class _ResizableTableDemo extends StatefulWidget {
  const _ResizableTableDemo();

  @override
  State<_ResizableTableDemo> createState() => _ResizableTableDemoState();
}

class _ResizableTableDemoState extends State<_ResizableTableDemo> {
  static const _minColWidth = 40.0;
  static const _tablePadding = 12.0;
  static const _handleWidth = 16.0;
  static const _initialRatios = [3.0, 1.0, 1.0];

  List<double>? _widths;

  final _rows = const [
    HandDrawnTableRow(cells: ['Dune', '412', '★★★★★'], highlight: true),
    HandDrawnTableRow(cells: ['Neuromancer', '271', '★★★★']),
    HandDrawnTableRow(cells: ['Foundation', '244', '★★★★']),
  ];

  List<double> _initWidths(double contentWidth) {
    final totalRatio = _initialRatios.fold(0.0, (s, r) => s + r);
    return [for (final r in _initialRatios) contentWidth * r / totalRatio];
  }

  void _onDrag(int boundary, double delta) {
    setState(() {
      final maxGrow = _widths![boundary + 1] - _minColWidth;
      final maxShrink = _widths![boundary] - _minColWidth;
      final clamped = delta.clamp(-maxShrink, maxGrow);
      _widths![boundary] += clamped;
      _widths![boundary + 1] -= clamped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - _tablePadding * 2;
        _widths ??= _initWidths(contentWidth);
        return Stack(
          children: [
            HandDrawnTable(
              columns: [
                HandDrawnTableColumn(header: 'TITLE', width: _widths![0]),
                HandDrawnTableColumn(
                  header: 'PAGES',
                  width: _widths![1],
                  alignment: Alignment.centerRight,
                ),
                HandDrawnTableColumn(
                  header: 'RATING',
                  width: _widths![2],
                  alignment: Alignment.center,
                ),
              ],
              rows: _rows,
              rowDividers: const TableDividerStyle(irregularity: 3),
              columnDividers: const TableDividerStyle(irregularity: 3),
            ),
            for (int i = 0; i < _widths!.length - 1; i++)
              Positioned(
                left:
                    _tablePadding +
                    _widths!.take(i + 1).fold(0.0, (s, w) => s + w) -
                    _handleWidth / 2,
                top: 0,
                bottom: 0,
                width: _handleWidth,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) => _onDrag(i, d.delta.dx),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ══ UI HELPERS ═════════════════════════════════════════════════════════════

Widget _sectionHeading(String text) => Text(
  text,
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: _ink,
  ),
);

Widget _hitLabel(String? label) => Text(
  label ?? 'Tap a data element…',
  style: TextStyle(
    fontSize: 13,
    color: label != null ? _accent : _inkLight,
    fontStyle: label != null ? FontStyle.normal : FontStyle.italic,
  ),
);

// ══ STATUS SQUARE DEMO HELPERS ═════════════════════════════════════════════

enum _TaskStatus { pending, completed, skipped }

class _TaskItem {
  const _TaskItem(this.label, {this.status = _TaskStatus.pending});

  final String label;
  final _TaskStatus status;

  _TaskItem cycled() {
    final next = switch (status) {
      _TaskStatus.pending => _TaskStatus.completed,
      _TaskStatus.completed => _TaskStatus.skipped,
      _TaskStatus.skipped => _TaskStatus.pending,
    };
    return _TaskItem(label, status: next);
  }

  Color get color => switch (status) {
    _TaskStatus.pending => _ink,
    _TaskStatus.completed => _accent,
    _TaskStatus.skipped => _inkLight,
  };

  bool get isFilled => status != _TaskStatus.pending;

  StatusIndicator get indicator => switch (status) {
    _TaskStatus.pending => StatusIndicator.none,
    _TaskStatus.completed => StatusIndicator.check,
    _TaskStatus.skipped => StatusIndicator.dash,
  };
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.seed, required this.onTap});

  final _TaskItem task;
  final int seed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NotebookRow(
      lineHeight: _notebookLineHeight,
      child: Row(
        children: [
          HandDrawnStatusSquare(
            color: task.color,
            isFilled: task.isFilled,
            indicator: task.indicator,
            size: 18,
            seed: seed,
            onTap: onTap,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.label,
              style: TextStyle(
                fontSize: _notebookFontSize,
                height: _notebookLineHeight / _notebookFontSize,
                color: _ink,
                decoration: task.isFilled ? TextDecoration.lineThrough : null,
                decorationColor: _inkLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalItem extends StatelessWidget {
  const _GoalItem({required this.seed, required this.text});

  final int seed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return HandDrawnContainer(
      backgroundColor: _cardFill,
      strokeColor: _ink,
      strokeWidth: 1.4,
      irregularity: 2.2,
      seed: seed,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 15, color: _ink)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5, color: _ink),
            ),
          ),
        ],
      ),
    );
  }
}
