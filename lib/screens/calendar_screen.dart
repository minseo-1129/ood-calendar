import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../data/entry_store.dart';
import '../data/settings_store.dart';
import '../models/doodle_models.dart';
import '../navigation/quiet_route.dart';
import '../utils/date_labels.dart';
import '../widgets/daily_layout.dart';
import '../widgets/daily_sheet.dart';
import 'card_browse_screen.dart';
import 'settings_screen.dart';

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isAfter(today)) return;

    final result = await Navigator.of(context).push<DateTime>(
      quietRoute(
        CardBrowseScreen(
          store: widget.store,
          initialDate: date,
        ),
      ),
    );

    if (!mounted) return;
    if (result != null) {
      _visibleMonth = DateTime(result.year, result.month);
    }
    await _loadMonth();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      quietRoute<void>(
        SettingsScreen(
          entryStore: widget.store,
          settingsStore: SettingsStore(),
        ),
      ),
    );
    if (!mounted) return;
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
            padding: const EdgeInsets.fromLTRB(
              36,
              DailyLayoutMetrics.topPadding,
              36,
              24,
            ),
            child: Column(
              children: [
                _CalendarHeader(
                  title: monthLabel(_visibleMonth),
                  onPrevious: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
                  onTitleTap: _openSettings,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final gridHeight = math.min(
                        470.0,
                        math.max(320.0, constraints.maxHeight - 52),
                      );

                      return Center(
                        child: AnimatedOpacity(
                          opacity: _loading ? 0.55 : 1,
                          duration: const Duration(milliseconds: 160),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _WeekdayRow(),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: gridHeight,
                                child: _MonthGrid(
                                  month: _visibleMonth,
                                  today: today,
                                  entries: _entries,
                                  onTapDate: _openDate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.title,
    required this.onPrevious,
    required this.onNext,
    required this.onTitleTap,
  });

  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTitleTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DailyLayoutMetrics.headerHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTitleTap,
              behavior: HitTestBehavior.opaque,
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  title,
                  style: GoogleFonts.gaegu(
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w400,
                    color: kInk,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _CalendarArrow(
            icon: Icons.chevron_left_rounded,
            semanticsLabel: '이전 달',
            onTap: onPrevious,
          ),
          const SizedBox(width: 8),
          _CalendarArrow(
            icon: Icons.chevron_right_rounded,
            semanticsLabel: '다음 달',
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _CalendarArrow extends StatelessWidget {
  const _CalendarArrow({
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 28,
          height: 36,
          child: Align(
            alignment: Alignment.topCenter,
            child: Icon(
              icon,
              size: 24,
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
    const weekdays = <String>['일', '월', '화', '수', '목', '금', '토'];

    return Row(
      children: weekdays
          .map(
            (day) => Expanded(
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: GoogleFonts.gaegu(
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w400,
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
    final leading = first.weekday % 7;

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
        ? kSoftInk.withAlpha(95)
        : isToday
            ? kInk.withAlpha(235)
            : kMutedInk.withAlpha(195);

    return GestureDetector(
      onTap: isFuture ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isToday)
              Positioned(
                left: 2,
                right: 2,
                top: 0,
                height: 70,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: kAccent.withAlpha(33),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            Column(
              children: [
                SizedBox(
                  height: 24,
                  child: Center(
                    child: Text(
                      date.day.toString(),
                      style: GoogleFonts.gaegu(
                        fontSize: isToday ? 13 : 12,
                        height: 1,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w400,
                        color: dateColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Center(
                    child: entry != null
                        ? DoodleThumbnail(
                            strokes: entry!.strokes,
                            width: 38,
                            height: 44,
                          )
                        : Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isFuture
                                  ? const Color(0xFFD6D2C7)
                                  : kSoftInk,
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
