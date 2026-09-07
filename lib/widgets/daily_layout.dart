import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../utils/date_labels.dart';

class DailyLayoutMetrics {
  // Major app screens (onboarding / theme / calendar / settings) keep their
  // shared title baseline at 30 logical pixels below SafeArea.
  static const double screenTitleTopPadding = 30;

  // The daily prototype is a fixed 360 x 780 composition. After the 28px
  // status area, its 752px content column is laid out exactly as below.
  static const double dailyTopPadding = 20;
  static const double horizontalPadding = 36;
  static const double headerHeight = 46;
  static const double headerToPrompt = 0;
  static const double promptSlotHeight = 52;
  static const double promptToPaper = 12;
  static const double paperMaxWidth = 288;
  static const double paperToNote = 22;
  static const double noteSlotHeight = 104;
  static const double noteToActions = 0;
  static const double actionHeight = 44;
  static const double bottomPadding = 68;

  // Backward-compatible alias for top-level screens that were already using
  // topPadding. Daily screens should use dailyTopPadding explicitly.
  static const double topPadding = screenTitleTopPadding;

  static double paperWidth(
    BuildContext context, {
    double bottomPadding = DailyLayoutMetrics.bottomPadding,
  }) {
    final media = MediaQuery.of(context);
    final widthLimit = math.max(
      0.0,
      media.size.width - horizontalPadding * 2,
    );

    // Prototype paper is 288 x 384. Only shrink it when a device is genuinely
    // narrower than the 360 logical-pixel reference viewport.
    return math.min(paperMaxWidth, widthLimit);
  }
}

class OodHeader extends StatelessWidget {
  const OodHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onForward,
    this.onTitleTap,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback? onTitleTap;

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
            child: GestureDetector(
              onTap: onTitleTap,
              behavior: HitTestBehavior.opaque,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          DailyLayoutMetrics.paperMaxWidth,
          constraints.maxWidth,
        );

        return Center(
          child: SizedBox(
            width: width,
            height: DailyLayoutMetrics.headerHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    drawingDateLabel(date),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: GoogleFonts.gaegu(
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.w400,
                      color: kInk,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onBack,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        '닫기',
                        style: GoogleFonts.gaegu(
                          fontSize: 15,
                          height: 1,
                          fontWeight: FontWeight.w400,
                          color: kSoftInk,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DailyPromptBlock extends StatelessWidget {
  const DailyPromptBlock({
    super.key,
    required this.text,
    this.label,
  });

  final String text;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox(
        height: DailyLayoutMetrics.promptSlotHeight,
      );
    }

    final savedCard = label != null;

    return SizedBox(
      height: DailyLayoutMetrics.promptSlotHeight,
      child: Padding(
        padding: EdgeInsets.only(top: savedCard ? 8 : 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (savedCard) ...[
              Text(
                label!,
                style: GoogleFonts.gaegu(
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                  color: kSoftInk,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              maxLines: savedCard ? 2 : 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.gaegu(
                fontSize: 19,
                height: savedCard ? 1.3 : 1.35,
                fontWeight: FontWeight.w400,
                color: kInk.withAlpha(190),
              ),
            ),
          ],
        ),
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

Future<bool> showOodConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = '취소',
  String confirmLabel = '확인',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: kInk.withAlpha(38),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: kPaper,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.gaegu(
                          fontSize: 22,
                          height: 1.08,
                          fontWeight: FontWeight.w500,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.gaegu(
                          fontSize: 16,
                          height: 1.3,
                          fontWeight: FontWeight.w400,
                          color: kMutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 0.7,
                  color: kSoftInk.withAlpha(82),
                ),
                SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(dialogContext).pop(false),
                          child: Center(
                            child: Text(
                              cancelLabel,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.gaegu(
                                fontSize: 18,
                                height: 1,
                                fontWeight: FontWeight.w400,
                                color: kMutedInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 0.7,
                        color: kSoftInk.withAlpha(70),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(dialogContext).pop(true),
                          child: Center(
                            child: Text(
                              confirmLabel,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.gaegu(
                                fontSize: 18,
                                height: 1,
                                fontWeight: FontWeight.w500,
                                color: kInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  return result ?? false;
}
