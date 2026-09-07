# Design updates — onboarding, question themes, settings

Only what changed relative to `main`. Colors and type come from
`lib/app/theme.dart` and `docs/VISUAL_GRAMMAR.md`; nothing here introduces a
new token.

## New files

| File | What it is |
| --- | --- |
| `lib/content/prompt_themes.dart` | Theme-aware prompt pools. Replaces `content/prompt_provider.dart`. |
| `lib/data/settings_store.dart` | `onboarded`, `promptTheme`, `ageBand` in SharedPreferences, separate from `EntryStore`. |
| `lib/app/boot_gate.dart` | Splash hold → onboarding or calendar. |
| `lib/screens/onboarding_screen.dart` | One page of copy. |
| `lib/screens/theme_picker_screen.dart` | Question-theme axis picker (onboarding step 2 + Settings). |
| `lib/screens/settings_screen.dart` | Question theme, notifications, storage, version. |
| `lib/widgets/sodam_mark.dart` | The app mark, drawn (paper + tape + pencil leaf). |

## Modified files

| File | Change |
| --- | --- |
| `lib/main.dart` | `home:` → `BootGate`. |
| `lib/widgets/daily_layout.dart` | `OodHeader` gains an optional `onTitleTap`. |
| `lib/screens/calendar_screen.dart` | Month title opens Settings. |

## Wiring

Step-by-step copy-paste version: `docs/APPLY.md`.

`main.dart` — swap the home for the gate:

```dart
home: BootGate(
  entryStore: EntryStore(),
  settingsStore: SettingsStore(),
),
```

`calendar_screen.dart` — the month title is the settings entry point. Add an
optional `onTitleTap` to `OodHeader` in `lib/widgets/daily_layout.dart`, then:

```dart
OodHeader(
  title: monthLabel(_visibleMonth),
  onBack: () => _changeMonth(-1),
  onForward: () => _changeMonth(1),
  onTitleTap: _openSettings,
)
```

Prompt call sites move from `promptForDate(date)` to:

```dart
promptForDate(date, theme: settings.promptTheme, ageBand: settings.ageBand, tenure: savedCount)
```

`prompt_provider.dart` can be deleted once call sites move; keep a one-line
shim if you'd rather not touch them in the same commit.

## Mark artwork

`assets/mark/` holds the source PNGs, all drawn from the same curves as
`SodamMark`:

| File | Use |
| --- | --- |
| `mark-1024.png` | transparent, mark only — general source |
| `app-icon-1024.png` / `app-icon-512.png` | launcher / Play Store, ivory ground |
| `app-icon-maskable-1024.png` | extra safe-area padding for adaptive + web maskable |
| `splash-mark-1024.png` | transparent, sized for `drawable-*/splash_mark.png` |

These are reference sources, not drop-in replacements: regenerate the per-density
`mipmap-*` and `drawable-*` files from them so the launcher icon and splash mark
finally come from one artwork.

## Splash

The native splash already exists (`drawable/launch_background.xml` →
`@color/ood_background` + `splash_mark.png` at five densities). `BootGate`
holds the same mark for 1100 ms so the native → Flutter handoff has no flash.
If the launcher icon and `splash_mark.png` are meant to be the same artwork,
regenerate both from one source — right now they don't match the drawn
`SodamMark`.

## Flow

```
native splash → BootGate (1.1s)
  ├─ onboarded → CalendarScreen
  └─ first run → OnboardingScreen → ThemePickerScreen → CalendarScreen
CalendarScreen → (month title tap) → SettingsScreen → ThemePickerScreen (pops back)
```

## Question themes

Five axes: 계절과 날씨 (default), 나이대, 기분과 감정, 사물 하나 정하기,
전부 섞기. Choosing 사물 reveals six object chips (구름 / 꽃 / 컵 / 창 / 걸음
/ 빛) and stores as `object:<id>`. One axis at a time.

The question is a pure function of `(theme, date, swap)`, so a day always
reopens with the same question. Saved entries keep their own prompt string, so
changing the theme later never rewrites history.

## Dimensions

- Page padding 36, calendar page padding 18.
- Screen title 28 / height 1, body 19 / height 1.5, detail 12.
- Selection dot 5×5 in `kAccent`; object chip radius 999, padding 14×5.
- Tap targets 44 min (`quietButtonStyle`).
- Back affordance is the word 닫기 at 15 in `kSoftInk`, right-aligned on the
  title baseline — the large date/title stays pinned left and never shifts.

## Drawing feel (already in the prototype, not yet in this repo)

- Stroke ends flat (`StrokeCap.butt`), not round.
- Input smoothing lowered: the point-drop threshold went from 0.004 to 0.0012
  of sheet width, so the line follows the finger instead of averaging it.
- Empty past days show a 4px dot in `kSoftInk`; future days the same dot in
  `kPaper`-adjacent `#D6D2C7`.
