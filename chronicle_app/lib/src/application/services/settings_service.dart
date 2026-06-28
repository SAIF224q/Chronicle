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
}
