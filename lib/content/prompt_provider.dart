import 'prompt_themes.dart' as themed;

// Runtime prompt context. SettingsStore configures theme/age on app boot and
// whenever the user changes a preference. CardBrowse updates tenure from the
// number of saved entries it already loads.
String _theme = themed.kDefaultTheme;
String _ageBand = themed.kDefaultAgeBand;
int _tenure = 0;

/// Updates only the supplied parts of the prompt context.
///
/// Keeping this synchronous lets existing `promptForDate(date)` call sites
/// remain simple while the actual prompt engine is theme-aware.
void configurePromptContext({
  String? theme,
  String? ageBand,
  int? tenure,
}) {
  if (theme != null && theme.isNotEmpty) {
    _theme = theme;
  }
  if (ageBand != null && ageBand.isNotEmpty) {
    _ageBand = ageBand;
  }
  if (tenure != null) {
    _tenure = tenure < 0 ? 0 : tenure;
  }
}

String promptForDate(DateTime date) {
  return themed.promptForDate(
    date,
    theme: _theme,
    ageBand: _ageBand,
    tenure: _tenure,
  );
}
