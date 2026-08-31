import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../content/prompt_provider.dart';
import '../data/entry_store.dart';
import '../models/doodle_models.dart';
import '../navigation/quiet_route.dart';
import '../utils/date_labels.dart';
import '../widgets/daily_layout.dart';
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
  bool _showSavedToast = false;
  Timer? _toastTimer;

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
    _toastTimer?.cancel();
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

    final prompt = draft?.prompt.isNotEmpty == true
        ? draft!.prompt
        : existing?.prompt.isNotEmpty == true
            ? existing!.prompt
            : promptForDate(date);

    final drawing = await Navigator.of(context).push<DoodleDraft>(
      quietRoute(
        DrawingScreen(
          store: widget.store,
          date: date,
          initialStrokes:
              draft?.strokes ?? existing?.strokes ?? const <DoodleStroke>[],
          initialNote: draft?.note ?? existing?.note ?? '',
          initialPrompt: prompt,
        ),
      ),
    );

    if (drawing == null || !mounted) return;

    final saved = await Navigator.of(context).push<DoodleEntry>(
      quietRoute(
        ComposeCardScreen(
          store: widget.store,
          date: date,
          strokes: drawing.strokes,
          initialNote: drawing.note,
          prompt: drawing.prompt,
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

    _showSaveConfirmation();
  }

  void _showSaveConfirmation() {
    _toastTimer?.cancel();

    setState(() {
      _showSavedToast = true;
    });

    _toastTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _showSavedToast = false;
      });
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
    final paperWidth = DailyLayoutMetrics.paperWidth(context);
    final paperHeight = paperWidth * 4 / 3;
    final promptText = _currentEntry?.prompt.isNotEmpty == true
        ? _currentEntry!.prompt
        : editable
            ? promptForDate(_currentDate)
            : '';

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
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
                    date: _currentDate,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(
                    height: DailyLayoutMetrics.headerToPrompt,
                  ),
                  DailyPromptBlock(
                    text: promptText,
                    label: promptText.isEmpty ? null : '그날의 질문',
                  ),
                  const SizedBox(
                    height: DailyLayoutMetrics.promptToPaper,
                  ),
                  SizedBox(
                    width: paperWidth,
                    height: paperHeight,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pageCount,
                      onPageChanged: (index) {
                        setState(() => _index = index);
                      },
                      itemBuilder: (context, index) {
                        final date = _startDate.add(Duration(days: index));
                        final entry = _entries[dateKey(date)];

                        final isLockedEmpty =
                            entry == null && date.isBefore(_today);

                        if (isLockedEmpty) {
                          return const LockedEmptySheet();
                        }

                        if (entry == null) {
                          return const DailySheet(
                            strokes: <DoodleStroke>[],
                          );
                        }

                        return SavedTapedSheet(
                          strokes: entry.strokes,
                        );
                      },
                    ),
                  ),
                  const SizedBox(
                    height: DailyLayoutMetrics.paperToNote,
                  ),
                  SizedBox(
                    height: DailyLayoutMetrics.noteSlotHeight,
                    child: Center(
                      child: SizedBox(
                        width: paperWidth,
                        child: _currentEntry == null ||
                                _currentEntry!.note.isEmpty
                            ? const SizedBox.shrink()
                            : Text(
                                _currentEntry!.note,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.gaegu(
                                  fontSize: 18,
                                  height: 1.22,
                                  color: kMutedInk,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: DailyLayoutMetrics.noteToActions,
                  ),
                  SizedBox(
                    height: DailyLayoutMetrics.actionHeight,
                    child: Row(
                      children: [
                        const SizedBox.shrink(),
                        const Spacer(),
                        if (editable)
                          DailyTextAction(
                            label: 'Edit',
                            onTap: _editCurrent,
                            strong: true,
                          )
                        else
                          const SizedBox(
                            width: 44,
                            height: DailyLayoutMetrics.actionHeight,
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 92,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showSavedToast ? 1 : 0,
                duration: const Duration(milliseconds: 140),
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: kInk.withAlpha(228),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 17,
                        vertical: 8,
                      ),
                      child: Text(
                        '저장했어요',
                        style: GoogleFonts.gaegu(
                          fontSize: 16,
                          height: 1,
                          fontWeight: FontWeight.w400,
                          color: kBackground,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DateTime _dayOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}
