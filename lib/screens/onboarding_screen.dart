// One quiet page of copy, then the prompt-theme step. No carousel, no dots,
// no progress bar — the app promises calm, so onboarding has to behave.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import '../data/entry_store.dart';
import '../data/settings_store.dart';
import '../navigation/quiet_route.dart';
import 'theme_picker_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    super.key,
    required this.entryStore,
    required this.settingsStore,
    required this.settings,
  });

  final EntryStore entryStore;
  final SettingsStore settingsStore;
  final SodamSettings settings;

  static const List<String> _lines = <String>[
    '그날의 질문 하나가 뜹니다.\n답은 작은 그림이면 충분해요.',
    '비운 날도 그대로 괜찮습니다.\n연속 기록을 세지 않아요.',
    '기록은 이 기기에만 저장됩니다.',
  ];

  void _next(BuildContext context) {
    Navigator.of(context).push(
      quietRoute<void>(
        ThemePickerScreen(
          entryStore: entryStore,
          settingsStore: settingsStore,
          settings: settings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 30, 36, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                '하루에 한 장,\n그림으로 남기기',
                style: TextStyle(fontSize: 28, height: 1.25, color: kInk),
              ),
              const SizedBox(height: 40),
              for (final String line in _lines) ...<Widget>[
                _Line(line),
                if (line != _lines.last) const SizedBox(height: 22),
              ],
              const Spacer(),
              SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _next(context),
                    style: _quietButtonStyle,
                    child: const Text(
                      '다음',
                      style: TextStyle(
                        fontSize: 19,
                        color: kInk,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 11, right: 12),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: kAccent,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 19,
              height: 1.5,
              color: kInk.withValues(alpha: 0.75),
            ),
          ),
        ),
      ],
    );
  }
}

final ButtonStyle _quietButtonStyle = TextButton.styleFrom(
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
