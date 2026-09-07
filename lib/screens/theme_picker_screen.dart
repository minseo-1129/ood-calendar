// Pick the axis the daily question comes from. Reached twice: as the second
// onboarding step, and from Settings (where it pops instead of replacing).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../content/prompt_themes.dart';
import '../data/entry_store.dart';
import '../data/settings_store.dart';
import '../navigation/quiet_route.dart';
import 'calendar_screen.dart';

class ThemePickerScreen extends StatefulWidget {
  const ThemePickerScreen({
    super.key,
    required this.entryStore,
    required this.settingsStore,
    required this.settings,
    this.fromSettings = false,
  });

  final EntryStore entryStore;
  final SettingsStore settingsStore;
  final SodamSettings settings;
  final bool fromSettings;

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen> {
  late String _theme = widget.settings.promptTheme;

  bool get _objectSelected => isObjectTheme(_theme);

  Future<void> _pick(String theme) async {
    setState(() => _theme = theme);
    await widget.settingsStore.savePromptTheme(theme);
  }

  Future<void> _done() async {
    await widget.settingsStore.savePromptTheme(_theme);

    if (!mounted) {
      return;
    }

    if (widget.fromSettings) {
      Navigator.of(context).pop(_theme);
      return;
    }

    await widget.settingsStore.markOnboarded();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      quietRoute<void>(CalendarScreen(store: widget.entryStore)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sample = promptForDate(
      DateTime.now(),
      theme: _theme,
      ageBand: widget.settings.ageBand,
    );

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 30, 36, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                height: 46,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    const Text(
                      '질문 테마',
                      style: TextStyle(fontSize: 28, height: 1, color: kInk),
                    ),
                    const Spacer(),
                    if (widget.fromSettings)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: quietButtonStyle,
                        child: const Text(
                          '닫기',
                          style: TextStyle(fontSize: 15, color: kSoftInk),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '그날의 질문을 어떤 축에서 고를지 정해요.\n나중에 설정에서 바꿀 수 있어요.',
                style: TextStyle(
                  fontSize: 19,
                  height: 1.5,
                  color: kInk.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 28),
              for (final PromptAxis axis in kPromptAxes) ...<Widget>[
                _AxisRow(
                  axis: axis,
                  selected: axis.id == 'object' ? _objectSelected : _theme == axis.id,
                  onTap: () => _pick(
                    axis.id == 'object'
                        ? '$kObjectThemePrefix${kObjectThemes.first.id}'
                        : axis.id,
                  ),
                ),
                if (axis != kPromptAxes.last) const SizedBox(height: 20),
              ],
              if (_objectSelected) ...<Widget>[
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final ObjectTheme option in kObjectThemes)
                          _ObjectChip(
                            label: option.label,
                            selected:
                                _theme == '$kObjectThemePrefix${option.id}',
                            onTap: () =>
                                _pick('$kObjectThemePrefix${option.id}'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                height: 44,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '예: $sample',
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: kSoftInk,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: _done,
                      style: quietButtonStyle,
                      child: Text(
                        widget.fromSettings ? '완료' : '시작하기',
                        style: const TextStyle(
                          fontSize: 19,
                          color: kInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AxisRow extends StatelessWidget {
  const _AxisRow({
    required this.axis,
    required this.selected,
    required this.onTap,
  });

  final PromptAxis axis;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 8, right: 13),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: selected ? kAccent : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  axis.label,
                  style: TextStyle(
                    fontSize: 19,
                    height: 1.2,
                    color: selected ? kInk : kMutedInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  axis.hint,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: kSoftInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectChip extends StatelessWidget {
  const _ObjectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? kAccent.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? kAccent.withValues(alpha: 0.5)
                : kMutedInk.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: selected ? kInk : kMutedInk,
          ),
        ),
      ),
    );
  }
}

final ButtonStyle quietButtonStyle = TextButton.styleFrom(
  padding: EdgeInsets.zero,
  minimumSize: const Size(44, 44),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  foregroundColor: kInk,
  overlayColor: Colors.transparent,
).copyWith(
  textStyle: WidgetStateProperty.resolveWith<TextStyle>(
    (states) => GoogleFonts.gaegu(
      fontWeight: states.contains(WidgetState.hovered)
          ? FontWeight.w600
          : FontWeight.w400,
    ),
  ),
);
