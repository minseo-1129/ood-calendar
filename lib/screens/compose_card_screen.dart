import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../data/entry_store.dart';
import '../models/doodle_models.dart';
import '../navigation/quiet_route.dart';
import '../utils/date_labels.dart';
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
    this.existingEntry,
  });

  final EntryStore store;
  final DateTime date;
  final List<DoodleStroke> strokes;
  final String initialNote;
  final DoodleEntry? existingEntry;

  @override
  State<ComposeCardScreen> createState() => _ComposeCardScreenState();
}

class _ComposeCardScreenState extends State<ComposeCardScreen> {
  late List<DoodleStroke> _strokes;
  late final TextEditingController _noteController;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _noteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _strokes = List<DoodleStroke>.of(widget.strokes);
    _noteController = TextEditingController(text: widget.initialNote);

    _noteFocus.addListener(() {
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
    unawaited(
      widget.store.saveDraft(
        date: widget.date,
        strokes: _strokes,
        note: value,
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
        ),
      ),
    );

    if (revised == null || !mounted) return;

    setState(() {
      _strokes = List<DoodleStroke>.of(revised.strokes);
      _noteController.text = revised.note;
    });
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final entry = DoodleEntry(
      dateKey: dateKey(widget.date),
      strokes: List<DoodleStroke>.of(_strokes),
      note: _noteController.text.trim(),
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
        child: LayoutBuilder(
          builder: (context, viewport) {
            return SingleChildScrollView(
              controller: _scrollController,
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                DailyLayoutMetrics.horizontalPadding,
                DailyLayoutMetrics.topPadding,
                DailyLayoutMetrics.horizontalPadding,
                20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewport.maxHeight - 44,
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
                    const SizedBox(
                      height: DailyLayoutMetrics.promptSlotHeight,
                    ),
                    const SizedBox(
                      height: DailyLayoutMetrics.promptToPaper,
                    ),
                    SizedBox(
                      width: paperWidth,
                      height: paperHeight,
                      child: DailySheet(
                        strokes: _strokes,
                        strokeWidth: 3.0,
                      ),
                    ),
                    const SizedBox(
                      height: DailyLayoutMetrics.paperToNote,
                    ),
                    SizedBox(
                      height: DailyLayoutMetrics.noteSlotHeight,
                      child: Center(
                        child: TextField(
                          controller: _noteController,
                          focusNode: _noteFocus,
                          maxLines: 1,
                          maxLength: 60,
                          textAlign: TextAlign.center,
                          onChanged: _noteChanged,
                          scrollPadding: const EdgeInsets.only(bottom: 160),
                          style: GoogleFonts.gaegu(
                            fontSize: 20,
                            height: 1.15,
                            color: kInk.withAlpha(215),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '한 줄 설명을 남길 수 있어요',
                            hintStyle: GoogleFonts.gaegu(
                              fontSize: 19,
                              height: 1.15,
                              color: kMutedInk.withAlpha(145),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
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
                            label: 'Edit',
                            onTap: _editDrawing,
                          ),
                          const Spacer(),
                          DailyTextAction(
                            label: 'Save',
                            onTap: _save,
                            strong: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
