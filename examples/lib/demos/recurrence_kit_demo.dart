import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recurrence_kit/recurrence_kit.dart';

/// Top-level demo widget for the recurrence_kit package.
///
/// Adapted from the package's example app. Loaded by the URL router in
/// `main.dart` when `?demo=recurrence-kit` is present in the iframe URL.
class RecurrenceKitDemo extends StatelessWidget {
  const RecurrenceKitDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'recurrence_kit example',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF5B6ABF),
        useMaterial3: true,
      ),
      home: const ExampleScreen(),
    );
  }
}

// ── Theme configurations ─────────────────────────────────────────────────────

const _lightTheme = RecurrencePickerTheme();

const _darkTheme = RecurrencePickerTheme(
  textColor: Color(0xFFE0E0E0),
  secondaryTextColor: Color(0xFF9E9E9E),
  accentColor: Color(0xFF81C784),
  borderColor: Color(0xFF616161),
);

// ── Main screen ──────────────────────────────────────────────────────────────

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  final DateTime _startDate = DateTime.now();
  bool _useDarkTheme = false;

  late RecurrenceRule _rule = RecurrenceRule(
    type: RecurrenceType.weekly,
    daysOfWeek: [_startDate.weekday],
  );

  // Cached computed values — updated in _updateRule(), not in build().
  List<DateTime> _upcoming = [];
  String _jsonString = '';

  RecurrencePickerTheme get _pickerTheme =>
      _useDarkTheme ? _darkTheme : _lightTheme;

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  void _updateRule(RecurrenceRule updated) {
    setState(() {
      _rule = updated;
      _recompute();
    });
  }

  /// Recomputes derived display values from the current [_rule].
  ///
  /// When endType is afterCount, resolves the concrete endDate via
  /// [RecurrenceEngine.computeEndDateFromCount] before querying
  /// occurrences — this is the workflow described in the
  /// [RecurrencePicker] docs.
  void _recompute() {
    final effectiveRule =
        _rule.endType == RecurrenceEndType.afterCount &&
            _rule.endAfterCount != null
        ? _rule.copyWith(
            endDate: RecurrenceEngine.computeEndDateFromCount(
              _rule,
              _startDate,
              _rule.endAfterCount!,
            ),
          )
        : _rule;

    // afterDate is exclusive, so pass the day before startDate to
    // include the first occurrence (which may be startDate itself).
    _upcoming = RecurrenceEngine.nextOccurrences(
      effectiveRule,
      _startDate,
      _startDate.subtract(const Duration(days: 1)),
      count: 5,
    );

    _jsonString = const JsonEncoder.withIndent('  ').convert(_rule.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Picker section ──
          _SectionCard(
            title: 'RecurrencePicker',
            backgroundColor: _useDarkTheme ? const Color(0xFF2C2C2C) : null,
            child: RecurrencePicker(
              rule: _rule,
              onChanged: _updateRule,
              startDate: _startDate,
              theme: _pickerTheme,
            ),
          ),
          const SizedBox(height: 16),

          // ── Display text section ──
          _SectionCard(
            title: 'RecurrenceRule.displayText',
            child: Text(
              _rule.displayText,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),

          // ── Next occurrences section ──
          _SectionCard(
            title: 'Next occurrences',
            subtitle:
                'Up to 5 shown. '
                'If today matches the rule, it appears as the first entry.',
            child: _upcoming.isEmpty
                ? Text(
                    'No upcoming occurrences found.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < _upcoming.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${i + 1}. ${DateFormat.yMMMEd().format(_upcoming[i])}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // ── JSON section ──
          _SectionCard(
            title: 'RecurrenceRule.toJson()',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _jsonString,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Reusable card wrapper ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.backgroundColor,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}