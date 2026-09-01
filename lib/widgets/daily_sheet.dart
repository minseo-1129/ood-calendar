import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/doodle_models.dart';

class DailySheet extends StatelessWidget {
  const DailySheet({
    super.key,
    required this.strokes,
    this.currentStroke = const <Offset>[],
    this.strokeWidth = 3.3,
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
            color: kInk.withAlpha(12),
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

class LockedEmptySheet extends StatelessWidget {
  const LockedEmptySheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const DailySheet(
      strokes: <DoodleStroke>[],
    );
  }
}

class DoodleThumbnail extends StatelessWidget {
  const DoodleThumbnail({
    super.key,
    required this.strokes,
    this.width = 38,
    this.height = 50,
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
          strokeWidth: 1.38,
        ),
      ),
    );
  }
}

class EmptyPaperThumbnail extends StatelessWidget {
  const EmptyPaperThumbnail({
    super.key,
    this.width = 34,
    this.height = 45,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const CustomPaint(
        painter: _EmptyPaperPainter(
          borderColor: Color(0x99809B92),
          fillColor: Color(0xCCFFFDF8),
          dashed: true,
        ),
      ),
    );
  }
}

class EmptyDayMark extends StatelessWidget {
  const EmptyDayMark({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 28,
      height: 37,
      child: CustomPaint(
        painter: _EmptyPaperPainter(
          borderColor: Color(0x66B9BCB7),
          fillColor: Color(0x00FFFDF8),
          dashed: false,
        ),
      ),
    );
  }
}

class _EmptyPaperPainter extends CustomPainter {
  const _EmptyPaperPainter({
    required this.borderColor,
    required this.fillColor,
    required this.dashed,
  });

  final Color borderColor;
  final Color fillColor;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.8, 0.8, size.width - 1.6, size.height - 1.6),
      const Radius.circular(2),
    );

    if (fillColor.a > 0) {
      canvas.drawRRect(
        rect,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );
    }

    final path = Path()..addRRect(rect);
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;

    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = math.min(distance + 3.2, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, end),
          paint,
        );
        distance += 6.0;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EmptyPaperPainter oldDelegate) => false;
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
    for (var i = 0; i < strokes.length; i++) {
      _paintStroke(
        canvas,
        size,
        strokes[i].points,
        seed: 17.0 + i * 97.0,
      );
    }

    if (currentStroke.isNotEmpty) {
      _paintStroke(
        canvas,
        size,
        currentStroke,
        seed: 997.0,
      );
    }
  }

  void _paintStroke(
    Canvas canvas,
    Size size,
    List<Offset> normalized, {
    required double seed,
  }) {
    if (normalized.isEmpty) return;

    final rect = _fitThreeByFour(size);
    final raw = normalized
        .map(
          (point) => Offset(
            rect.left + point.dx * rect.width,
            rect.top + point.dy * rect.height,
          ),
        )
        .toList(growable: false);

    if (raw.length == 1) {
      _paintDryDot(canvas, raw.first, seed);
      return;
    }

    final dense = _densify(
      raw,
      math.max(1.8, strokeWidth * 0.72),
    );
    final points = dense;
    if (points.length < 2) return;

    final basePaint = Paint()
      ..color = kInk.withAlpha(132)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.84
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(
      _pathThrough(points),
      basePaint,
    );

    // Several translucent fibres keep the stroke vector/path based while
    // breaking the clean digital edge into a dry pencil/crayon texture.
    for (var pass = 0; pass < 7; pass++) {
      final jittered = <Offset>[];

      for (var i = 0; i < points.length; i++) {
        final a = points[math.max(0, i - 1)];
        final b = points[math.min(points.length - 1, i + 1)];
        var tangent = b - a;
        final length = tangent.distance == 0 ? 1.0 : tangent.distance;
        tangent = Offset(
          tangent.dx / length,
          tangent.dy / length,
        );
        final normal = Offset(-tangent.dy, tangent.dx);

        final n = _noise(seed + pass * 31.7 + i * 0.83);
        final slowWave = math.sin(i * 0.21 + pass * 1.37) * 0.22;
        final offset =
            (n - 0.5 + slowWave) * strokeWidth * (0.62 + pass * 0.025);

        jittered.add(points[i] + normal * offset);
      }

      final alpha =
          (22 + _noise(seed + pass * 8.4) * 26).round().clamp(18, 50);
      final fibreWidth = strokeWidth *
          (0.27 + _noise(seed + pass * 4.9 + 3) * 0.25);

      canvas.drawPath(
        _pathThrough(jittered),
        Paint()
          ..color = kInk.withAlpha(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = fibreWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true,
      );
    }

    // Fine deterministic grain around the centre line. Since the seed is
    // stable, saved doodles render identically every time and at every scale.
    final grainPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (var i = 0; i < points.length; i++) {
      final density = _noise(seed + i * 2.17 + 41);
      if (density < 0.28) continue;

      final a = points[math.max(0, i - 1)];
      final b = points[math.min(points.length - 1, i + 1)];
      var tangent = b - a;
      final length = tangent.distance == 0 ? 1.0 : tangent.distance;
      tangent = Offset(
        tangent.dx / length,
        tangent.dy / length,
      );
      final normal = Offset(-tangent.dy, tangent.dx);

      final lateral =
          (_noise(seed + i * 3.71 + 7) - 0.5) * strokeWidth * 1.5;
      final along = (_noise(seed + i * 5.13 + 19) - 0.5) *
          math.max(1.0, strokeWidth * 0.7);
      final point = points[i] + normal * lateral + tangent * along;

      final radius = strokeWidth *
          (0.045 + _noise(seed + i * 7.91 + 5) * 0.105);
      final alpha =
          (34 + _noise(seed + i * 11.23 + 29) * 72).round().clamp(28, 108);

      grainPaint.color = kInk.withAlpha(alpha);
      canvas.drawCircle(point, radius, grainPaint);

      if (_noise(seed + i * 13.7 + 73) > 0.72) {
        final secondPoint =
            point + normal * ((_noise(seed + i * 17.1) - 0.5) * strokeWidth);
        grainPaint.color = kInk.withAlpha((alpha * 0.58).round());
        canvas.drawCircle(
          secondPoint,
          radius * 0.72,
          grainPaint,
        );
      }
    }
  }

  void _paintDryDot(Canvas canvas, Offset point, double seed) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (var i = 0; i < 18; i++) {
      final angle = _noise(seed + i * 2.7) * math.pi * 2;
      final distance =
          _noise(seed + i * 5.9 + 3) * strokeWidth * 0.72;
      final radius =
          strokeWidth * (0.055 + _noise(seed + i * 7.3 + 9) * 0.12);

      paint.color = kInk.withAlpha(
        (35 + _noise(seed + i * 11.1 + 17) * 90).round(),
      );

      canvas.drawCircle(
        point + Offset(math.cos(angle), math.sin(angle)) * distance,
        radius,
        paint,
      );
    }
  }

  List<Offset> _smoothStrokePoints(List<Offset> points) {
    if (points.length < 3) return points;

    final result = <Offset>[points.first];
    for (var i = 1; i < points.length - 1; i++) {
      result.add(
        Offset(
          (points[i - 1].dx + points[i].dx * 2 + points[i + 1].dx) / 4,
          (points[i - 1].dy + points[i].dy * 2 + points[i + 1].dy) / 4,
        ),
      );
    }
    result.add(points.last);
    return result;
  }

  Path _pathThrough(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 2) {
      path.lineTo(points.last.dx, points.last.dy);
      return path;
    }

    for (var i = 1; i < points.length - 1; i++) {
      final midpoint = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(
        points[i].dx,
        points[i].dy,
        midpoint.dx,
        midpoint.dy,
      );
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
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
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFFFEFA),
          Color(0xFFFBF7EE),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    final fiberPaint = Paint()
      ..color = const Color(0xFF9B8F7A).withAlpha(10)
      ..strokeWidth = 0.45
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 54; i++) {
      final x = _noise(i * 1.71 + 3) * size.width;
      final y = _noise(i * 2.43 + 11) * size.height;
      final length = 3 + _noise(i * 3.17 + 17) * 9;
      final angle = (_noise(i * 4.19 + 23) - 0.5) * 0.4;
      final delta = Offset(math.cos(angle), math.sin(angle)) * length;

      canvas.drawLine(
        Offset(x, y),
        Offset(x, y) + delta,
        fiberPaint,
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
    const amount = 1.0;
    final path = Path();

    path.moveTo(2, 1.5);

    for (double x = 2; x <= size.width - 2; x += step) {
      final y = amount * math.sin(x * 0.10) +
          0.4 * math.sin(x * 0.31 + 0.8);
      path.lineTo(x, y + 1.6);
    }

    for (double y = 2; y <= size.height - 2; y += step) {
      final x = size.width -
          1.6 -
          amount * math.sin(y * 0.11 + 1.2) -
          0.4 * math.sin(y * 0.34);
      path.lineTo(x, y);
    }

    for (double x = size.width - 2; x >= 2; x -= step) {
      final y = size.height -
          1.6 -
          amount * math.sin(x * 0.08 + 2.1) -
          0.4 * math.sin(x * 0.28);
      path.lineTo(x, y);
    }

    for (double y = size.height - 2; y >= 2; y -= step) {
      final x = amount * math.sin(y * 0.10 + 0.4) +
          0.4 * math.sin(y * 0.29 + 1.7) +
          1.6;
      path.lineTo(x, y);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
