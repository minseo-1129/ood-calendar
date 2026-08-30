import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:sodam/main.dart';

void main() {
  test('DoodleStroke keeps normalized points', () {
    final stroke = DoodleStroke(
      const <Offset>[
        Offset(0.1, 0.2),
        Offset(0.8, 0.9),
      ],
    );

    expect(stroke.points.length, 2);
    expect(stroke.points.first.dx, 0.1);
    expect(stroke.points.last.dy, 0.9);
  });
}
