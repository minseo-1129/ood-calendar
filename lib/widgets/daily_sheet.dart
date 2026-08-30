import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/doodle_models.dart';

class DailySheet extends StatelessWidget {
  const DailySheet({
    super.key,
    required this.strokes,
    this.currentStroke = const <Offset>[],
    this.strokeWidth = 3.0,
  });

  final List<DoodleStroke> strokes;
  final List<Offset> currentStroke;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: kInk.withAlpha(14),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipPath(
        clipper: const _DeckleClipper(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _PaperTexturePainter()),
            CustomPaint(
              painter: DoodlePainter(
                strokes: strokes,
                currentStroke: currentStroke,
                strokeWidth: strokeWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoodleThumbnail extends StatelessWidget {
  const DoodleThumbnail({
    super.key,
    required this.strokes,
    this.width = 42,
    this.height = 56,
  });

  final List<DoodleStroke> strokes;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: DoodlePainter(
          strokes: strokes,
          currentStroke: const <Offset>[],
          strokeWidth: 1.35,
        ),
      ),
    );
  }
}

class DoodlePainter extends CustomPainter {
  DoodlePainter({
    required this.strokes,
    required this.currentStroke,
    required this.strokeWidth,
  });

  final List<DoodleStroke> strokes;
  final List<Offset> currentStroke;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kInk
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (final stroke in strokes) {
      _paintStroke(canvas, size, paint, stroke.points);
    }

    if (currentStroke.isNotEmpty) {
      _paintStroke(canvas, size, paint, currentStroke);
    }
  }

  void _paintStroke(
    Canvas canvas,
    Size size,
    Paint paint,
    List<Offset> normalized,
  ) {
    if (normalized.isEmpty) return;

    final rect = _fitThreeByFour(size);
    final points = normalized
        .map(
          (point) => Offset(
            rect.left + point.dx * rect.width,
            rect.top + point.dy * rect.height,
          ),
        )
        .toList(growable: false);

    if (points.length == 1) {
      canvas.drawCircle(points.first, strokeWidth * 0.45, paint);
      return;
    }

    canvas.drawPath(
      _roughBrushPath(points, strokeWidth * 0.52),
      paint,
    );
  }

  Rect _fitThreeByFour(Size size) {
    const sourceAspect = 3 / 4;

    if (size.width / size.height > sourceAspect) {
      final height = size.height;
      final width = height * sourceAspect;
      return Rect.fromLTWH(
        (size.width - width) / 2,
        0,
        width,
        height,
      );
    }

    final width = size.width;
    final height = width / sourceAspect;
    return Rect.fromLTWH(
      0,
      (size.height - height) / 2,
      width,
      height,
    );
  }

  @override
  bool shouldRepaint(covariant DoodlePainter oldDelegate) => true;
}

Path _roughBrushPath(List<Offset> raw, double halfWidth) {
  final points = _densify(raw, 4.0);
  if (points.length < 2) return Path();

  final count = points.length;
  final arcLength = List<double>.filled(count, 0);

  for (var i = 1; i < count; i++) {
    arcLength[i] = arcLength[i - 1] + (points[i] - points[i - 1]).distance;
  }

  final total = arcLength.last == 0 ? 1.0 : arcLength.last;
  final taperLength = math.min(9.0, total * 0.4);

  final smoothed = <Offset>[];
  for (var i = 0; i < count; i++) {
    if (i == 0 || i == count - 1) {
      smoothed.add(points[i]);
    } else {
      smoothed.add(
        Offset(
          (points[i - 1].dx + 2 * points[i].dx + points[i + 1].dx) / 4,
          (points[i - 1].dy + 2 * points[i].dy + points[i + 1].dy) / 4,
        ),
      );
    }
  }

  final left = <Offset>[];
  final right = <Offset>[];

  for (var i = 0; i < count; i++) {
    final a = smoothed[math.max(0, i - 1)];
    final b = smoothed[math.min(count - 1, i + 1)];
    var tangent = b - a;
    final tangentLength = tangent.distance == 0 ? 1.0 : tangent.distance;
    tangent = Offset(
      tangent.dx / tangentLength,
      tangent.dy / tangentLength,
    );

    final fromStart =
        math.min(1.0, arcLength[i] / math.max(0.001, taperLength));
    final fromEnd =
        math.min(1.0, (total - arcLength[i]) / math.max(0.001, taperLength));
    final taper = math.pow(fromStart, 0.55).toDouble() *
        math.pow(fromEnd, 0.55).toDouble();

    final speed = 1 / (1 + tangentLength * 0.09);
    final wobble = 1 +
        0.12 * math.sin(arcLength[i] * 0.22) +
        0.06 * math.sin(arcLength[i] * 0.51 + 1.1);

    var width = halfWidth *
        (0.3 + 0.7 * taper) *
        (0.82 + 0.36 * speed) *
        wobble;

    width *= 1.16 +
        0.30 * (_noise(arcLength[i] * 0.7) - 0.5) +
        0.16 * (_noise(arcLength[i] * 2.9 + 7) - 0.5);

    final leftJitter =
        (_noise(arcLength[i] * 4.1 + 13) - 0.5) * halfWidth * 0.62;
    final rightJitter =
        (_noise(arcLength[i] * 3.7 + 29) - 0.5) * halfWidth * 0.62;

    final normal = Offset(-tangent.dy, tangent.dx);
    left.add(smoothed[i] + normal * (width + leftJitter));
    right.add(smoothed[i] - normal * (width + rightJitter));
  }

  final path = Path()..moveTo(left.first.dx, left.first.dy);

  for (var i = 1; i < left.length; i++) {
    path.lineTo(left[i].dx, left[i].dy);
  }

  for (final point in right.reversed) {
    path.lineTo(point.dx, point.dy);
  }

  path.close();
  return path;
}

List<Offset> _densify(List<Offset> points, double step) {
  if (points.isEmpty) return const <Offset>[];

  final result = <Offset>[points.first];

  for (var i = 1; i < points.length; i++) {
    final a = result.last;
    final b = points[i];
    final distance = (b - a).distance;
    final pieces = math.max(1, (distance / step).ceil());

    for (var j = 1; j <= pieces; j++) {
      result.add(Offset.lerp(a, b, j / pieces)!);
    }
  }

  return result;
}

double _noise(double value) {
  final raw = math.sin(value * 12.9898) * 43758.5453;
  return raw - raw.floorToDouble();
}

class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = kPaper,
    );

    final fiberPaint = Paint()
      ..color = const Color(0xFF9B8F7A).withAlpha(12)
      ..strokeWidth = 0.45
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 58; i++) {
      final x = _noise(i * 1.71 + 3) * size.width;
      final y = _noise(i * 2.43 + 11) * size.height;
      final length = 3 + _noise(i * 3.17 + 17) * 10;
      final angle = (_noise(i * 4.19 + 23) - 0.5) * 0.42;
      final delta = Offset(math.cos(angle), math.sin(angle)) * length;

      canvas.drawLine(
        Offset(x, y),
        Offset(x, y) + delta,
        fiberPaint,
      );
    }

    final speckPaint = Paint()
      ..color = const Color(0xFFB6A992).withAlpha(8);

    for (var i = 0; i < 42; i++) {
      final x = _noise(i * 2.11 + 31) * size.width;
      final y = _noise(i * 4.07 + 19) * size.height;
      canvas.drawCircle(
        Offset(x, y),
        0.35 + _noise(i * 3.31 + 5) * 0.5,
        speckPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DeckleClipper extends CustomClipper<Path> {
  const _DeckleClipper();

  @override
  Path getClip(Size size) {
    const step = 18.0;
    const amount = 1.1;
    final path = Path();

    path.moveTo(2, 1.5);

    for (double x = 2; x <= size.width - 2; x += step) {
      final y = amount * math.sin(x * 0.10) +
          0.45 * math.sin(x * 0.31 + 0.8);
      path.lineTo(x, y + 1.6);
    }

    for (double y = 2; y <= size.height - 2; y += step) {
      final x = size.width -
          1.6 -
          amount * math.sin(y * 0.11 + 1.2) -
          0.45 * math.sin(y * 0.34);
      path.lineTo(x, y);
    }

    for (double x = size.width - 2; x >= 2; x -= step) {
      final y = size.height -
          1.6 -
          amount * math.sin(x * 0.08 + 2.1) -
          0.45 * math.sin(x * 0.28);
      path.lineTo(x, y);
    }

    for (double y = size.height - 2; y >= 2; y -= step) {
      final x = amount * math.sin(y * 0.10 + 0.4) +
          0.45 * math.sin(y * 0.29 + 1.7) +
          1.6;
      path.lineTo(x, y);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
