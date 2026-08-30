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
    required this.initialDate,
  });

  final EntryStore store;
  final DateTime initialDate;

  @override
  State<CardBrowseScreen> createState() => _CardBrowseScreenState();
}

class _CardBrowseScreenState extends State<CardBrowseScreen> {
  Map<String, DoodleEntry> _entries = <String, DoodleEntry>{};
  PageController? _controller;
  late DateTime _startDate;
  late DateTime _today;
  int _index = 0;
  bool _loading = true;

  DateTime get _currentDate => _startDate.add(Duration(days: _index));
  DoodleEntry? get _currentEntry => _entries[dateKey(_currentDate)];

  @override
  void initState() {
    super.initState();
    _today = _dayOnly(DateTime.now());
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load({DateTime? focusDate}) async {
    final all = await widget.store.loadAll();

    DateTime earliest = _dayOnly(focusDate ?? widget.initialDate);
    for (final entry in all.values) {
      final entryDate = dateFromKey(entry.dateKey);
      if (entryDate.isBefore(earliest)) {
        earliest = entryDate;
      }
    }

    _startDate = DateTime(earliest.year, earliest.month, 1);

    final target = _dayOnly(focusDate ?? widget.initialDate);
    final index = target
        .difference(_startDate)
        .inDays
        .clamp(
          0,
          _today.difference(_startDate).inDays,
        )
        .toInt();

    final nextController = PageController(initialPage: index);
    final previousController = _controller;

    if (!mounted) {
      nextController.dispose();
      return;
    }

    setState(() {
      _entries = all;
      _index = index;
      _controller = nextController;
      _loading = false;
    });

    previousController?.dispose();
  }

  Future<void> _editCurrent() async {
    final date = _currentDate;
    if (!isSameDay(date, _today)) return;

    final existing = _currentEntry;
    final draft = await widget.store.loadDraft(date);
    if (!mounted) return;

    final drawing = await Navigator.of(context).push<DoodleDraft>(
      MaterialPageRoute(
        builder: (_) => DrawingScreen(
          store: widget.store,
          date: date,
          initialStrokes:
              draft?.strokes ?? existing?.strokes ?? const <DoodleStroke>[],
          initialNote: draft?.note ?? existing?.note ?? '',
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
          existingEntry: existing,
        ),
      ),
    );

    if (saved == null || !mounted) return;

    setState(() {
      _entries = <String, DoodleEntry>{
        ..._entries,
        saved.dateKey: saved,
      };
    });
  }

  int get _pageCount => _today.difference(_startDate).inDays + 1;

  @override
  Widget build(BuildContext context) {
    if (_loading || _controller == null) {
      return const Scaffold(
        body: Center(child: SizedBox.shrink()),
      );
    }

    final editable = isSameDay(_currentDate, _today);
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
                        drawingDateLabel(_currentDate),
                        style: GoogleFonts.gaegu(
                          fontSize: 29,
                          height: 1,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2,
                          color: kInk,
                        ),
                      ),
                    ),
                    if (editable)
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _editCurrent,
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            height: 44,
                            child: Center(
                              child: Text(
                                'Edit',
                                style: GoogleFonts.gaegu(
                                  fontSize: 18,
                                  height: 1,
                                  fontWeight: FontWeight.w400,
                                  color: kMutedInk,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(height: 34),
              const SizedBox(height: 8),
              SizedBox(
                height: maxPaperWidth * 4 / 3 + 48,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pageCount,
                  onPageChanged: (index) {
                    setState(() => _index = index);
                  },
                  itemBuilder: (context, index) {
                    final date = _startDate.add(Duration(days: index));
                    final entry = _entries[dateKey(date)];

                    return Column(
                      children: [
                        SizedBox(
                          width: maxPaperWidth,
                          height: maxPaperWidth * 4 / 3,
                          child: DailySheet(
                            strokes:
                                entry?.strokes ?? const <DoodleStroke>[],
                            strokeWidth: 3.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: entry == null || entry.note.isEmpty
                                ? const SizedBox.shrink()
                                : Text(
                                    entry.note,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.gaegu(
                                      fontSize: 20,
                                      height: 1,
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
              const SizedBox(height: 4),
              const SizedBox(height: 44),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

DateTime _dayOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
