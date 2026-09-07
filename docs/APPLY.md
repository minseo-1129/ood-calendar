# Apply it — step by step

Nothing gets deleted. Two existing files get a small edit; everything else is
new.

## 0. Copy the files in

From the unzipped `git-handoff/`, copy into your checkout root:

```
lib/app/boot_gate.dart
lib/content/prompt_themes.dart
lib/data/settings_store.dart
lib/screens/onboarding_screen.dart
lib/screens/theme_picker_screen.dart
lib/screens/settings_screen.dart
lib/widgets/sodam_mark.dart
docs/DESIGN_UPDATES.md
docs/APPLY.md
assets/mark/*.png
```

## 1. `lib/main.dart`

Add two imports and swap `home:`. The whole file after the edit:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/boot_gate.dart';          // ← added
import 'app/theme.dart';
import 'data/entry_store.dart';
import 'data/settings_store.dart';    // ← added

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
      home: BootGate(                 // ← was CalendarScreen(store: EntryStore())
        entryStore: EntryStore(),
        settingsStore: SettingsStore(),
      ),
    );
  }
}
```

`CalendarScreen` is no longer imported here — `BootGate` pushes it. If your
editor flags the unused import, delete that line.

## 2. `lib/widgets/daily_layout.dart`

Give `OodHeader` an optional title tap. Two edits inside the `OodHeader` class.

Constructor and fields — add `onTitleTap`:

```dart
class OodHeader extends StatelessWidget {
  const OodHeader({
    super.key,
    required this.title,
    this.onBack,
    this.onForward,
    this.onTitleTap,          // ← added
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback? onTitleTap;   // ← added
```

Then the middle `Expanded` in `build`. Find:

```dart
          Expanded(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -1),
                child: Text(
```

and wrap the `Center` in a `GestureDetector` — the whole `Expanded` becomes:

```dart
          Expanded(
            child: GestureDetector(
              onTap: onTitleTap,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.gaegu(
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                      color: kInk,
                    ),
                  ),
                ),
              ),
            ),
          ),
```

`onTitleTap: null` (every other caller, e.g. `DailyHeader`) behaves exactly as
before — a null `onTap` means the gesture is ignored.

## 3. `lib/screens/calendar_screen.dart`

Add to the imports:

```dart
import '../data/settings_store.dart';
import 'settings_screen.dart';
```

Find this, inside `Column(children: [`:

```dart
                OodHeader(
                  title: monthLabel(_visibleMonth),
                  onBack: () => _changeMonth(-1),
                  onForward: () => _changeMonth(1),
                ),
```

Replace with:

```dart
                OodHeader(
                  title: monthLabel(_visibleMonth),
                  onBack: () => _changeMonth(-1),
                  onForward: () => _changeMonth(1),
                  onTitleTap: _openSettings,
                ),
```

And add this method to `_CalendarScreenState`, next to `_openDate`:

```dart
  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      quietRoute<void>(
        SettingsScreen(
          entryStore: widget.store,
          settingsStore: SettingsStore(),
        ),
      ),
    );
    if (!mounted) return;
    await _loadMonth();
  }
```

## 4. Prompts (optional, do it in a second commit if you prefer)

Call sites that use `promptForDate(date)` from `content/prompt_provider.dart`
become:

```dart
final settings = await SettingsStore().load();
final prompt = promptForDate(
  date,
  theme: settings.promptTheme,
  ageBand: settings.ageBand,
  tenure: savedEntryCount,
);
```

Until you move them, both files can coexist — `prompt_themes.dart` doesn't
import or shadow `prompt_provider.dart`.

## 5. Run it

```bash
flutter pub get
flutter analyze
flutter run
```

First launch shows: native splash → mark held ~1.1s → 소개 → 질문 테마 →
캘린더. Second launch goes straight to the calendar. Tap the month title for
Settings; 질문 테마 there reopens the picker.

To see onboarding again during testing, either reinstall the app or call
`SettingsStore().resetOnboarding()` once.

## 6. Commit and push

```bash
git checkout -b onboarding-and-themes
git add lib docs assets
git status              # sanity-check: 7 new lib files, 3 modified, docs, assets
git commit -m "Add onboarding, question themes, and settings"
git push -u origin onboarding-and-themes
```

Then open a PR on GitHub (it offers a "Compare & pull request" button right
after the push). Merging to `main` is the last step — nothing before it touches
your existing history.
