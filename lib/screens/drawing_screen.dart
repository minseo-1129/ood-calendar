import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../content/prompt_provider.dart';
import '../data/entry_store.dart';
import '../models/doodle_models.dart';
import '../utils/date_labels.dart';
import '../widgets/daily_layout.dart';
import '../widgets/daily_sheet.dart';

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({
    super.key,
    required this.store,
    required this.date,
    required this.initialStrokes,
    required this.initialNote,
    required this.initialPrompt,
  });

  final EntryStore store;
  final DateTime date;
  final List<DoodleStroke> initialStrokes;
  final String initialNote;
  final String initialPrompt;

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  late final List<DoodleStroke> _strokes;
  late final String _prompt;
  List<Offset> _currentStroke = <Offset>[];
  Offset? _lastLocalPoint;

  bool get _canUndo => _strokes.isNotEmpty;
  bool get _canNext => _strokes.isNotEmpty;
  bool get _sheetEmpty => _strokes.isEmpty && _currentStroke.isEmpty;

  @override
  void initState() {
    super.initState();
    _strokes = List<DoodleStroke>.of(widget.initialStrokes);
    _prompt = widget.initialPrompt.isEmpty
        ? promptForDate(widget.date)
        : widget.initialPrompt;
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
    final current = event.localPosition;

    if (previous == null) {
      setState(() {
        _lastLocalPoint = current;
        _currentStroke = <Offset>[
          ..._currentStroke,
          _normalize(current, size),
        ];
      });
      return;
    }

    final distance = (current - previous).distance;
    if (distance < 0.55) return;

    final steps = math.max(1, (distance / 0.78).ceil());

    setState(() {
      final nextPoints = <Offset>[..._currentStroke];
      for (var i = 1; i <= steps; i++) {
        final point = Offset.lerp(previous, current, i / steps)!;
        nextPoints.add(_normalize(point, size));
      }
      _lastLocalPoint = current;
      _currentStroke = nextPoints;
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
      prompt: _prompt,
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
        prompt: _prompt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paperWidth = DailyLayoutMetrics.paperWidth(
      context,
      bottomPadding: 20,
    );
    final paperHeight = paperWidth * 4 / 3;
    final paperSize = Size(paperWidth, paperHeight);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DailyLayoutMetrics.horizontalPadding,
            DailyLayoutMetrics.topPadding,
            DailyLayoutMetrics.horizontalPadding,
            20,
          ),
          child: Column(
            children: [
              DailyHeader(
                date: widget.date,
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(
                height: DailyLayoutMetrics.headerToPrompt,
              ),
              DailyPromptBlock(text: _prompt),
              const SizedBox(
                height: DailyLayoutMetrics.promptToPaper,
              ),
              SizedBox(
                width: paperWidth,
                height: paperHeight,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => _startStroke(event, paperSize),
                  onPointerMove: (event) => _continueStroke(event, paperSize),
                  onPointerUp: (_) => _finishStroke(),
                  onPointerCancel: (_) => _finishStroke(),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DailySheet(
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                        strokeWidth: 3.3,
                      ),
                      if (_sheetEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 18,
                          child: IgnorePointer(
                            child: Text(
                              '여기에 그려보세요',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.gaegu(
                                fontSize: 15,
                                height: 1,
                                color: kPaperEdge,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: DailyLayoutMetrics.paperToNote,
              ),
              const SizedBox(
                height: DailyLayoutMetrics.noteSlotHeight,
              ),
              const SizedBox(
                height: DailyLayoutMetrics.noteToActions,
              ),
              SizedBox(
                height: DailyLayoutMetrics.actionHeight,
                child: Row(
                  children: [
                    DailyTextAction(
                      label: '되돌리기',
                      enabled: _canUndo,
                      onTap: _undo,
                    ),
                    const Spacer(),
                    DailyTextAction(
                      label: '다음',
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
