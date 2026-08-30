import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../data/entry_store.dart';
import '../models/doodle_models.dart';
import '../utils/date_labels.dart';
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

  @override
  void initState() {
    super.initState();
    _strokes = List<DoodleStroke>.of(widget.strokes);
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
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
      MaterialPageRoute(
        builder: (_) => DrawingScreen(
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
              _ComposeHeader(
                date: widget.date,
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 18),
              const SizedBox(height: 34),
              const SizedBox(height: 8),
              SizedBox(
                width: maxPaperWidth,
                height: maxPaperWidth * 4 / 3,
                child: DailySheet(
                  strokes: _strokes,
                  strokeWidth: 3.0,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 58,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      '오늘을 한 줄로 남겨도 좋아요',
                      style: GoogleFonts.gaegu(
                        fontSize: 16,
                        height: 1,
                        color: kMutedInk.withAlpha(185),
                      ),
                    ),
                    const SizedBox(height: 1),
                    SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _noteController,
                        maxLines: 1,
                        maxLength: 60,
                        textAlign: TextAlign.center,
                        onChanged: _noteChanged,
                        style: GoogleFonts.gaegu(
                          fontSize: 20,
                          height: 1,
                          color: kInk.withAlpha(205),
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '한 줄 (선택)',
                          hintStyle: GoogleFonts.gaegu(
                            fontSize: 20,
                            height: 1,
                            color: kMutedInk.withAlpha(130),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    _ComposeAction(
                      label: 'Edit',
                      onTap: _editDrawing,
                    ),
                    const Spacer(),
                    _ComposeAction(
                      label: 'Save',
                      onTap: _save,
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

class _ComposeHeader extends StatelessWidget {
  const _ComposeHeader({
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

class _ComposeAction extends StatelessWidget {
  const _ComposeAction({
    required this.label,
    required this.onTap,
    this.strong = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            color: strong ? kInk : kMutedInk,
          ),
        ),
      ),
    );
  }
}
