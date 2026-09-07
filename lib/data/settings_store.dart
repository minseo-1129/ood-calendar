// Onboarding + prompt-theme preferences. Kept separate from EntryStore so the
// diary data and the app's settings can never clobber each other.

import 'package:shared_preferences/shared_preferences.dart';

import '../content/prompt_themes.dart';

class SodamSettings {
  const SodamSettings({
    required this.onboarded,
    required this.promptTheme,
    required this.ageBand,
  });

  final bool onboarded;
  final String promptTheme;
  final String ageBand;

  SodamSettings copyWith({
    bool? onboarded,
    String? promptTheme,
    String? ageBand,
  }) {
    return SodamSettings(
      onboarded: onboarded ?? this.onboarded,
      promptTheme: promptTheme ?? this.promptTheme,
      ageBand: ageBand ?? this.ageBand,
    );
  }
}

class SettingsStore {
  static const String _onboardedKey = 'sodam.onboarded.v1';
  static const String _themeKey = 'sodam.promptTheme.v1';
  static const String _ageBandKey = 'sodam.ageBand.v1';

  Future<SodamSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString(_themeKey);
    final ageBand = prefs.getString(_ageBandKey);

    return SodamSettings(
      onboarded: prefs.getBool(_onboardedKey) ?? false,
      promptTheme: (theme == null || theme.isEmpty) ? kDefaultTheme : theme,
      ageBand: (ageBand == null || ageBand.isEmpty) ? kDefaultAgeBand : ageBand,
    );
  }

  Future<void> savePromptTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  Future<void> saveAgeBand(String ageBand) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ageBandKey, ageBand);
  }

  Future<void> markOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, true);
  }

  /// Only used by the debug affordance in Settings.
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardedKey);
  }
}
