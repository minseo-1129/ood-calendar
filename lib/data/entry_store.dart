import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/doodle_models.dart';
import '../utils/date_labels.dart';

class EntryStore {
  static const String _entriesKey = 'sodam.entries.v2';
  static const String _legacyEntriesKey = 'sodam.entries.v1';
  static const String _draftKey = 'sodam.todayDraft.v2';

  Future<Map<String, DoodleEntry>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_entriesKey);

    if (raw == null || raw.isEmpty) {
      final legacy = prefs.getString(_legacyEntriesKey);
      if (legacy == null || legacy.isEmpty) {
        return <String, DoodleEntry>{};
      }
      raw = legacy;
      await prefs.setString(_entriesKey, legacy);
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        DoodleEntry.fromJson(
          Map<String, dynamic>.from(value as Map),
        ),
      ),
    );
  }

  Future<Map<String, DoodleEntry>> loadMonth(DateTime month) async {
    final all = await loadAll();
    final prefix = monthKey(month);

    return Map<String, DoodleEntry>.fromEntries(
      all.entries.where((entry) => entry.key.startsWith(prefix)),
    );
  }

  Future<void> saveEntry(DoodleEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    all[entry.dateKey] = entry;

    await prefs.setString(
      _entriesKey,
      jsonEncode(
        all.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
  }

  Future<void> deleteEntry(String entryDateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    all.remove(entryDateKey);

    await prefs.setString(
      _entriesKey,
      jsonEncode(
        all.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
  }

  Future<DoodleDraft?> loadDraft(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final draft = DoodleDraft.fromJson(
      Map<String, dynamic>.from(jsonDecode(raw) as Map),
    );

    if (draft.dateKey != dateKey(date)) {
      await prefs.remove(_draftKey);
      return null;
    }

    return draft;
  }

  Future<void> saveDraft({
    required DateTime date,
    required List<DoodleStroke> strokes,
    required String note,
    required String prompt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final draft = DoodleDraft(
      dateKey: dateKey(date),
      strokes: List<DoodleStroke>.of(strokes),
      note: note,
      prompt: prompt,
      updatedAt: DateTime.now(),
    );

    await prefs.setString(
      _draftKey,
      jsonEncode(draft.toJson()),
    );
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }
}
