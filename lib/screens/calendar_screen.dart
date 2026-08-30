import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../data/entry_store.dart';
import '../models/doodle_models.dart';
import '../utils/date_labels.dart';
import '../widgets/daily_sheet.dart';
import 'card_browse_screen.dart';
import 'compose_card_screen.dart';
import 'drawing_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.store,
  });

  final EntryStore store;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;
  Map<String, DoodleEntry> _entries = <String, DoodleEntry>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    final entries = await widget.store.loadMonth(_visibleMonth);

    if (!mounted) return;

    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _changeMonth(int delta) async {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      );
      _loading = true;
    });

    await _loadMonth();
  }

  Future<void> _openDate(DateTime date) async {
    final entry = _entries[dateKey(date)];
    final today = DateTime.now();

    if (entry != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CardBrowseScreen(
            store: widget.store,
            initialDateKey: entry.dateKey,
          ),
        ),
      );
      await _loadMonth();
      return;
    }

    if (!isSameDay(date, today)) return;

    final draft = await widget.store.loadDraft(date);
    if (!mounted) return;

    final drawing = await Navigator.of(context).push<DoodleDraft>(
      MaterialPageRoute(
        builder: (_) => DrawingScreen(
          store: widget.store,
          date: date,
          initialStrokes:
              draft?.strokes ?? const <DoodleStroke>[],
          initialNote: draft?.note ?? '',
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
        ),
      ),
    );

    if (saved == null || !mounted) return;

    await _loadMonth();
    if (!mounted) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CardBrowseScreen(
          store: widget.store,
          initialDateKey: saved.dateKey,
        ),
      ),
    );

    await _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;

            if (velocity < -220) {
              _changeMonth(1);
            } else if (velocity > 220) {
              _changeMonth(-1);
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      _MonthArrow(
                        label: '‹',
                        onTap: () => _changeMonth(-1),
                      ),
                      Expanded(
                        child: Text(
                          monthLabel(_visibleMonth),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.gaegu(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.8,
                            color: kInk,
                          ),
                        ),
                      ),
                      _MonthArrow(
                        label: '›',
                        onTap: () => _changeMonth(1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _WeekdayRow(),
                const SizedBox(height: 8),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _loading ? 0.45 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: _MonthGrid(
                      month: _visibleMonth,
                      today: today,
                      entries: _entries,
                      onTapDate: _openDate,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.gaegu(
              fontSize: 27,
              color: kMutedInk,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow();

  @override
  Widget build(BuildContext context) {
    const weekdays = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      children: weekdays
          .map(
            (day) => Expanded(
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: GoogleFonts.gaegu(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                  color: kSoftInk,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.entries,
    required this.onTapDate,
  });

  final DateTime month;
  final DateTime today;
  final Map<String, DoodleEntry> entries;
  final ValueChanged<DateTime> onTapDate;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - DateTime.monday;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellHeight = constraints.maxHeight / 6;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 42,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: cellHeight,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leading + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }

            final date = DateTime(
              month.year,
              month.month,
              dayNumber,
            );
            final entry = entries[dateKey(date)];
            final isToday = isSameDay(date, today);

            return _DayCell(
              date: date,
              entry: entry,
              isToday: isToday,
              onTap: () => onTapDate(date),
            );
          },
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.entry,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final DoodleEntry? entry;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tappable = entry != null || isToday;

    return GestureDetector(
      onTap: tappable ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 3, 2, 1),
        child: Column(
          children: [
            Text(
              date.day.toString(),
              style: GoogleFonts.gaegu(
                fontSize: 16,
                fontWeight: isToday ? FontWeight.w400 : FontWeight.w300,
                color: isToday ? kInk : kMutedInk,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Center(
                child: entry != null
                    ? DoodleThumbnail(strokes: entry!.strokes)
                    : isToday
                        ? Text(
                            '+',
                            style: GoogleFonts.gaegu(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: kMutedInk,
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
