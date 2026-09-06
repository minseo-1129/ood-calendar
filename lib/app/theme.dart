import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kBackground = Color(0xFFF8F5EE);
const Color kPaper = Color(0xFFFFFDF8);
const Color kInk = Color(0xFF203748);
const Color kMutedInk = Color(0xFF7C8888);
const Color kSoftInk = Color(0xFFB9BCB7);
const Color kAccent = Color(0xFF809B92);

ThemeData buildOodTheme() {
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

  return base.copyWith(
    textTheme: GoogleFonts.gaeguTextTheme(base.textTheme).apply(
      bodyColor: kInk,
      displayColor: kInk,
    ),
  );
}
