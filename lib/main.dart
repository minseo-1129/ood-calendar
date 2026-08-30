import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'data/entry_store.dart';
import 'screens/calendar_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SodamApp());
}

class SodamApp extends StatelessWidget {
  const SodamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'sodam',
      theme: buildSodamTheme(),
      home: CalendarScreen(store: EntryStore()),
    );
  }
}
