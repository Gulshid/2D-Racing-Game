import 'dart:convert';

import 'package:racing/data/models/save_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves progress as JSON, with a versioned migration path and a backup.
///
/// Every save first copies the previous save to a backup key. If the main
/// save is unreadable on the next launch, the backup is used instead.
class SaveRepository {
  SaveRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'save.data';
  static const _backupKey = 'save.backup';

  /// Migration steps: _migrations[v] turns a version-v map into version v+1.
  /// Add an entry here whenever SaveData.currentVersion goes up.
  static final Map<int, Map<String, dynamic> Function(Map<String, dynamic>)>
      _migrations = {
    // 1: (j) => {...j, 'newField': defaultValue}, // example for version 2
  };

  SaveData load() {
    final main = _tryRead(_prefs.getString(_key));
    if (main != null) return main;
    final backup = _tryRead(_prefs.getString(_backupKey));
    return backup ?? SaveData.initial();
  }

  Future<void> save(SaveData data) async {
    final previous = _prefs.getString(_key);
    if (previous != null) {
      await _prefs.setString(_backupKey, previous);
    }
    await _prefs.setString(_key, jsonEncode(data.toJson()));
  }

  /// Returns null if the text is missing, broken, or cannot be migrated.
  SaveData? _tryRead(String? raw) {
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return SaveData.fromJson(_migrate(decoded));
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _migrate(Map<String, dynamic> json) {
    var version = (json['version'] is num)
        ? (json['version'] as num).toInt()
        : 1;
    var data = json;
    while (version < SaveData.currentVersion) {
      final step = _migrations[version];
      if (step != null) data = step(data);
      version++;
    }
    return data;
  }
}
