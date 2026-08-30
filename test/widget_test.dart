import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sodam/models/doodle_models.dart';
import 'package:sodam/utils/date_labels.dart';

void main() {
  test('DoodleStroke round-trips normalized points', () {
    final stroke = DoodleStroke(
      const <Offset>[
        Offset(0.1, 0.2),
        Offset(0.8, 0.9),
      ],
    );

    final decoded = DoodleStroke.fromJson(stroke.toJson());

    expect(decoded.points.length, 2);
    expect(decoded.points.first.dx, 0.1);
    expect(decoded.points.last.dy, 0.9);
  });

  test('legacy stroke format still loads', () {
    final stroke = DoodleStroke.fromDynamic(
      const <dynamic>[
        <double>[0.2, 0.3],
        <double>[0.7, 0.8],
      ],
    );

    expect(stroke.points.length, 2);
    expect(stroke.points.first, const Offset(0.2, 0.3));
  });

  test('date labels use full month names', () {
    final date = DateTime(2026, 8, 30);
    expect(dateKey(date), '20260830');
    expect(drawingDateLabel(date), 'August 30');
    expect(monthLabel(date), 'August 2026');
  });
}
