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
  static const double promptToPaper = 26;
  static const double paperMaxWidth = 288;
  static const double paperToNote = 26;
  static const double noteSlotHeight = 104;
  static const double noteToActions = 8;
  static const double actionHeight = 44;

  static double paperWidth(
    BuildContext context, {
    double bottomPadding = 20,
  }) {
    final media = MediaQuery.of(context);
    final widthLimit = media.size.width - horizontalPadding * 2;

    const verticalSafety = 6.0;
    final safeHeight =
        media.size.height - media.padding.top - media.padding.bottom;
    final fixedVertical = topPadding +
        headerHeight +
        headerToPrompt +
        promptSlotHeight +
        promptToPaper +
        paperToNote +
        noteSlotHeight +
        noteToActions +
        actionHeight +
        bottomPadding +
        verticalSafety;

    final availablePaperHeight = math.max(0.0, safeHeight - fixedVertical);
    final widthFromHeight = availablePaperHeight * 3 / 4;

    return math.min(
      paperMaxWidth,
      math.min(widthLimit, widthFromHeight),
    );
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
                      alignment: Alignment.centerRight,
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

    return SizedBox(
      height: DailyLayoutMetrics.promptSlotHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (label != null) ...[
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
            const SizedBox(height: 5),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.gaegu(
              fontSize: 19,
              height: 1.05,
              fontWeight: FontWeight.w400,
              color: kInk.withAlpha(190),
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
