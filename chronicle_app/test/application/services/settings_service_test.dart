import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:chronicle_app/src/application/services/settings_service.dart';
import 'package:chronicle_app/src/storage/database/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService', () {
    late Directory tempDirectory;
    late DatabaseService databaseService;
    late SettingsService settingsService;

    setUpAll(() {
      sqfliteFfiInit();
    });

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'chronicle_settings_',
      );
      databaseService = DatabaseService(
        documentsDirectoryProvider: () async => tempDirectory,
        factory: databaseFactoryFfi,
      );
      await databaseService.initializeDatabase();
      settingsService = SettingsService(databaseService);
    });

    tearDown(() async {
      await databaseService.close();
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('stores a password hash and verifies password attempts', () async {
      expect(await settingsService.hasHiddenMessagePassword(), isFalse);

      await settingsService.setHiddenMessagePassword('secret');

      expect(await settingsService.hasHiddenMessagePassword(), isTrue);
      expect(
        await settingsService.verifyHiddenMessagePassword('secret'),
        isTrue,
      );
      expect(
        await settingsService.verifyHiddenMessagePassword('wrong'),
        isFalse,
      );

      final rows = await databaseService.rawQuery(
        'SELECT value FROM app_settings WHERE key = ?',
        <Object?>['hidden_message_password'],
      );
      expect(rows.single['value'], isNot(contains('secret')));
    });

    test('saves and retrieves scrapbook configurations and layout positions', () async {
      // Test defaults
      expect(await settingsService.getScrapbookBoardTheme(), 'corkboard');
      expect(await settingsService.getScrapbookWashiStyle(), 'grid');
      expect(await settingsService.getScrapbookLayoutPositions(), isEmpty);

      // Test theme saving
      await settingsService.setScrapbookBoardTheme('pastel_aura');
      expect(await settingsService.getScrapbookBoardTheme(), 'pastel_aura');

      // Test washi style saving
      await settingsService.setScrapbookWashiStyle('glitter');
      expect(await settingsService.getScrapbookWashiStyle(), 'glitter');

      // Test layout coordinates saving
      final positions = {
        101: {'x': 100.5, 'y': 200.0, 'rotation': -2.5},
        102: {'x': 150.0, 'y': 350.5, 'rotation': 4.2},
      };
      await settingsService.setScrapbookLayoutPositions(positions);

      final loadedPositions = await settingsService.getScrapbookLayoutPositions();
      expect(loadedPositions.length, 2);
      expect(loadedPositions[101]!['x'], 100.5);
      expect(loadedPositions[101]!['rotation'], -2.5);
      expect(loadedPositions[102]!['y'], 350.5);
    });
  });
}
