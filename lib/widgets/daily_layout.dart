import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../utils/date_labels.dart';

class DailyLayoutMetrics {
  static const double horizontalPadding = 24;
  static const double topPadding = 24;
  static const double headerHeight = 44;
  static const double headerToPrompt = 24;
  static const double promptSlotHeight = 34;
  static const double promptToPaper = 12;
  static const double paperMaxWidth = 288;
  static const double paperToNote = 18;
  static const double noteSlotHeight = 52;
  static const double noteToActions = 8;
  static const double actionHeight = 44;

  static double paperWidth(BuildContext context) {
    return math.min(
      paperMaxWidth,
      MediaQuery.sizeOf(context).width - horizontalPadding * 2,
    );
  }
}

class DailyHeader extends StatelessWidget {
  const DailyHeader({
    super.key,
    required this.date,
    required this.onBack,
  });

  final DateTime date;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DailyLayoutMetrics.headerHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkResponse(
              onTap: onBack,
              radius: 24,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 26,
                  color: kMutedInk,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              drawingDateLabel(date),
              style: GoogleFonts.gaegu(
                fontSize: 28,
                height: 1,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
                color: kInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DailyTextAction extends StatelessWidget {
  const DailyTextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.strong = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? (strong ? kInk : kMutedInk)
        : kSoftInk.withAlpha(140);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: DailyLayoutMetrics.actionHeight,
        child: Align(
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.gaegu(
              fontSize: 19,
              height: 1,
              fontWeight: strong ? FontWeight.w500 : FontWeight.w400,
              letterSpacing: 0.3,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
