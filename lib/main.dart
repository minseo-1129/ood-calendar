import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kBackground = Color(0xFFF1E9DC);
const Color kPaper = Color(0xFFFFFCF5);
const Color kInk = Color(0xFF173143);
const Color kMutedInk = Color(0xFF7E8B8B);
const Color kSoftInk = Color(0xFFB5B6AE);
const Color kAccent = Color(0xFF7C9A90);

void main() {
  runApp(const SodamApp());
}

class SodamApp extends StatelessWidget {
  const SodamApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: kBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kAccent,
        brightness: Brightness.light,
        surface: kPaper,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'sodam',
      theme: base.copyWith(
        textTheme: GoogleFonts.gaeguTextTheme(base.textTheme).apply(
          bodyColor: kInk,
          displayColor: kInk,
        ),
      ),
      home: CalendarScreen(store: EntryStore()),
    );
  }
}

class DoodleStroke {
  DoodleStroke(List<Offset> points) : points = List.unmodifiable(points);

  final List<Offset> points;
}

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<DoodleStroke> _strokes = <DoodleStroke>[];
  List<Offset> _currentStroke = <Offset>[];
  Offset? _lastLocalPoint;

  bool get _canUndo => _strokes.isNotEmpty;
  bool get _canFinish => _strokes.isNotEmpty;

  void _startStroke(PointerDownEvent event, Size size) {
    setState(() {
      _lastLocalPoint = event.localPosition;
      _currentStroke = <Offset>[_normalize(event.localPosition, size)];
    });
  }

  void _continueStroke(PointerMoveEvent event, Size size) {
    final previous = _lastLocalPoint;
    if (previous != null && (event.localPosition - previous).distance < 1.8) {
      return;
    }

    setState(() {
      _lastLocalPoint = event.localPosition;
      _currentStroke = <Offset>[
        ..._currentStroke,
        _normalize(event.localPosition, size),
      ];
    });
  }

  void _finishStroke() {
    if (_currentStroke.isEmpty) return;

    setState(() {
      _strokes.add(DoodleStroke(_currentStroke));
      _currentStroke = <Offset>[];
      _lastLocalPoint = null;
    });
  }

  Offset _normalize(Offset point, Size size) {
    return Offset(point.dx / size.width, point.dy / size.height);
  }

  void _undo() {
    if (!_canUndo) return;
    setState(_strokes.removeLast);
  }

  void _done() {
    if (!_canFinish) return;

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) {
          return CardScreen(strokes: List<DoodleStroke>.of(_strokes));
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dateLabel(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: Column(
            children: [
              Text(
                dateLabel,
                style: GoogleFonts.gaegu(
                  fontSize: 29,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '오늘 이상하게 기억나는 것 하나',
                textAlign: TextAlign.center,
                style: GoogleFonts.gaegu(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: kMutedInk,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final widthByHeight = constraints.maxHeight * 3 / 4;
                      final sheetWidth = math.min(
                        324.0,
                        math.min(constraints.maxWidth, widthByHeight),
                      );
                      final sheetSize = Size(sheetWidth, sheetWidth * 4 / 3);

                      return Hero(
                        tag: 'today-daily-sheet',
                        child: SizedBox(
                          width: sheetSize.width,
                          height: sheetSize.height,
                          child: Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (event) => _startStroke(event, sheetSize),
                            onPointerMove: (event) =>
                                _continueStroke(event, sheetSize),
                            onPointerUp: (_) => _finishStroke(),
                            onPointerCancel: (_) => _finishStroke(),
                            child: DailySheet(
                              strokes: _strokes,
                              currentStroke: _currentStroke,
                              strokeWidth: 3.0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _QuietAction(
                    label: '↶  Undo',
                    enabled: _canUndo,
                    onTap: _undo,
                  ),
                  const Spacer(),
                  _QuietAction(
                    label: 'Done',
                    enabled: _canFinish,
                    onTap: _done,
                    strong: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardScreen extends StatefulWidget {
  const CardScreen({super.key, required this.strokes});

  final List<DoodleStroke> strokes;

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dateLabel(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        dateLabel,
                        style: GoogleFonts.gaegu(
                          fontSize: 29,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2,
                          color: kInk,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: kMutedInk,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: Text(
                          '수정',
                          style: GoogleFonts.gaegu(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final widthByHeight = constraints.maxHeight * 3 / 4;
                      final sheetWidth = math.min(
                        310.0,
                        math.min(constraints.maxWidth, widthByHeight),
                      );

                      return Hero(
                        tag: 'today-daily-sheet',
                        child: SizedBox(
                          width: sheetWidth,
                          height: sheetWidth * 4 / 3,
                          child: DailySheet(
                            strokes: widget.strokes,
                            strokeWidth: 3.0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _noteController,
                maxLines: 1,
                maxLength: 60,
                textAlign: TextAlign.center,
                style: GoogleFonts.gaegu(
                  fontSize: 20,
                  color: kMutedInk,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '한 줄 (선택)',
                  hintStyle: GoogleFonts.gaegu(
                    fontSize: 20,
                    color: kSoftInk,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '오늘은 다시 열어 수정할 수 있어요',
                style: GoogleFonts.gaegu(
                  fontSize: 15,
                  color: kSoftInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            color: kInk.withAlpha(20),
            blurRadius: 28,
            offset: const Offset(0, 14),
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

    final points = normalized
        .map((point) => Offset(
              point.dx * size.width,
              point.dy * size.height,
            ))
        .toList(growable: false);

    if (points.length == 1) {
      canvas.drawCircle(points.first, strokeWidth * 0.45, paint);
      return;
    }

    final path = _roughBrushPath(points, strokeWidth * 0.52);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant DoodlePainter oldDelegate) {
    return true;
  }
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

    final fromStart = taperLength == 0
        ? 1.0
        : math.min(1.0, arcLength[i] / taperLength);
    final fromEnd = taperLength == 0
        ? 1.0
        : math.min(1.0, (total - arcLength[i]) / taperLength);
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
      ..color = const Color(0xFF9B8F7A).withAlpha(14)
      ..strokeWidth = 0.55
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 72; i++) {
      final x = _noise(i * 1.71 + 3) * size.width;
      final y = _noise(i * 2.43 + 11) * size.height;
      final length = 4 + _noise(i * 3.17 + 17) * 13;
      final angle = (_noise(i * 4.19 + 23) - 0.5) * 0.5;
      final delta = Offset(math.cos(angle), math.sin(angle)) * length;
      canvas.drawLine(Offset(x, y), Offset(x, y) + delta, fiberPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DeckleClipper extends CustomClipper<Path> {
  const _DeckleClipper();

  @override
  Path getClip(Size size) {
    const step = 12.0;
    const amount = 1.7;
    final path = Path();

    path.moveTo(2, 0);

    for (double x = 2; x <= size.width - 2; x += step) {
      final y = amount * math.sin(x * 0.11) +
          0.7 * math.sin(x * 0.37 + 0.8);
      path.lineTo(x, y + 1.8);
    }

    for (double y = 2; y <= size.height - 2; y += step) {
      final x = size.width -
          1.8 -
          amount * math.sin(y * 0.13 + 1.2) -
          0.6 * math.sin(y * 0.41);
      path.lineTo(x, y);
    }

    for (double x = size.width - 2; x >= 2; x -= step) {
      final y = size.height -
          1.8 -
          amount * math.sin(x * 0.09 + 2.1) -
          0.6 * math.sin(x * 0.31);
      path.lineTo(x, y);
    }

    for (double y = size.height - 2; y >= 2; y -= step) {
      final x = amount * math.sin(y * 0.12 + 0.4) +
          0.6 * math.sin(y * 0.33 + 1.7) +
          1.8;
      path.lineTo(x, y);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _QuietAction extends StatelessWidget {
  const _QuietAction({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.strong = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? (strong ? kInk : kMutedInk)
        : kSoftInk.withAlpha(150);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(
          label,
          style: GoogleFonts.gaegu(
            fontSize: 19,
            fontWeight: strong ? FontWeight.w400 : FontWeight.w300,
            letterSpacing: 0.6,
            color: color,
          ),
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  const months = <String>[
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return months[date.month - 1] + ' ' + date.day.toString();
}


class DoodleEntry {
  const DoodleEntry({
    required this.dateKey,
    required this.strokes,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String dateKey;
  final List<DoodleStroke> strokes;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  DoodleEntry copyWith({
    List<DoodleStroke>? strokes,
    String? note,
    DateTime? updatedAt,
  }) {
    return DoodleEntry(
      dateKey: dateKey,
      strokes: strokes ?? this.strokes,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dateKey': dateKey,
      'strokes': strokes
          .map(
            (stroke) => stroke.points
                .map((point) => <double>[point.dx, point.dy])
                .toList(growable: false),
          )
          .toList(growable: false),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DoodleEntry.fromJson(Map<String, dynamic> json) {
    final rawStrokes =
        json['strokes'] as List<dynamic>? ?? const <dynamic>[];

    return DoodleEntry(
      dateKey: json['dateKey'] as String,
      strokes: rawStrokes.map((rawStroke) {
        final rawPoints = rawStroke as List<dynamic>;
        return DoodleStroke(
          rawPoints.map((rawPoint) {
            final pair = rawPoint as List<dynamic>;
            return Offset(
              (pair[0] as num).toDouble(),
              (pair[1] as num).toDouble(),
            );
          }).toList(growable: false),
        );
      }).toList(growable: false),
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class EntryStore {
  static const _storageKey = 'sodam.entries.v1';

  Future<Map<String, DoodleEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <String, DoodleEntry>{};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        DoodleEntry.fromJson(Map<String, dynamic>.from(value as Map)),
      ),
    );
  }

  Future<Map<String, DoodleEntry>> loadMonth(DateTime month) async {
    final all = await loadAll();
    final prefix = _monthKey(month);
    return Map<String, DoodleEntry>.fromEntries(
      all.entries.where((entry) => entry.key.startsWith(prefix)),
    );
  }

  Future<void> save(DoodleEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    all[entry.dateKey] = entry;
    await prefs.setString(
      _storageKey,
      jsonEncode(
        all.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.store});

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
    final entry = _entries[_dateKey(date)];
    final today = DateTime.now();

    if (entry == null) {
      if (!_sameDay(date, today)) return;

      final created = await Navigator.of(context).push<DoodleEntry>(
        MaterialPageRoute(
          builder: (_) => SavedDrawingScreen(
            store: widget.store,
            date: date,
          ),
        ),
      );
      if (created == null || !mounted) return;

      await _loadMonth();
      if (!mounted) return;

      await Navigator.of(context).push<DoodleEntry>(
        MaterialPageRoute(
          builder: (_) => SavedCardScreen(
            store: widget.store,
            entry: created,
          ),
        ),
      );
      await _loadMonth();
      return;
    }

    await Navigator.of(context).push<DoodleEntry>(
      MaterialPageRoute(
        builder: (_) => SavedCardScreen(
          store: widget.store,
          entry: entry,
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
                          _monthLabel(_visibleMonth),
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
                Row(
                  children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map(
                        (day) => Expanded(
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _loading ? 0.45 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final first = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month,
                          1,
                        );
                        final daysInMonth = DateTime(
                          _visibleMonth.year,
                          _visibleMonth.month + 1,
                          0,
                        ).day;
                        final leading = first.weekday - DateTime.monday;
                        final cellHeight = constraints.maxHeight / 6;

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 42,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisExtent: cellHeight,
                          ),
                          itemBuilder: (context, index) {
                            final dayNumber = index - leading + 1;
                            if (dayNumber < 1 || dayNumber > daysInMonth) {
                              return const SizedBox.shrink();
                            }

                            final date = DateTime(
                              _visibleMonth.year,
                              _visibleMonth.month,
                              dayNumber,
                            );
                            final entry = _entries[_dateKey(date)];
                            final isToday = _sameDay(date, today);

                            return _CalendarDay(
                              date: date,
                              entry: entry,
                              isToday: isToday,
                              onTap: () => _openDate(date),
                            );
                          },
                        );
                      },
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
  const _MonthArrow({required this.label, required this.onTap});

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

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
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
              '\${date.day}',
              style: GoogleFonts.gaegu(
                fontSize: 16,
                fontWeight: isToday ? FontWeight.w400 : FontWeight.w300,
                color: isToday ? kInk : kMutedInk,
              ),
            ),
            const SizedBox(height: 1),
            Expanded(
              child: entry != null
                  ? Padding(
                      padding: const EdgeInsets.all(3),
                      child: CustomPaint(
                        painter: DoodlePainter(
                          strokes: entry!.strokes,
                          currentStroke: const <Offset>[],
                          strokeWidth: 1.25,
                        ),
                      ),
                    )
                  : isToday
                      ? Center(
                          child: Text(
                            '+',
                            style: GoogleFonts.gaegu(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: kMutedInk,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class SavedDrawingScreen extends StatefulWidget {
  const SavedDrawingScreen({
    super.key,
    required this.store,
    required this.date,
    this.initialEntry,
  });

  final EntryStore store;
  final DateTime date;
  final DoodleEntry? initialEntry;

  @override
  State<SavedDrawingScreen> createState() => _SavedDrawingScreenState();
}

class _SavedDrawingScreenState extends State<SavedDrawingScreen> {
  late final List<DoodleStroke> _strokes;
  List<Offset> _currentStroke = <Offset>[];
  Offset? _lastLocalPoint;

  bool get _canUndo => _strokes.isNotEmpty;
  bool get _canFinish => _strokes.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _strokes = List<DoodleStroke>.of(
      widget.initialEntry?.strokes ?? const <DoodleStroke>[],
    );
  }

  void _startStroke(PointerDownEvent event, Size size) {
    setState(() {
      _lastLocalPoint = event.localPosition;
      _currentStroke = <Offset>[
        _normalizePoint(event.localPosition, size),
      ];
    });
  }

  void _continueStroke(PointerMoveEvent event, Size size) {
    final previous = _lastLocalPoint;
    if (previous != null &&
        (event.localPosition - previous).distance < 1.8) {
      return;
    }

    setState(() {
      _lastLocalPoint = event.localPosition;
      _currentStroke = <Offset>[
        ..._currentStroke,
        _normalizePoint(event.localPosition, size),
      ];
    });
  }

  void _finishStroke() {
    if (_currentStroke.isEmpty) return;
    setState(() {
      _strokes.add(DoodleStroke(_currentStroke));
      _currentStroke = <Offset>[];
      _lastLocalPoint = null;
    });
  }

  Offset _normalizePoint(Offset point, Size size) {
    return Offset(
      (point.dx / size.width).clamp(0.0, 1.0),
      (point.dy / size.height).clamp(0.0, 1.0),
    );
  }

  void _undo() {
    if (!_canUndo) return;
    setState(_strokes.removeLast);
  }

  Future<void> _done() async {
    if (!_canFinish) return;

    final now = DateTime.now();
    final entry = DoodleEntry(
      dateKey: _dateKey(widget.date),
      strokes: List<DoodleStroke>.of(_strokes),
      note: widget.initialEntry?.note ?? '',
      createdAt: widget.initialEntry?.createdAt ?? now,
      updatedAt: now,
    );
    await widget.store.save(entry);

    if (!mounted) return;
    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: Column(
            children: [
              SizedBox(
                height: 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        _drawingDateLabel(widget.date),
                        style: GoogleFonts.gaegu(
                          fontSize: 29,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2,
                          color: kInk,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '‹',
                            style: GoogleFonts.gaegu(
                              fontSize: 28,
                              color: kMutedInk,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '오늘 이상하게 기억나는 것 하나',
                textAlign: TextAlign.center,
                style: GoogleFonts.gaegu(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  color: kMutedInk,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final widthByHeight = constraints.maxHeight * 3 / 4;
                      final sheetWidth = math.min(
                        324.0,
                        math.min(constraints.maxWidth, widthByHeight),
                      );
                      final sheetSize =
                          Size(sheetWidth, sheetWidth * 4 / 3);

                      return SizedBox(
                        width: sheetSize.width,
                        height: sheetSize.height,
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (event) =>
                              _startStroke(event, sheetSize),
                          onPointerMove: (event) =>
                              _continueStroke(event, sheetSize),
                          onPointerUp: (_) => _finishStroke(),
                          onPointerCancel: (_) => _finishStroke(),
                          child: DailySheet(
                            strokes: _strokes,
                            currentStroke: _currentStroke,
                            strokeWidth: 3.0,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _QuietAction(
                    label: '↶  Undo',
                    enabled: _canUndo,
                    onTap: _undo,
                  ),
                  const Spacer(),
                  _QuietAction(
                    label: 'Done',
                    enabled: _canFinish,
                    onTap: _done,
                    strong: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedCardScreen extends StatefulWidget {
  const SavedCardScreen({
    super.key,
    required this.store,
    required this.entry,
  });

  final EntryStore store;
  final DoodleEntry entry;

  @override
  State<SavedCardScreen> createState() => _SavedCardScreenState();
}

class _SavedCardScreenState extends State<SavedCardScreen> {
  late DoodleEntry _entry;
  late final TextEditingController _noteController;

  bool get _editable =>
      _sameDay(_dateFromKey(_entry.dateKey), DateTime.now());

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _noteController = TextEditingController(text: _entry.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    if (!_editable) return;

    final updated = await Navigator.of(context).push<DoodleEntry>(
      MaterialPageRoute(
        builder: (_) => SavedDrawingScreen(
          store: widget.store,
          date: _dateFromKey(_entry.dateKey),
          initialEntry: _entry,
        ),
      ),
    );

    if (updated == null || !mounted) return;
    setState(() {
      _entry = updated;
      _noteController.text = updated.note;
    });
  }

  Future<void> _saveNote(String value) async {
    if (!_editable) return;
    final updated = _entry.copyWith(
      note: value,
      updatedAt: DateTime.now(),
    );
    _entry = updated;
    await widget.store.save(updated);
  }

  @override
  Widget build(BuildContext context) {
    final date = _dateFromKey(_entry.dateKey);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(_entry),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '‹',
                            style: GoogleFonts.gaegu(
                              fontSize: 28,
                              color: kMutedInk,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        _drawingDateLabel(date),
                        style: GoogleFonts.gaegu(
                          fontSize: 29,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2,
                          color: kInk,
                        ),
                      ),
                    ),
                    if (_editable)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _edit,
                          style: TextButton.styleFrom(
                            foregroundColor: kMutedInk,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: Text(
                            '수정',
                            style: GoogleFonts.gaegu(fontSize: 18),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final widthByHeight = constraints.maxHeight * 3 / 4;
                      final sheetWidth = math.min(
                        310.0,
                        math.min(constraints.maxWidth, widthByHeight),
                      );

                      return SizedBox(
                        width: sheetWidth,
                        height: sheetWidth * 4 / 3,
                        child: DailySheet(
                          strokes: _entry.strokes,
                          strokeWidth: 3.0,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_editable)
                TextField(
                  controller: _noteController,
                  maxLines: 1,
                  maxLength: 60,
                  textAlign: TextAlign.center,
                  onChanged: _saveNote,
                  style: GoogleFonts.gaegu(
                    fontSize: 20,
                    color: kMutedInk,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '한 줄 (선택)',
                    hintStyle: GoogleFonts.gaegu(
                      fontSize: 20,
                      color: kSoftInk,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                )
              else if (_entry.note.isNotEmpty)
                Text(
                  _entry.note,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.gaegu(
                    fontSize: 20,
                    color: kMutedInk,
                  ),
                ),
              const SizedBox(height: 2),
              if (_editable)
                Text(
                  '오늘은 다시 열어 수정할 수 있어요',
                  style: GoogleFonts.gaegu(
                    fontSize: 15,
                    color: kSoftInk,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _dateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year$month$day';
}

String _monthKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$year$month';
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime _dateFromKey(String key) {
  return DateTime(
    int.parse(key.substring(0, 4)),
    int.parse(key.substring(4, 6)),
    int.parse(key.substring(6, 8)),
  );
}

String _drawingDateLabel(DateTime date) {
  const months = <String>[
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return '\${months[date.month - 1]} \${date.day}';
}

String _monthLabel(DateTime date) {
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '\${months[date.month - 1]} \${date.year}';
}
