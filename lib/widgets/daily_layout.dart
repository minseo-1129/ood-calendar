import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../utils/date_labels.dart';

class DailyLayoutMetrics {
  static const double horizontalPadding = 24;
  static const double topPadding = 30;
  static const double headerHeight = 46;
  static const double headerToPrompt = 28;
  static const double promptSlotHeight = 48;
  static const double promptToPaper = 18;
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

class SodamHeader extends StatelessWidget {
  const SodamHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onForward,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onForward;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DailyLayoutMetrics.headerHeight,
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: onBack == null
                ? null
                : IconButton(
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      size: 26,
                      color: kMutedInk,
                    ),
                  ),
          ),
          Expanded(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -1),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gaegu(
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                    color: kInk,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: onForward == null
                ? null
                : IconButton(
                    onPressed: onForward,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      size: 26,
                      color: kMutedInk,
                    ),
                  ),
          ),
        ],
      ),
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
    return SodamHeader(
      title: drawingDateLabel(date),
      onBack: onBack,
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
