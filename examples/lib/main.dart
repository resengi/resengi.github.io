// Router entry point for the Resengi examples Flutter app.
//
// This app is built once (`flutter build web`) and deployed at
// `/flutter-examples/`. Which demo renders is controlled by the `demo`
// query parameter in the URL:
//
//   /flutter-examples/?demo=hand-drawn-toolkit  → HandDrawnToolkitDemo
//   /flutter-examples/?demo=page-turn-animation → PageTurnDemo
//   /flutter-examples/?demo=recurrence-kit      → RecurrenceKitDemo
//   /flutter-examples/?demo=flip-calendar       → FlipCalendarDemo
//
// Each iframe on opensource.html points at one of these URLs.
//
// Visiting `/flutter-examples/` without a slug (or with an unrecognized
// slug) shows a simple landing page with links to each demo.
//
// IMPORTANT: the slug keys below are the single source of truth for which
// demos exist. They must stay in sync with the slugs referenced on
// opensource.html. Keep both sides updated together.

import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'demos/flip_calendar_demo.dart';
import 'demos/hand_drawn_toolkit_demo.dart';
import 'demos/page_turn_animation_demo.dart';
import 'demos/recurrence_kit_demo.dart';

/// Slug → demo-widget builder.
///
/// Using a builder (rather than a pre-constructed widget) keeps each
/// demo lazy.
final Map<String, Widget Function()> _demos = {
  'hand-drawn-toolkit': () => const HandDrawnToolkitDemo(),
  'page-turn-animation': () => const PageTurnDemo(),
  'recurrence-kit': () => const RecurrenceKitDemo(),
  'flip-calendar': () => const FlipCalendarDemo(),
};

void main() {
  final slug = Uri.base.queryParameters['demo'];
  final demo = slug == null ? null : _demos[slug]?.call();

  runApp(
    demo == null
        ? const _LandingPage()
        : _DemoReadySignal(slug: slug!, child: demo),
  );
}

/// Wraps a real demo and notifies the parent page when Flutter has
/// successfully mounted and painted its first frame.
///
/// This is the signal that opensource.html should treat as "success".
class _DemoReadySignal extends StatefulWidget {
  const _DemoReadySignal({required this.slug, required this.child});

  final String slug;
  final Widget child;

  @override
  State<_DemoReadySignal> createState() => _DemoReadySignalState();
}

class _DemoReadySignalState extends State<_DemoReadySignal> {
  bool _sentReady = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sentReady) return;
      _sentReady = true;

      web.window.parent?.postMessage(
        {'type': 'resengi:flutter-demo-ready', 'demo': widget.slug}.jsify(),
        web.window.location.origin.toJS,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Dev-only index shown when no (or an unknown) `?demo=` slug is supplied.
class _LandingPage extends StatelessWidget {
  const _LandingPage();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Resengi Examples',
      home: Scaffold(
        appBar: AppBar(title: const Text('Resengi Examples')),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                'Pick a demo to launch. In production these are loaded '
                'inside an iframe on the Open Source page. This landing '
                'page is a dev-only index.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            for (final slug in _demos.keys)
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: Text(slug),
                subtitle: Text('?demo=$slug'),
                onTap: () => web.window.location.assign('?demo=$slug'),
              ),
          ],
        ),
      ),
    );
  }
}
