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
  bool get _canFinish => _strokes.isNotEmpty;

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
    if (!_canFinish) return;

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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: Column(
            children: [
              SizedBox(
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '‹',
                            style: GoogleFonts.gaegu(
                              fontSize: 28,
                              color: kMutedInk,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        drawingDateLabel(widget.date),
                        style: GoogleFonts.gaegu(
                          fontSize: 29,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2,
                          color: kInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '오늘 이상하게 기억나는 것 하나',
                textAlign: TextAlign.center,
                style: GoogleFonts.gaegu(
                  fontSize: 21,
                  fontWeight: FontWeight.w400,
                  color: kInk.withAlpha(182),
                ),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final widthByHeight = constraints.maxHeight * 3 / 4;
                      final sheetWidth = math.min(
                        324.0,
                        math.min(constraints.maxWidth, widthByHeight),
                      );
                      final sheetSize =
                          Size(sheetWidth, sheetWidth * 4 / 3);

                      return SizedBox(
                        width: sheetSize.width,
                        height: sheetSize.height,
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (event) =>
                              _startStroke(event, sheetSize),
                          onPointerMove: (event) =>
                              _continueStroke(event, sheetSize),
                          onPointerUp: (_) => _finishStroke(),
                          onPointerCancel: (_) => _finishStroke(),
                          child: DailySheet(
                            strokes: _strokes,
                            currentStroke: _currentStroke,
                            strokeWidth: 3.0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _QuietAction(
                    label: '↶  Undo',
                    enabled: _canUndo,
                    onTap: _undo,
                  ),
                  const Spacer(),
                  _QuietAction(
                    label: 'Next',
                    enabled: _canFinish,
                    onTap: _next,
                    strong: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietAction extends StatelessWidget {
  const _QuietAction({
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
        : kSoftInk.withAlpha(150);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          label,
          style: GoogleFonts.gaegu(
            fontSize: 19,
            fontWeight: strong ? FontWeight.w400 : FontWeight.w300,
            letterSpacing: 0.6,
            color: color,
          ),
        ),
      ),
    );
  }
}
