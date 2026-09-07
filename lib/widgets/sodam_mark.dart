// The app mark: a small paper sheet, a tape band, one pencil leaf.
// Drawn rather than shipped as a bitmap so it sits on any background at any
// size. Same curves as assets/mark/*.png — change both together.

import 'package:flutter/material.dart';

import '../app/theme.dart';

class SodamMark extends StatelessWidget {
  const SodamMark({super.key, this.size = 124});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kPaper,
          borderRadius: BorderRadius.circular(size * 0.10),
          border: Border.all(color: kInk.withValues(alpha: 0.07)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: kInk.withValues(alpha: 0.09),
              blurRadius: size * 0.09,
              offset: Offset(0, size * 0.035),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.10),
          child: CustomPaint(painter: _MarkPainter()),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.shortestSide;
    final band = c * 0.19;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, band),
      Paint()..color = const Color(0xFFE7DDC8),
    );

    final slotWidth = c * 0.014;
    final slotHeight = band * 0.30;
    final gap = c * 0.15;
    final slotPaint = Paint()..color = kInk.withValues(alpha: 0.16);
    for (final double side in <double>[-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width / 2 + side * gap / 2 - slotWidth / 2,
            (band - slotHeight) / 2,
            slotWidth,
            slotHeight,
          ),
          Radius.circular(slotWidth),
        ),
        slotPaint,
      );
    }

    final padX = c * 0.17;
    final area = Rect.fromLTWH(
      padX,
      band + c * 0.08,
      size.width - padX * 2,
      size.height - band - c * 0.19,
    );
    final strokeWidth = c * 0.022;

    // faint offset pass first — dry pencil edge
    canvas.save();
    canvas.translate(c * 0.007, -c * 0.006);
    _drawLeaf(canvas, area, strokeWidth, kInk.withValues(alpha: 0.16));
    canvas.restore();

    _drawLeaf(canvas, area, strokeWidth, kInk.withValues(alpha: 0.82));
  }

  void _drawLeaf(Canvas canvas, Rect area, double strokeWidth, Color color) {
    Offset p(double x, double y) =>
        Offset(area.left + x * area.width, area.top + y * area.height);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth;

    final blade = Path()
      ..moveTo(p(0.62, 0.06).dx, p(0.62, 0.06).dy)
      ..cubicTo(p(0.04, 0.26).dx, p(0.04, 0.26).dy, p(0.10, 0.66).dx,
          p(0.10, 0.66).dy, p(0.38, 0.80).dx, p(0.38, 0.80).dy)
      ..cubicTo(p(0.74, 0.66).dx, p(0.74, 0.66).dy, p(0.92, 0.30).dx,
          p(0.92, 0.30).dy, p(0.62, 0.06).dx, p(0.62, 0.06).dy);
    canvas.drawPath(blade, paint);

    final thin = Paint.from(paint)..strokeWidth = strokeWidth * 0.66;

    final vein = Path()
      ..moveTo(p(0.60, 0.10).dx, p(0.60, 0.10).dy)
      ..quadraticBezierTo(p(0.44, 0.50).dx, p(0.44, 0.50).dy, p(0.38, 0.79).dx,
          p(0.38, 0.79).dy);
    canvas.drawPath(vein, thin);

    final stalk = Path()
      ..moveTo(p(0.38, 0.80).dx, p(0.38, 0.80).dy)
      ..quadraticBezierTo(p(0.35, 0.90).dx, p(0.35, 0.90).dy, p(0.30, 0.97).dx,
          p(0.30, 0.97).dy);
    canvas.drawPath(stalk, thin);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
