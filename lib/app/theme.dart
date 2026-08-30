import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kBackground = Color(0xFFF1E9DC);
const Color kPaper = Color(0xFFFBF7ED);
const Color kInk = Color(0xFF173143);
const Color kMutedInk = Color(0xFF7E8B8B);
const Color kSoftInk = Color(0xFFB5B6AE);
const Color kAccent = Color(0xFF7C9A90);

ThemeData buildSodamTheme() {
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
