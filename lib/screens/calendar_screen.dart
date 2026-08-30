import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../data/entry_store.dart';
import '../models/doodle_models.dart';
import '../utils/date_labels.dart';
import '../widgets/daily_sheet.dart';
import 'card_browse_screen.dart';

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
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    if (date.isAfter(normalizedToday)) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CardBrowseScreen(
          store: widget.store,
          initialDate: date,
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
                    opacity: _loading ? 0.55 : 1,
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
                  color: kMutedInk.withAlpha(205),
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
            final isFuture = date.isAfter(
              DateTime(today.year, today.month, today.day),
            );

            return _DayCell(
              date: date,
              entry: entry,
              isToday: isToday,
              isFuture: isFuture,
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
    required this.isFuture,
    required this.onTap,
  });

  final DateTime date;
  final DoodleEntry? entry;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateColor = isFuture
        ? kSoftInk.withAlpha(105)
        : isToday
            ? kInk
            : kInk.withAlpha(176);

    return GestureDetector(
      onTap: isFuture ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 3, 2, 1),
        child: Column(
          children: [
            SizedBox(
              height: 28,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isToday
                        ? kAccent.withAlpha(30)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    date.day.toString(),
                    style: GoogleFonts.gaegu(
                      fontSize: 18,
                      fontWeight:
                          isToday ? FontWeight.w500 : FontWeight.w400,
                      color: dateColor,
                    ),
                  ),
                ),
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
                              fontWeight: FontWeight.w400,
                              color: kAccent,
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
