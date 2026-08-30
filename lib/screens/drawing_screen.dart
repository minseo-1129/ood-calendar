import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../data/entry_store.dart';
import '../models/doodle_models.dart';
import '../utils/date_labels.dart';
import '../widgets/daily_sheet.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({
    super.key,
    required this.store,
    required this.date,
    required this.initialStrokes,
    required this.initialNote,
  });

  final EntryStore store;
  final DateTime date;
  final List<DoodleStroke> initialStrokes;
  final String initialNote;

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late final List<DoodleStroke> _strokes;
  List<Offset> _currentStroke = <Offset>[];
  Offset? _lastLocalPoint;

  bool get _canUndo => _strokes.isNotEmpty;
  bool get _canNext => _strokes.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _strokes = List<DoodleStroke>.of(widget.initialStrokes);
  }

  void _startStroke(PointerDownEvent event, Size size) {
    setState(() {
      _lastLocalPoint = event.localPosition;
      _currentStroke = <Offset>[
        _normalize(event.localPosition, size),
      ];
    });
  }

  void _continueStroke(PointerMoveEvent event, Size size) {
    final previous = _lastLocalPoint;

    if (previous != null &&
        (event.localPosition - previous).distance < 1.8) {
      return;
    }

    setState(() {
      _lastLocalPoint = event.localPosition;
      _currentStroke = <Offset>[
        ..._currentStroke,
        _normalize(event.localPosition, size),
      ];
    });
  }

  void _finishStroke() {
    if (_currentStroke.isEmpty) return;

    setState(() {
      _strokes.add(DoodleStroke(_currentStroke));
      _currentStroke = <Offset>[];
      _lastLocalPoint = null;
    });

    unawaited(_saveDraft());
  }

  Offset _normalize(Offset point, Size size) {
    return Offset(
      (point.dx / size.width).clamp(0.0, 1.0),
      (point.dy / size.height).clamp(0.0, 1.0),
    );
  }

  void _undo() {
    if (!_canUndo) return;

    setState(_strokes.removeLast);
    unawaited(_saveDraft());
  }

  Future<void> _saveDraft() {
    return widget.store.saveDraft(
      date: widget.date,
      strokes: _strokes,
      note: widget.initialNote,
    );
  }

  Future<void> _next() async {
    if (!_canNext) return;

    await _saveDraft();
    if (!mounted) return;

    Navigator.of(context).pop(
      DoodleDraft(
        dateKey: dateKey(widget.date),
        strokes: List<DoodleStroke>.of(_strokes),
        note: widget.initialNote,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxPaperWidth = math.min(
      310.0,
      MediaQuery.sizeOf(context).width - 48,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            children: [
              _ScreenHeader(
                date: widget.date,
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 34,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Text(
                    '오늘 이상하게 기억나는 것 하나',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.gaegu(
                      fontSize: 20,
                      height: 1,
                      fontWeight: FontWeight.w400,
                      color: kInk.withAlpha(190),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: maxPaperWidth,
                height: maxPaperWidth * 4 / 3,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => _startStroke(
                    event,
                    Size(maxPaperWidth, maxPaperWidth * 4 / 3),
                  ),
                  onPointerMove: (event) => _continueStroke(
                    event,
                    Size(maxPaperWidth, maxPaperWidth * 4 / 3),
                  ),
                  onPointerUp: (_) => _finishStroke(),
                  onPointerCancel: (_) => _finishStroke(),
                  child: DailySheet(
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    strokeWidth: 3.0,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    _TextAction(
                      label: 'Undo',
                      enabled: _canUndo,
                      onTap: _undo,
                    ),
                    const Spacer(),
                    _TextAction(
                      label: 'Next',
                      enabled: _canNext,
                      onTap: _next,
                      strong: true,
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({
    required this.date,
    required this.onBack,
  });

  final DateTime date;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Text(
                    '‹',
                    style: GoogleFonts.gaegu(
                      fontSize: 29,
                      height: 1,
                      color: kMutedInk,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              drawingDateLabel(date),
              style: GoogleFonts.gaegu(
                fontSize: 29,
                height: 1,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.2,
                color: kInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.strong = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? (strong ? kInk : kMutedInk)
        : kSoftInk.withAlpha(140);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 4,
        ),
        child: Text(
          label,
          style: GoogleFonts.gaegu(
            fontSize: 19,
            height: 1,
            fontWeight:
                strong ? FontWeight.w500 : FontWeight.w400,
            letterSpacing: 0.4,
            color: color,
          ),
        ),
      ),
    );
  }
}
