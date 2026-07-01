import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../storage/database/chronicle_schema.dart';
import '../../storage/database/database_service.dart';

class SettingsService {
  SettingsService(this._databaseService);

  final DatabaseService _databaseService;

  static const String _hiddenMessagePasswordKey = 'hidden_message_password';
  static const String _selectedThemeKey = 'selected_theme';
  static const String _vibeCalendarStartDayOfWeekKey = 'vibe_calendar_start_day_of_week';
  static const String _vibeCalendarShowStreaksKey = 'vibe_calendar_show_streaks';
  static const String _vibeCheckBotEnabledKey = 'vibe_check_bot_enabled';
  static const String _vibeCheckBotTimeKey = 'vibe_check_bot_time';
  static const String _vibeCheckLastTriggerDateKey = 'vibe_check_last_trigger_date';
  static const String _lastWeeklyWrappedDateKey = 'last_weekly_wrapped_date';
  static const String _scrapbookBoardThemeKey = 'scrapbook_board_theme';
  static const String _scrapbookWashiStyleKey = 'scrapbook_washi_style';
  static const String _scrapbookLayoutPositionsKey = 'scrapbook_layout_positions';


  final ValueNotifier<String> themeNotifier = ValueNotifier<String>('sunset_coral');

  Future<void> initializeTheme() async {
    final theme = await getSelectedTheme();
    themeNotifier.value = theme;
  }

  Future<String> getSelectedTheme() async {
    final rows = await _databaseService.rawQuery(
      '''
      SELECT value
      FROM ${ChronicleSchema.appSettingsTable}
      WHERE key = ?
      LIMIT 1
      ''',
      <Object?>[_selectedThemeKey],
    );

    if (rows.isEmpty) {
      return 'sunset_coral';
    }
    return rows.single['value']! as String;
  }

  Future<void> setSelectedTheme(String themeName) async {
    await _databaseService.transaction((transaction) async {
      await transaction.insert(
        ChronicleSchema.appSettingsTable,
        <String, Object?>{'key': _selectedThemeKey, 'value': themeName},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    themeNotifier.value = themeName;
  }

  Future<bool> hasHiddenMessagePassword() async {
    final rows = await _databaseService.rawQuery(
      '''
      SELECT value
      FROM ${ChronicleSchema.appSettingsTable}
      WHERE key = ?
      LIMIT 1
      ''',
      <Object?>[_hiddenMessagePasswordKey],
    );

    return rows.isNotEmpty;
  }

  Future<void> setHiddenMessagePassword(String password) async {
    final normalizedPassword = password.trim();
    if (normalizedPassword.isEmpty) {
      throw ArgumentError('Password must not be empty.');
    }

    final salt = _generateSalt();
    final passwordHash = _hashPassword(normalizedPassword, salt);
    final value = jsonEncode(<String, String>{
      'salt': salt,
      'hash': passwordHash,
    });

    await _databaseService.transaction((transaction) async {
      await transaction.insert(
        ChronicleSchema.appSettingsTable,
        <String, Object?>{'key': _hiddenMessagePasswordKey, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<bool> verifyHiddenMessagePassword(String password) async {
    final rows = await _databaseService.rawQuery(
      '''
      SELECT value
      FROM ${ChronicleSchema.appSettingsTable}
      WHERE key = ?
      LIMIT 1
      ''',
      <Object?>[_hiddenMessagePasswordKey],
    );

    if (rows.isEmpty) {
      return false;
    }

    final value = rows.single['value']! as String;
    final decoded = jsonDecode(value) as Map<String, dynamic>;
    final salt = decoded['salt'] as String?;
    final storedHash = decoded['hash'] as String?;
    if (salt == null || storedHash == null) {
      return false;
    }

    final candidateHash = _hashPassword(password.trim(), salt);
    return _constantTimeEquals(candidateHash, storedHash);
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(16, (_) => random.nextInt(256)),
    );
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    var difference = 0;
    for (var index = 0; index < a.length; index += 1) {
      difference |= a.codeUnitAt(index) ^ b.codeUnitAt(index);
    }

    return difference == 0;
  }

  Future<int> getVibeCalendarStartDayOfWeek() async {
    final rows = await _databaseService.rawQuery(
      '''
      SELECT value
      FROM ${ChronicleSchema.appSettingsTable}
      WHERE key = ?
      LIMIT 1
      ''',
      <Object?>[_vibeCalendarStartDayOfWeekKey],
    );

    if (rows.isEmpty) {
      return 1; // default Monday
    }
    return int.tryParse(rows.single['value']! as String) ?? 1;
  }

  Future<void> setVibeCalendarStartDayOfWeek(int dayOfWeek) async {
    await _databaseService.transaction((transaction) async {
      await transaction.insert(
        ChronicleSchema.appSettingsTable,
        <String, Object?>{'key': _vibeCalendarStartDayOfWeekKey, 'value': dayOfWeek.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<bool> getVibeCalendarShowStreaks() async {
    final rows = await _databaseService.rawQuery(
      '''
      SELECT value
      FROM ${ChronicleSchema.appSettingsTable}
      WHERE key = ?
      LIMIT 1
      ''',
      <Object?>[_vibeCalendarShowStreaksKey],
    );

    if (rows.isEmpty) {
      return true; // default true
    }
    return rows.single['value']! as String == 'true';
  }

  Future<void> setVibeCalendarShowStreaks(bool show) async {
    await _databaseService.transaction((transaction) async {
      await transaction.insert(
        ChronicleSchema.appSettingsTable,
        <String, Object?>{'key': _vibeCalendarShowStreaksKey, 'value': show.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<bool> getVibeCheckBotEnabled() async {
    final rows = await _databaseService.rawQuery(
      '''
      SELECT value
      FROM ${ChronicleSchema.appSettingsTable}
      WHERE key = ?
      LIMIT 1
      ''',
      <Object?>[_vibeCheckBotEnabledKey],
    );

    if (rows.isEmpty) {
      return true; // default true
    }
    return rows.single['value']! as String == 'true';
  }

  Future<void> setVibeCheckBotEnabled(bool enabled) async {
    await _databaseService.transaction((transaction) async {
      await transaction.insert(
        ChronicleSchema.appSettingsTable,
        <String, Object?>{'key': _vibeCheckBotEnabledKey, 'value': enabled.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<String> getVibeCheckBotTime() async {
    final rows = await _databaseService.rawQuery(
      '''
      SELECT value
      FROM ${ChronicleSchema.appSettingsTable}
      WHERE key = ?
      LIMIT 1
      ''',
      <Object?>[_vibeCheckBotTimeKey],
    );

    if (rows.isEmpty) {
      return '20:00'; // default 8 PM
    }
    return rows.single['value']! as String;
  }

  Future<void> setVibeCheckBotTime(String time) async {
    await _databaseService.transaction((transaction) async {
      await transaction.insert(
        ChronicleSchema.appSettingsTable,
        <String, Object?>{'key': _vibeCheckBotTimeKey, 'value': time},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<String?> getVibeCheckLastTriggerDate() async {
    final rows = await _databaseService.rawQuery(
      '''
      SELECT value
      FROM ${ChronicleSchema.appSettingsTable}
      WHERE key = ?
      LIMIT 1
      ''',
      <Object?>[_vibeCheckLastTriggerDateKey],
    );

    if (rows.isEmpty) {
      return null;
    }
    return rows.single['value']! as String;
  }

  Future<void> setVibeCheckLastTriggerDate(String date) async {
    await _databaseService.transaction((transaction) async {
      await transaction.insert(
        ChronicleSchema.appSettingsTable,
        <String, Object?>{'key': _vibeCheckLastTriggerDateKey, 'value': date},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> clearBotMessages() async {
    await _databaseService.transaction((transaction) async {
      await transaction.delete(
        ChronicleSchema.entryIndexTable,
        where: "type IN ('bot_prompt', 'bot_response')",
      );
    });
  }

  Future<String?> getLastWeeklyWrappedDate() async {
    final rows = await _databaseService.rawQuery(
      '''
      SELECT value
      FROM ${ChronicleSchema.appSettingsTable}
      WHERE key = ?
      LIMIT 1
      ''',
      <Object?>[_lastWeeklyWrappedDateKey],
    );

    if (rows.isEmpty) {
      return null;
    }
    return rows.single['value']! as String;
  }

  Future<void> setLastWeeklyWrappedDate(String dateCode) async {
    await _databaseService.transaction((transaction) async {
      await transaction.insert(
        ChronicleSchema.appSettingsTable,
        <String, Object?>{'key': _lastWeeklyWrappedDateKey, 'value': dateCode},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<String> getScrapbookBoardTheme() async {
    final rows = await _databaseService.rawQuery(
      '''
      SELECT value
      FROM ${ChronicleSchema.appSettingsTable}
      WHERE key = ?
      LIMIT 1
      ''',
      <Object?>[_scrapbookBoardThemeKey],
    );
    if (rows.isEmpty) {
      return 'corkboard';
    }
    return rows.single['value']! as String;
  }

  Future<void> setScrapbookBoardTheme(String theme) async {
    await _databaseService.transaction((transaction) async {
      await transaction.insert(
        ChronicleSchema.appSettingsTable,
        <String, Object?>{'key': _scrapbookBoardThemeKey, 'value': theme},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<String> getScrapbookWashiStyle() async {
    final rows = await _databaseService.rawQuery(
      '''
      SELECT value
      FROM ${ChronicleSchema.appSettingsTable}
      WHERE key = ?
      LIMIT 1
      ''',
      <Object?>[_scrapbookWashiStyleKey],
    );
    if (rows.isEmpty) {
      return 'grid';
    }
    return rows.single['value']! as String;
  }

  Future<void> setScrapbookWashiStyle(String style) async {
    await _databaseService.transaction((transaction) async {
      await transaction.insert(
        ChronicleSchema.appSettingsTable,
        <String, Object?>{'key': _scrapbookWashiStyleKey, 'value': style},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<Map<int, Map<String, double>>> getScrapbookLayoutPositions() async {
    final rows = await _databaseService.rawQuery(
      '''
      SELECT value
      FROM ${ChronicleSchema.appSettingsTable}
      WHERE key = ?
      LIMIT 1
      ''',
      <Object?>[_scrapbookLayoutPositionsKey],
    );
    if (rows.isEmpty) {
      return <int, Map<String, double>>{};
    }
    try {
      final decoded = json.decode(rows.single['value']! as String) as Map<String, dynamic>;
      final result = <int, Map<String, double>>{};
      decoded.forEach((key, val) {
        final id = int.tryParse(key);
        if (id != null && val is Map) {
          result[id] = {
            'x': (val['x'] as num).toDouble(),
            'y': (val['y'] as num).toDouble(),
            'rotation': (val['rotation'] as num).toDouble(),
          };
        }
      });
      return result;
    } catch (_) {
      return <int, Map<String, double>>{};
    }
  }

  Future<void> setScrapbookLayoutPositions(Map<int, Map<String, double>> positions) async {
    final encoded = json.encode(
      positions.map((key, val) => MapEntry(key.toString(), val)),
    );
    await _databaseService.transaction((transaction) async {
      await transaction.insert(
        ChronicleSchema.appSettingsTable,
        <String, Object?>{'key': _scrapbookLayoutPositionsKey, 'value': encoded},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }
}
