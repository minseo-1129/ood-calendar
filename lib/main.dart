import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/boot_gate.dart';
import 'app/theme.dart';
import 'data/entry_store.dart';
import 'data/settings_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/licenses/gaegu/OFL.txt');
    yield LicenseEntryWithLineBreaks(<String>['Gaegu'], license);
  });

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
      home: BootGate(
        entryStore: EntryStore(),
        settingsStore: SettingsStore(),
      ),
    );
  }
}
