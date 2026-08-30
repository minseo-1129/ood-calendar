import 'package:flutter/material.dart';

Route<T> quietRoute<T>(Widget child) {
  return PageRouteBuilder<T>(
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: (_, __, ___, page) => page,
  );
}
