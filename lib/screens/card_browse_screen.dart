import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../data/entry_store.dart';
import '../models/doodle_models.dart';
import '../utils/date_labels.dart';
import '../widgets/daily_sheet.dart';
import 'compose_card_screen.dart';
import 'drawing_screen.dart';

class CardBrowseScreen extends StatefulWidget {
  const CardBrowseScreen({
    super.key,
    required this.store,
    required this.initialDateKey,
  });

  final EntryStore store;
  final String initialDateKey;

  @override
  State<CardBrowseScreen> createState() => _CardBrowseScreenState();
}

class _CardBrowseScreenState extends State<CardBrowseScreen> {
  List<DoodleEntry> _entries = <DoodleEntry>[];
  PageController? _controller;
  int _index = 0;
  bool _loading = true;

  DoodleEntry? get _current {
    if (_entries.isEmpty) return null;
    return _entries[_index];
  }

  @override
  void initState() {
    super.initState();
    _loadEntries(focusKey: widget.initialDateKey);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadEntries({required String focusKey}) async {
    final all = await widget.store.loadAll();
    final entries = all.values.toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));

    var index = entries.indexWhere((entry) => entry.dateKey == focusKey);
    if (index < 0) {
      index = entries.isEmpty ? 0 : entries.length - 1;
    }

    final nextController = PageController(initialPage: index);
    final previousController = _controller;

    if (!mounted) {
      nextController.dispose();
      return;
    }

    setState(() {
      _entries = entries;
      _index = index;
      _controller = nextController;
      _loading = false;
    });

    previousController?.dispose();
  }

  Future<void> _editCurrent() async {
    final current = _current;
    if (current == null) return;

    final date = dateFromKey(current.dateKey);
    if (!isSameDay(date, DateTime.now())) return;

    final draft = await widget.store.loadDraft(date);
    if (!mounted) return;

    final drawing = await Navigator.of(context).push<DoodleDraft>(
      MaterialPageRoute(
        builder: (_) => DrawingScreen(
          store: widget.store,
          date: date,
          initialStrokes: draft?.strokes ?? current.strokes,
          initialNote: draft?.note ?? current.note,
        ),
      ),
    );

    if (drawing == null || !mounted) return;

    final saved = await Navigator.of(context).push<DoodleEntry>(
      MaterialPageRoute(
        builder: (_) => ComposeCardScreen(
          store: widget.store,
          date: date,
          strokes: drawing.strokes,
          initialNote: drawing.note,
          existingEntry: current,
        ),
      ),
    );

    if (saved == null || !mounted) return;
    await _loadEntries(focusKey: saved.dateKey);
  }

  void _previous() {
    if (_controller == null || _index <= 0) return;
    _controller!.animateToPage(
      _index - 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_controller == null || _index >= _entries.length - 1) return;
    _controller!.animateToPage(
      _index + 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _controller == null) {
      return const Scaffold(
        body: Center(child: SizedBox.shrink()),
      );
    }

    if (_entries.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              '아직 모인 카드가 없어요',
              style: GoogleFonts.gaegu(
                fontSize: 20,
                color: kMutedInk,
              ),
            ),
          ),
        ),
      );
    }

    final current = _current!;
    final editable = isSameDay(
      dateFromKey(current.dateKey),
      DateTime.now(),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: Column(
            children: [
              SizedBox(
                height: 44,
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
                        drawingDateLabel(
                          dateFromKey(current.dateKey),
                        ),
                        style: GoogleFonts.gaegu(
                          fontSize: 29,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2,
                          color: kInk,
                        ),
                      ),
                    ),
                    if (editable)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _editCurrent,
                          style: TextButton.styleFrom(
                            foregroundColor: kMutedInk,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: Text(
                            '수정',
                            style: GoogleFonts.gaegu(fontSize: 18),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _entries.length,
                  onPageChanged: (index) {
                    setState(() => _index = index);
                  },
                  itemBuilder: (context, index) {
                    final entry = _entries[index];

                    return Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final widthByHeight =
                                    constraints.maxHeight * 3 / 4;
                                final sheetWidth = math.min(
                                  310.0,
                                  math.min(
                                    constraints.maxWidth,
                                    widthByHeight,
                                  ),
                                );

                                return SizedBox(
                                  width: sheetWidth,
                                  height: sheetWidth * 4 / 3,
                                  child: DailySheet(
                                    strokes: entry.strokes,
                                    strokeWidth: 3.0,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 32,
                          child: Center(
                            child: entry.note.isEmpty
                                ? const SizedBox.shrink()
                                : Text(
                                    entry.note,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.gaegu(
                                      fontSize: 20,
                                      color: kMutedInk,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _BrowseArrow(
                    label: '←',
                    enabled: _index > 0,
                    onTap: _previous,
                  ),
                  Expanded(
                    child: Text(
                      (_index + 1).toString() +
                          ' / ' +
                          _entries.length.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.gaegu(
                        fontSize: 15,
                        color: kSoftInk,
                      ),
                    ),
                  ),
                  _BrowseArrow(
                    label: '→',
                    enabled: _index < _entries.length - 1,
                    onTap: _next,
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

class _BrowseArrow extends StatelessWidget {
  const _BrowseArrow({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 36,
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.gaegu(
              fontSize: 19,
              color: enabled ? kMutedInk : kSoftInk.withAlpha(100),
            ),
          ),
        ),
      ),
    );
  }
}
