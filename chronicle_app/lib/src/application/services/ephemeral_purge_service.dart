import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../storage/database/chronicle_schema.dart';
import '../../storage/database/database_service.dart';
import '../../storage/media/media_manager.dart';

class EphemeralPurgeService {
  EphemeralPurgeService({
    required DatabaseService databaseService,
    required MediaManager mediaManager,
  })  : _databaseService = databaseService,
        _mediaManager = mediaManager;

  final DatabaseService _databaseService;
  final MediaManager _mediaManager;
  Timer? _purgeTimer;

  void startPeriodicPurge({Duration interval = const Duration(seconds: 60)}) {
    _purgeTimer?.cancel();
    _purgeTimer = Timer.periodic(interval, (_) => purgeExpiredVents());
    // Also run a purge immediately
    purgeExpiredVents();
  }

  void stopPeriodicPurge() {
    _purgeTimer?.cancel();
    _purgeTimer = null;
  }

  Future<void> purgeExpiredVents() async {
    try {
      final db = await _databaseService.openDatabaseConnection();
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.transaction((txn) async {
        // 1. Find all expired vents with media
        final expired = await txn.rawQuery(
          'SELECT entry_id, media_path FROM ${ChronicleSchema.entryIndexTable} '
          'WHERE is_vent = 1 AND burn_at IS NOT NULL AND burn_at <= ?',
          [now],
        );

        if (expired.isEmpty) return;

        final expiredIds = expired.map((row) => row['entry_id'] as int).toList();
        final mediaPaths = expired
            .map((row) => row['media_path'] as String?)
            .where((path) => path != null)
            .cast<String>()
            .toList();

        // 2. Delete entries, events, and tags from database
        final idsPlaceholder = expiredIds.map((_) => '?').join(',');
        await txn.execute(
          'DELETE FROM ${ChronicleSchema.entryIndexTable} '
          'WHERE entry_id IN ($idsPlaceholder)',
          expiredIds,
        );
        await txn.execute(
          'DELETE FROM ${ChronicleSchema.eventsTable} '
          'WHERE entry_id IN ($idsPlaceholder)',
          expiredIds,
        );
        await txn.execute(
          'DELETE FROM ${ChronicleSchema.entryTagsTable} '
          'WHERE entry_id IN ($idsPlaceholder)',
          expiredIds,
        );

        // 3. Delete physical media files from disk
        for (final mediaPath in mediaPaths) {
          try {
            final mediaDir = await _mediaManager.getMediaDirectory();
            final file = File(p.join(mediaDir.path, p.basename(mediaPath)));
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            debugPrint('Error deleting media file $mediaPath: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Error purging expired vents: $e');
    }
  }

  Future<void> purgeSessionVents() async {
    try {
      final db = await _databaseService.openDatabaseConnection();

      await db.transaction((txn) async {
        // 1. Find all session vents (On Exit)
        final sessionVents = await txn.rawQuery(
          'SELECT entry_id, media_path FROM ${ChronicleSchema.entryIndexTable} '
          'WHERE is_vent = 1 AND burn_at IS NULL',
        );

        if (sessionVents.isEmpty) return;

        final ventIds = sessionVents.map((row) => row['entry_id'] as int).toList();
        final mediaPaths = sessionVents
            .map((row) => row['media_path'] as String?)
            .where((path) => path != null)
            .cast<String>()
            .toList();

        final idsPlaceholder = ventIds.map((_) => '?').join(',');
        await txn.execute(
          'DELETE FROM ${ChronicleSchema.entryIndexTable} '
          'WHERE entry_id IN ($idsPlaceholder)',
          ventIds,
        );
        await txn.execute(
          'DELETE FROM ${ChronicleSchema.eventsTable} '
          'WHERE entry_id IN ($idsPlaceholder)',
          ventIds,
        );
        await txn.execute(
          'DELETE FROM ${ChronicleSchema.entryTagsTable} '
          'WHERE entry_id IN ($idsPlaceholder)',
          ventIds,
        );

        for (final mediaPath in mediaPaths) {
          try {
            final mediaDir = await _mediaManager.getMediaDirectory();
            final file = File(p.join(mediaDir.path, p.basename(mediaPath)));
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            debugPrint('Error deleting session media file $mediaPath: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Error purging session vents: $e');
    }
  }

  // Combust single entry immediately
  Future<void> combustNow(int entryId) async {
    try {
      final db = await _databaseService.openDatabaseConnection();
      await db.transaction((txn) async {
        final rows = await txn.rawQuery(
          'SELECT media_path FROM ${ChronicleSchema.entryIndexTable} '
          'WHERE entry_id = ?',
          [entryId],
        );

        await txn.execute(
          'DELETE FROM ${ChronicleSchema.entryIndexTable} WHERE entry_id = ?',
          [entryId],
        );
        await txn.execute(
          'DELETE FROM ${ChronicleSchema.eventsTable} WHERE entry_id = ?',
          [entryId],
        );
        await txn.execute(
          'DELETE FROM ${ChronicleSchema.entryTagsTable} WHERE entry_id = ?',
          [entryId],
        );

        if (rows.isNotEmpty) {
          final mediaPath = rows.first['media_path'] as String?;
          if (mediaPath != null) {
            final mediaDir = await _mediaManager.getMediaDirectory();
            final file = File(p.join(mediaDir.path, p.basename(mediaPath)));
            if (await file.exists()) {
              await file.delete();
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error combusting vent $entryId: $e');
    }
  }
}
