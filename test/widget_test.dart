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

  test('legacy entries without prompt still load', () {
    final entry = DoodleEntry.fromJson(
      <String, dynamic>{
        'dateKey': '20260831',
        'strokes': const <dynamic>[],
        'note': '',
        'createdAt': '2026-08-31T00:00:00.000',
        'updatedAt': '2026-08-31T00:00:00.000',
      },
    );

    expect(entry.prompt, '');
  });

  test('date labels use full month names', () {
    final date = DateTime(2026, 8, 31);
    expect(dateKey(date), '20260831');
    expect(drawingDateLabel(date), 'August 31');
    expect(monthLabel(date), 'August 2026');
  });
}
