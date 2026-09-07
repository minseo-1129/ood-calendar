// Settings: one editable row (question theme) and three statements of fact.
// Reached from the calendar's month title.

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../content/prompt_themes.dart';
import '../data/entry_store.dart';
import '../data/settings_store.dart';
import '../navigation/quiet_route.dart';
import 'theme_picker_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.entryStore,
    required this.settingsStore,
    this.appVersion = '1.0.0 (3)',
  });

  final EntryStore entryStore;
  final SettingsStore settingsStore;
  final String appVersion;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SodamSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await widget.settingsStore.load();
    if (mounted) {
      setState(() => _settings = settings);
    }
  }

  Future<void> _openThemePicker() async {
    final settings = _settings;
    if (settings == null) {
      return;
    }

    await Navigator.of(context).push(
      quietRoute<String>(
        ThemePickerScreen(
          entryStore: widget.entryStore,
          settingsStore: widget.settingsStore,
          settings: settings,
          fromSettings: true,
        ),
      ),
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 30, 36, 20),
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
                      '설정',
                      style: TextStyle(fontSize: 28, height: 1, color: kInk),
                    ),
                    const Spacer(),
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
              const SizedBox(height: 22),
              GestureDetector(
                onTap: settings == null ? null : _openThemePicker,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    const Text(
                      '질문 테마',
                      style: TextStyle(fontSize: 19, color: kInk),
                    ),
                    const Spacer(),
                    Text(
                      settings == null
                          ? ''
                          : '${promptThemeLabel(settings.promptTheme)} ›',
                      style: const TextStyle(fontSize: 15, color: kMutedInk),
                    ),
                  ],
                ),
              ),
              const _Divider(),
              const _Statement(
                title: '알림',
                detail: '이 앱은 알림을 보내지 않습니다',
              ),
              const _Divider(),
              const _Statement(
                title: '저장 위치',
                detail: '기록은 이 기기에만 저장됩니다',
              ),
              const _Divider(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  const Text('버전', style: TextStyle(fontSize: 19, color: kInk)),
                  const Spacer(),
                  Text(
                    widget.appVersion,
                    style: const TextStyle(fontSize: 12, color: kSoftInk),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Statement extends StatelessWidget {
  const _Statement({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: const TextStyle(fontSize: 19, color: kInk)),
        const SizedBox(height: 4),
        Text(detail, style: const TextStyle(fontSize: 12, color: kSoftInk)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Container(height: 1, color: kMutedInk.withValues(alpha: 0.16)),
    );
  }
}
