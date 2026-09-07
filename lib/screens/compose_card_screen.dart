import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../data/entry_store.dart';
import '../models/doodle_models.dart';
import '../navigation/quiet_route.dart';
import '../widgets/daily_layout.dart';
import '../widgets/daily_sheet.dart';
import 'drawing_screen.dart';

class ComposeCardScreen extends StatefulWidget {
  const ComposeCardScreen({
    super.key,
    required this.store,
    required this.date,
    required this.strokes,
    required this.initialNote,
    required this.prompt,
    this.existingEntry,
  });

  final EntryStore store;
  final DateTime date;
  final List<DoodleStroke> strokes;
  final String initialNote;
  final String prompt;
  final DoodleEntry? existingEntry;

  @override
  State<ComposeCardScreen> createState() => _ComposeCardScreenState();
}

class _ComposeCardScreenState extends State<ComposeCardScreen> {
  static const int _noteLimit = 60;

  late List<DoodleStroke> _strokes;
  late final TextEditingController _noteController;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _noteFocus = FocusNode();

  int get _remainingCharacters =>
      (_noteLimit - _noteController.text.runes.length)
          .clamp(0, _noteLimit)
          .toInt();

  @override
  void initState() {
    super.initState();
    _strokes = List<DoodleStroke>.of(widget.strokes);
    _noteController = TextEditingController(
      text: String.fromCharCodes(
        widget.initialNote.runes.take(_noteLimit),
      ),
    );

    _noteFocus.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (_noteFocus.hasFocus) {
        Future<void>.delayed(const Duration(milliseconds: 180), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _scrollController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  void _noteChanged(String value) {
    if (mounted) {
      setState(() {});
    }

    unawaited(
      widget.store.saveDraft(
        date: widget.date,
        strokes: _strokes,
        note: value,
        prompt: widget.prompt,
      ),
    );
  }

  Future<void> _editDrawing() async {
    final revised = await Navigator.of(context).push<DoodleDraft>(
      quietRoute(
        DrawingScreen(
          store: widget.store,
          date: widget.date,
          initialStrokes: _strokes,
          initialNote: _noteController.text,
          initialPrompt: widget.prompt,
        ),
      ),
    );

    if (revised == null || !mounted) return;

    setState(() {
      _strokes = List<DoodleStroke>.of(revised.strokes);
      _noteController.text = String.fromCharCodes(
        revised.note.runes.take(_noteLimit),
      );
    });
  }

  Future<void> _save() async {
    _noteFocus.unfocus();

    final confirmed = await showOodConfirmDialog(
      context: context,
      title: '이 기록을 저장할까요?',
      message: '오늘의 그림과 한 줄 메모를 이대로 남겨요.',
    );
    if (!confirmed || !mounted) return;

    final now = DateTime.now();
    final entry = DoodleEntry(
      dateKey: widget.date.year.toString().padLeft(4, '0') +
          widget.date.month.toString().padLeft(2, '0') +
          widget.date.day.toString().padLeft(2, '0'),
      strokes: List<DoodleStroke>.of(_strokes),
      note: _noteController.text.trim(),
      prompt: widget.prompt,
      createdAt: widget.existingEntry?.createdAt ?? now,
      updatedAt: now,
    );

    await widget.store.saveEntry(entry);
    await widget.store.clearDraft();

    if (!mounted) return;
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final paperWidth = DailyLayoutMetrics.paperWidth(context);
    final paperHeight = paperWidth * 4 / 3;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            DailyLayoutMetrics.horizontalPadding,
            DailyLayoutMetrics.dailyTopPadding,
            DailyLayoutMetrics.horizontalPadding,
            DailyLayoutMetrics.bottomPadding,
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
              DailyPromptBlock(text: widget.prompt),
              const SizedBox(
                height: DailyLayoutMetrics.promptToPaper,
              ),
              SizedBox(
                width: paperWidth,
                height: paperHeight,
                child: DailyPaperShadow(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: kPaper),
                      DailySheet(
                        strokes: _strokes,
                        strokeWidth: 3.3,
                        showShadow: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: DailyLayoutMetrics.paperToNote,
              ),
              SizedBox(
                height: DailyLayoutMetrics.noteSlotHeight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: SizedBox(
                    width: paperWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _noteController,
                          focusNode: _noteFocus,
                          minLines: 1,
                          maxLines: 3,
                          maxLength: _noteLimit,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          inputFormatters: <TextInputFormatter>[
                            LengthLimitingTextInputFormatter(_noteLimit),
                          ],
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          textAlign: TextAlign.center,
                          onSubmitted: (_) => _noteFocus.unfocus(),
                          onChanged: _noteChanged,
                          scrollPadding: const EdgeInsets.only(bottom: 180),
                          style: GoogleFonts.gaegu(
                            fontSize: 18,
                            height: 1.45,
                            color: kInk,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText:
                                _noteFocus.hasFocus ? null : '한 줄 메모 남기기',
                            hintStyle: GoogleFonts.gaegu(
                              fontSize: 18,
                              height: 1.45,
                              color: kMutedInk.withAlpha(140),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.only(bottom: 10),
                          ),
                        ),
                        Container(
                          width: paperWidth,
                          height: 1,
                          color: kMutedInk.withAlpha(107),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 14,
                          child: Center(
                            child: Text(
                              _noteFocus.hasFocus
                                  ? '$_remainingCharacters자 남음'
                                  : '',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.gaegu(
                                fontSize: 12,
                                height: 1,
                                color: kSoftInk,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                    DailyTextAction(
                      label: '수정',
                      onTap: _editDrawing,
                    ),
                    const Spacer(),
                    DailyTextAction(
                      label: '저장',
                      onTap: _save,
                      strong: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
