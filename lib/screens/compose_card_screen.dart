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
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final widthByHeight = constraints.maxHeight * 3 / 4;
                      final sheetWidth = math.min(
                        310.0,
                        math.min(constraints.maxWidth, widthByHeight),
                      );

                      return SizedBox(
                        width: sheetWidth,
                        height: sheetWidth * 4 / 3,
                        child: DailySheet(
                          strokes: _strokes,
                          strokeWidth: 3.0,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 1,
                maxLength: 60,
                textAlign: TextAlign.center,
                onChanged: _noteChanged,
                style: GoogleFonts.gaegu(
                  fontSize: 20,
                  color: kMutedInk,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '한 줄 (선택)',
                  hintStyle: GoogleFonts.gaegu(
                    fontSize: 20,
                    color: kSoftInk,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  GestureDetector(
                    onTap: _editDrawing,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      child: Text(
                        '↶  다시 그리기',
                        style: GoogleFonts.gaegu(
                          fontSize: 18,
                          color: kMutedInk,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _save,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.gaegu(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.7,
                          color: kInk,
                        ),
                      ),
                    ),
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
