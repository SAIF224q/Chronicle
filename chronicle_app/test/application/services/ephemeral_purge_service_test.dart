import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import 'package:chronicle_app/src/application/services/entry_service.dart';
import 'package:chronicle_app/src/application/services/ephemeral_purge_service.dart';
import 'package:chronicle_app/src/storage/database/database_service.dart';
import 'package:chronicle_app/src/storage/database/chronicle_schema.dart';
import 'package:chronicle_app/src/storage/media/media_manager.dart';
import 'package:chronicle_app/src/storage/events/event_service.dart';

void main() {
  late DatabaseService databaseService;
  late MediaManager mediaManager;
  late EntryService entryService;
  late EphemeralPurgeService purgeService;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    databaseService = DatabaseService(
      documentsDirectoryProvider: () async => Directory.systemTemp,
      factory: databaseFactoryFfi,
    );
    // Delete any old databases
    final path = await databaseService.getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    await databaseService.initializeDatabase();
    mediaManager = MediaManager(
      documentsDirectoryProvider: () async => Directory.systemTemp,
    );
    entryService = EntryService(
      databaseService: databaseService,
      eventService: EventService(databaseService),
      mediaManager: mediaManager,
    );
    purgeService = EphemeralPurgeService(
      databaseService: databaseService,
      mediaManager: mediaManager,
    );
  });

  tearDown(() async {
    await databaseService.close();
  });

  group('EphemeralPurgeService Tests', () {
    test('creates and retrieves vents, and purges expired vents correctly', () async {
      // 1. Create a regular entry
      final regular = await entryService.createEntry(
        content: 'Regular entry',
      );

      // 2. Create an expired vent entry (5 mins in the past)
      final pastBurnAt = DateTime.now().millisecondsSinceEpoch - 5 * 60 * 1000;
      final expired = await entryService.createEntry(
        content: 'Expired vent entry',
        isVent: true,
        burnAt: pastBurnAt,
      );

      // 3. Create a non-expired vent entry (5 mins in the future)
      final futureBurnAt = DateTime.now().millisecondsSinceEpoch + 5 * 60 * 1000;
      final futureVent = await entryService.createEntry(
        content: 'Future vent entry',
        isVent: true,
        burnAt: futureBurnAt,
      );

      // 4. Create a session vent entry (burnAt = null, isVent = true)
      final sessionVent = await entryService.createEntry(
        content: 'Session exit vent',
        isVent: true,
        burnAt: null,
      );

      // Verify they all exist in database first
      final db = await databaseService.openDatabaseConnection();
      var count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${ChronicleSchema.entryIndexTable}'),
      );
      expect(count, 4);

      // Verify specific column values
      final rows = await db.rawQuery('SELECT entry_id, is_vent, burn_at FROM ${ChronicleSchema.entryIndexTable}');
      final expiredRow = rows.firstWhere((r) => r['entry_id'] == expired.entryId);
      expect(expiredRow['is_vent'], 1);
      expect(expiredRow['burn_at'], pastBurnAt);

      final regularRow = rows.firstWhere((r) => r['entry_id'] == regular.entryId);
      expect(regularRow['is_vent'], 0);
      expect(regularRow['burn_at'], isNull);

      // Run expired vents purge
      await purgeService.purgeExpiredVents();

      // Only the expired vent should be deleted
      final rowsAfterExpiredPurge = await db.rawQuery('SELECT entry_id FROM ${ChronicleSchema.entryIndexTable}');
      expect(rowsAfterExpiredPurge.length, 3);
      expect(rowsAfterExpiredPurge.any((r) => r['entry_id'] == expired.entryId), false);
      expect(rowsAfterExpiredPurge.any((r) => r['entry_id'] == regular.entryId), true);
      expect(rowsAfterExpiredPurge.any((r) => r['entry_id'] == futureVent.entryId), true);
      expect(rowsAfterExpiredPurge.any((r) => r['entry_id'] == sessionVent.entryId), true);

      // Run session exit purge
      await purgeService.purgeSessionVents();

      // The session vent should be deleted
      final rowsAfterSessionPurge = await db.rawQuery('SELECT entry_id FROM ${ChronicleSchema.entryIndexTable}');
      expect(rowsAfterSessionPurge.length, 2);
      expect(rowsAfterSessionPurge.any((r) => r['entry_id'] == sessionVent.entryId), false);
      expect(rowsAfterSessionPurge.any((r) => r['entry_id'] == regular.entryId), true);
      expect(rowsAfterSessionPurge.any((r) => r['entry_id'] == futureVent.entryId), true);

      // Combust future vent immediately
      await purgeService.combustNow(futureVent.entryId);

      final finalRows = await db.rawQuery('SELECT entry_id FROM ${ChronicleSchema.entryIndexTable}');
      expect(finalRows.length, 1);
      expect(finalRows.single['entry_id'], regular.entryId);
    });
  });
}
