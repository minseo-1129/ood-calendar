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

  test('date labels are real values', () {
    final date = DateTime(2026, 8, 30);
    expect(dateKey(date), '20260830');
    expect(drawingDateLabel(date), 'AUG 30');
    expect(monthLabel(date), 'August 2026');
  });
}
