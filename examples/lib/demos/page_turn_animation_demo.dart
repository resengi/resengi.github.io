import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:page_turn_animation/page_turn_animation.dart';

// =============================================================================
// App
// =============================================================================

/// Top-level demo widget for the page_turn_animation package.
///
/// Adapted from the package's example app. Loaded by the URL router in
/// `main.dart` when `?demo=page-turn-animation` is present in the iframe URL.
///
/// Simulates a simple book whose pages can be turned forward and backward
/// with realistic curl animations. Use the edge selector to switch between
/// top, bottom, left, and right curl directions.
class PageTurnDemo extends StatelessWidget {
  const PageTurnDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Page Turn Animation Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.brown,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF3E2723),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4E342E),
          foregroundColor: Color(0xFFEFEBE9),
        ),
      ),
      home: const BookViewer(),
    );
  }
}

// =============================================================================
// Book page data
// =============================================================================

class BookPage {
  const BookPage({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
  });

  final String title;
  final String body;
  final Color color;
  final IconData icon;
}

const List<BookPage> _pages = [
  BookPage(
    title: 'Page Turn Animation',
    body:
        'A Flutter package for realistic 3D page curl transitions. '
        'Works with any widget content — just capture it as a ui.Image '
        'using a RepaintBoundary and hand it to PageTurnAnimation.',
    color: Color(0xFFFFF3E0),
    icon: Icons.auto_stories,
  ),
  BookPage(
    title: 'Choose Your Edge',
    body:
        'Use the PageTurnEdge enum to control which side the page '
        'curls over: top (notepad), bottom (wall calendar), '
        'right (manga), or left (Western book). '
        'Try the selector above to see each one in action!',
    color: Color(0xFFE8F5E9),
    icon: Icons.swap_horiz,
  ),
  BookPage(
    title: 'Customize the Style',
    body:
        'PageTurnStyle lets you tweak backgroundColor, shadowColor, '
        'shadowOpacity, shadowBlurRadius, segments (quality vs. '
        'performance), and curlIntensity. Use copyWith on '
        'PageTurnStyle.defaults for quick adjustments.',
    color: Color(0xFFE1F5FE),
    icon: Icons.tune,
  ),
  BookPage(
    title: 'Tips & Best Practices',
    body:
        'Capture images at the device\'s pixel ratio for crisp results. '
        'Wrap your animation controller in a CurvedAnimation for natural '
        'motion. Lower the segment count (50–80) on budget devices. '
        'Always dispose captured images when done.',
    color: Color(0xFFFCE4EC),
    icon: Icons.lightbulb_outline,
  ),
];

// =============================================================================
// Animation phases
// =============================================================================

/// [idle]      — show the current page normally.
/// [capturing] — both current and target pages render in RepaintBoundary
///               widgets so their pixels can be captured.
/// [animating] — captured images drive the PageTurnAnimation widget.
enum _Phase { idle, capturing, animating }

// =============================================================================
// BookViewer
// =============================================================================

class BookViewer extends StatefulWidget {
  const BookViewer({super.key});

  @override
  State<BookViewer> createState() => _BookViewerState();
}

class _BookViewerState extends State<BookViewer>
    with SingleTickerProviderStateMixin {
  // State
  int _currentIndex = 0;
  int _targetIndex = 0;
  bool _isForward = true;
  _Phase _phase = _Phase.idle;
  PageTurnEdge _edge = PageTurnEdge.left;

  // Captured images
  ui.Image? _currentImage;
  ui.Image? _targetImage;

  // Keys for dual RepaintBoundary capture
  final GlobalKey _currentKey = GlobalKey();
  final GlobalKey _targetKey = GlobalKey();

  // Animation
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 1000),
    vsync: this,
  );

  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.decelerate,
  );

  /// Style configuration for the page turn effect. Customize these values
  /// to change how the curl looks during animation.
  static const _pageTurnStyle = PageTurnStyle(
    backgroundColor: Color(0xFFFAF3E8),
    shadowColor: Colors.black,
    shadowOpacity: 0.8,
    shadowBlurRadius: 20.0,
    segments: 150,
    curlIntensity: 1.0,
  );

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    _disposeImages();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Image capture
  // ---------------------------------------------------------------------------

  Future<bool> _captureImages() async {
    if (!mounted) return false;
    final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;

    final currentBoundary =
        _currentKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (currentBoundary != null) {
      _currentImage = await currentBoundary.toImage(pixelRatio: pixelRatio);
    }

    final targetBoundary =
        _targetKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (targetBoundary != null) {
      _targetImage = await targetBoundary.toImage(pixelRatio: pixelRatio);
    }

    return _currentImage != null && _targetImage != null;
  }

  void _disposeImages() {
    _currentImage?.dispose();
    _targetImage?.dispose();
    _currentImage = null;
    _targetImage = null;
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  Future<void> _turnForward() async {
    if (_phase != _Phase.idle || _currentIndex >= _pages.length - 1) return;
    _isForward = true;
    _targetIndex = _currentIndex + 1;
    await _runPageTurn();
  }

  Future<void> _turnBackward() async {
    if (_phase != _Phase.idle || _currentIndex <= 0) return;
    _isForward = false;
    _targetIndex = _currentIndex - 1;
    await _runPageTurn();
  }

  /// Full capture → animate → commit lifecycle.
  Future<void> _runPageTurn() async {
    // 1. Render both pages for image capture.
    setState(() => _phase = _Phase.capturing);
    await SchedulerBinding.instance.endOfFrame;

    // 2. Capture both RepaintBoundary images.
    final success = await _captureImages();
    if (!success || !mounted) {
      _cleanup();
      return;
    }

    // 3. Animate.
    setState(() => _phase = _Phase.animating);
    try {
      await _controller.forward();
    } catch (_) {}

    if (!mounted) return;

    // 4. Commit page change.
    setState(() => _currentIndex = _targetIndex);
    _cleanup();
  }

  void _cleanup() {
    if (!mounted) return;
    setState(() => _phase = _Phase.idle);
    _controller.reset();
    _disposeImages();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Turn Animation')),
      body: Column(
        children: [
          // Edge selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Edge over which to turn page',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFBCAAA4),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<PageTurnEdge>(
                  value: _edge,
                  dropdownColor: const Color(0xFF4E342E),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFEFEBE9),
                  ),
                  underline: Container(
                    height: 1,
                    color: const Color(0xFFBCAAA4),
                  ),
                  iconEnabledColor: const Color(0xFFBCAAA4),
                  items: const [
                    DropdownMenuItem(
                      value: PageTurnEdge.top,
                      child: Text('Top'),
                    ),
                    DropdownMenuItem(
                      value: PageTurnEdge.bottom,
                      child: Text('Bottom'),
                    ),
                    DropdownMenuItem(
                      value: PageTurnEdge.left,
                      child: Text('Left'),
                    ),
                    DropdownMenuItem(
                      value: PageTurnEdge.right,
                      child: Text('Right'),
                    ),
                  ],
                  onChanged: (edge) {
                    if (edge != null) setState(() => _edge = edge);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Book area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildForPhase(),
            ),
          ),
          const SizedBox(height: 8),

          // Page indicator
          Text(
            'Page ${(_phase == _Phase.idle ? _currentIndex : _targetIndex) + 1} '
            'of ${_pages.length}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFBCAAA4)),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _currentIndex > 0 && _phase == _Phase.idle
                      ? _turnBackward
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed:
                      _currentIndex < _pages.length - 1 && _phase == _Phase.idle
                      ? _turnForward
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForPhase() {
    switch (_phase) {
      // Both pages rendered with RepaintBoundary for image capture.
      // Current page on top so the screen doesn't visually flash.
      case _Phase.capturing:
        return Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                key: _targetKey,
                child: _buildPage(_targetIndex),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                key: _currentKey,
                child: _buildPage(_currentIndex),
              ),
            ),
          ],
        );

      // Hand captured images to PageTurnAnimation.
      case _Phase.animating:
        return Stack(
          children: [
            // Bottom layer: the destination page.
            Positioned.fill(child: _buildPage(_targetIndex)),

            // Forward: current page curls away, revealing destination.
            if (_isForward && _currentImage != null)
              PageTurnAnimation(
                image: _currentImage!,
                animation: _curve,
                direction: PageTurnDirection.forward,
                edge: _edge,
                style: _pageTurnStyle,
              ),

            // Backward: static current-page image hides destination,
            // then target-page image curls into view on top.
            if (!_isForward) ...[
              if (_currentImage != null)
                Positioned.fill(
                  child: RawImage(image: _currentImage, fit: BoxFit.fill),
                ),
              if (_targetImage != null)
                PageTurnAnimation(
                  image: _targetImage!,
                  animation: _curve,
                  direction: PageTurnDirection.backward,
                  edge: _edge,
                  style: _pageTurnStyle,
                ),
            ],
          ],
        );

      case _Phase.idle:
        return _buildPage(_currentIndex);
    }
  }

  Widget _buildPage(int index) {
    final page = _pages[index];
    return ColoredBox(
      color: page.color,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(page.icon, size: 64, color: Colors.brown.shade400),
            const SizedBox(height: 24),
            Text(
              page.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              page.body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.brown.shade700,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}