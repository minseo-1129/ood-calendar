import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'data/entry_store.dart';
import 'screens/calendar_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OodApp());
}

class OodApp extends StatelessWidget {
  const OodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ood',
      theme: buildOodTheme(),
      home: CalendarScreen(store: EntryStore()),
    );
  }
}
