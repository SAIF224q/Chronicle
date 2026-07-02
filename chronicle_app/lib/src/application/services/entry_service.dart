import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../storage/database/chronicle_schema.dart';
import '../../storage/database/database_service.dart';
import '../../storage/events/event_service.dart';
import '../../storage/media/media_manager.dart';

class EntryRecord {
  const EntryRecord({
    required this.entryId,
    required this.type,
    required this.content,
    required this.mediaPath,
    required this.tags,
    required this.createdAt,
    this.locationName,
    this.latitude,
    this.longitude,
    required this.mood,
    this.unlockAt,
    this.isVent = false,
    this.burnAt,
  });

  final int entryId;
  final String type;
  final String content;
  final String? mediaPath;
  final List<String> tags;
  final int createdAt;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String mood;
  final int? unlockAt;
  final bool isVent;
  final int? burnAt;
}

class EntryService {
  EntryService({
    required DatabaseService databaseService,
    required EventService eventService,
    required MediaManager mediaManager,
  }) : _databaseService = databaseService,
       _eventService = eventService,
       _mediaManager = mediaManager;

  final DatabaseService _databaseService;
  final EventService _eventService;
  final MediaManager _mediaManager;

  MediaManager get mediaManager => _mediaManager;

  static final RegExp _hashtagPattern = RegExp(r'(?<!\S)#([A-Za-z0-9_]+)');

  Future<EntryRecord> createEntry({
    required String content,
    File? image,
    File? voiceNote,
    String? locationName,
    double? latitude,
    double? longitude,
    String mood = 'none',
    int? unlockAt,
    bool isVent = false,
    int? burnAt,
  }) async {
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty && image == null && voiceNote == null && locationName == null) {
      throw ArgumentError('An entry must include text content, an image, a voice note, or a location.');
    }

    String? mediaPath;
    if (image != null) {
      mediaPath = await _mediaManager.saveImage(image);
    } else if (voiceNote != null) {
      mediaPath = await _mediaManager.saveAudio(voiceNote);
    }

    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final contentTags = _extractTags(content);
    final tags = contentTags..sort();

    try {
      return await _databaseService.transaction((transaction) async {
        final entryId = await _generateEntryId(transaction);
        final type = voiceNote != null
            ? 'voice'
            : mediaPath == null
                ? 'text'
                : 'image';

        await _eventService.writeEvent(
          ChronicleEventDraft(
            eventType: 'EntryCreated',
            entryId: entryId,
            payload: <String, Object?>{
              'type': type,
              'content': normalizedContent,
              'media_path': mediaPath,
              'location_name': locationName,
              'latitude': latitude,
              'longitude': longitude,
              'mood': mood,
              'unlock_at': unlockAt,
              'is_vent': isVent ? 1 : 0,
              'burn_at': burnAt,
            },
            createdAt: createdAt,
          ),
          executor: transaction,
        );

        await transaction
            .insert(ChronicleSchema.entryIndexTable, <String, Object?>{
              'entry_id': entryId,
              'type': type,
              'content': normalizedContent,
              'media_path': mediaPath,
              'created_at': createdAt,
              'archived': 0,
              'hidden': 0,
              'location_name': locationName,
              'latitude': latitude,
              'longitude': longitude,
              'mood': mood,
              'unlock_at': unlockAt,
              'is_vent': isVent ? 1 : 0,
              'burn_at': burnAt,
            });

        for (final tag in tags) {
          await _eventService.writeEvent(
            ChronicleEventDraft(
              eventType: 'TagAdded',
              entryId: entryId,
              payload: <String, Object?>{'tag': tag},
              createdAt: createdAt,
            ),
            executor: transaction,
          );

          await transaction.insert(
            ChronicleSchema.entryTagsTable,
            <String, Object?>{'entry_id': entryId, 'tag': tag},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        return EntryRecord(
          entryId: entryId,
          type: type,
          content: normalizedContent,
          mediaPath: mediaPath,
          tags: tags,
          createdAt: createdAt,
          locationName: locationName,
          latitude: latitude,
          longitude: longitude,
          mood: mood,
          unlockAt: unlockAt,
          isVent: isVent,
          burnAt: burnAt,
        );
      });
    } catch (_) {
      if (mediaPath != null) {
        await _deleteSavedMedia(mediaPath);
      }
      rethrow;
    }
  }

  Future<EntryRecord> createBotEntry({
    required String content,
    required String type, // 'bot_prompt' or 'bot_response'
    String mood = 'none',
  }) async {
    final normalizedContent = content.trim();
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return await _databaseService.transaction((transaction) async {
      final entryId = await _generateEntryId(transaction);

      await _eventService.writeEvent(
        ChronicleEventDraft(
          eventType: 'EntryCreated',
          entryId: entryId,
          payload: <String, Object?>{
            'type': type,
            'content': normalizedContent,
            'media_path': null,
            'location_name': null,
            'latitude': null,
            'longitude': null,
            'mood': mood,
            'unlock_at': null,
          },
          createdAt: createdAt,
        ),
        executor: transaction,
      );

      await transaction
          .insert(ChronicleSchema.entryIndexTable, <String, Object?>{
            'entry_id': entryId,
            'type': type,
            'content': normalizedContent,
            'media_path': null,
            'created_at': createdAt,
            'archived': 0,
            'hidden': 0,
            'location_name': null,
            'latitude': null,
            'longitude': null,
            'mood': mood,
            'unlock_at': null,
          });

      return EntryRecord(
        entryId: entryId,
        type: type,
        content: normalizedContent,
        mediaPath: null,
        tags: const [],
        createdAt: createdAt,
        locationName: null,
        latitude: null,
        longitude: null,
        mood: mood,
        unlockAt: null,
        isVent: false,
        burnAt: null,
      );
    });
  }

  Future<EntryRecord> editEntry({
    required int entryId,
    required String content,
    String? mood,
    int? unlockAt,
  }) async {
    if (entryId <= 0) {
      throw ArgumentError.value(
        entryId,
        'entryId',
        'Entry ID must be positive.',
      );
    }

    final editedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    return _databaseService.transaction((transaction) async {
      final existingRows = await transaction.query(
        ChronicleSchema.entryIndexTable,
        columns: <String>[
          'entry_id',
          'type',
          'content',
          'media_path',
          'created_at',
          'mood',
          'unlock_at',
          'is_vent',
          'burn_at',
        ],
        where: 'entry_id = ?',
        whereArgs: <Object?>[entryId],
        limit: 1,
      );

      if (existingRows.isEmpty) {
        throw StateError('Entry $entryId was not found.');
      }

      final existing = existingRows.single;
      final existingUnlockAt = existing['unlock_at'] as int?;
      if (existingUnlockAt != null && existingUnlockAt > DateTime.now().millisecondsSinceEpoch) {
        throw StateError('Cannot edit a locked time capsule.');
      }

      final type = existing['type']! as String;
      final mediaPath = existing['media_path'] as String?;
      final createdAt = existing['created_at']! as int;
      final existingMood = existing['mood'] as String? ?? 'none';
      final resolvedMood = mood ?? existingMood;
      final resolvedUnlockAt = unlockAt ?? existingUnlockAt;
      final isVent = existing['is_vent'] == 1;
      final burnAt = existing['burn_at'] as int?;
      final normalizedContent = content.trim();

      if (type == 'text' && normalizedContent.isEmpty) {
        throw ArgumentError('Text entries must include content after editing.');
      }

      await _eventService.writeEvent(
        ChronicleEventDraft(
          eventType: 'EntryEdited',
          entryId: entryId,
          payload: <String, Object?>{
            'content': normalizedContent,
            if (mood != null) 'mood': mood,
            if (unlockAt != null) 'unlock_at': unlockAt,
          },
          createdAt: editedAt,
        ),
        executor: transaction,
      );

      await transaction.update(
        ChronicleSchema.entryIndexTable,
        <String, Object?>{
          'content': normalizedContent,
          'updated_at': editedAt,
          if (mood != null) 'mood': mood,
          if (unlockAt != null) 'unlock_at': unlockAt,
        },
        where: 'entry_id = ?',
        whereArgs: <Object?>[entryId],
      );

      final existingTagRows = await transaction.query(
        ChronicleSchema.entryTagsTable,
        columns: <String>['tag'],
        where: 'entry_id = ?',
        whereArgs: <Object?>[entryId],
      );
      final existingTags = existingTagRows
          .map((row) => row['tag']! as String)
          .toSet();
      
      final contentTags = _extractTags(content);
      final newTags = contentTags..sort();

      final tagsToRemove = existingTags.difference(newTags.toSet()).toList()..sort();
      final tagsToAdd = newTags.toSet().difference(existingTags).toList()..sort();

      for (final tag in tagsToRemove) {
        await _eventService.writeEvent(
          ChronicleEventDraft(
            eventType: 'TagRemoved',
            entryId: entryId,
            payload: <String, Object?>{'tag': tag},
            createdAt: editedAt,
          ),
          executor: transaction,
        );

        await transaction.delete(
          ChronicleSchema.entryTagsTable,
          where: 'entry_id = ? AND tag = ?',
          whereArgs: <Object?>[entryId, tag],
        );
      }

      for (final tag in tagsToAdd) {
        await _eventService.writeEvent(
          ChronicleEventDraft(
            eventType: 'TagAdded',
            entryId: entryId,
            payload: <String, Object?>{'tag': tag},
            createdAt: editedAt,
          ),
          executor: transaction,
        );

        await transaction.insert(
          ChronicleSchema.entryTagsTable,
          <String, Object?>{'entry_id': entryId, 'tag': tag},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      return EntryRecord(
        entryId: entryId,
        type: type,
        content: normalizedContent,
        mediaPath: mediaPath,
        tags: List<String>.of(newTags, growable: false),
        createdAt: createdAt,
        mood: resolvedMood,
        unlockAt: resolvedUnlockAt,
        isVent: isVent,
        burnAt: burnAt,
      );
    });
  }

  Future<void> hideEntry({required int entryId}) async {
    if (entryId <= 0) {
      throw ArgumentError.value(
        entryId,
        'entryId',
        'Entry ID must be positive.',
      );
    }

    final hiddenAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _databaseService.transaction((transaction) async {
      final existingRows = await transaction.query(
        ChronicleSchema.entryIndexTable,
        columns: <String>['entry_id', 'hidden'],
        where: 'entry_id = ?',
        whereArgs: <Object?>[entryId],
        limit: 1,
      );

      if (existingRows.isEmpty) {
        throw StateError('Entry $entryId was not found.');
      }

      if (existingRows.single['hidden'] == 1) {
        return;
      }

      await _eventService.writeEvent(
        ChronicleEventDraft(
          eventType: 'EntryHidden',
          entryId: entryId,
          payload: const <String, Object?>{},
          createdAt: hiddenAt,
        ),
        executor: transaction,
      );

      await transaction.update(
        ChronicleSchema.entryIndexTable,
        <String, Object?>{'hidden': 1},
        where: 'entry_id = ?',
        whereArgs: <Object?>[entryId],
      );
    });
  }

  Future<int> _generateEntryId(DatabaseExecutor executor) async {
    final rows = await executor.rawQuery('''
      SELECT COALESCE(MAX(entry_id), 0) + 1 AS next_entry_id
      FROM ${ChronicleSchema.eventsTable}
      ''');

    return rows.single['next_entry_id']! as int;
  }

  List<String> _extractTags(String content) {
    final tags = <String>{};

    for (final match in _hashtagPattern.allMatches(content)) {
      final tag = match.group(1);
      if (tag == null || tag.isEmpty) {
        continue;
      }

      tags.add(tag.toLowerCase());
    }

    return List<String>.of(tags, growable: false);
  }

  Future<void> _deleteSavedMedia(String mediaPath) async {
    final mediaDirectory = await _mediaManager.getMediaDirectory();
    final filename = p.basename(mediaPath);
    final savedFile = File(p.join(mediaDirectory.path, filename));

    if (await savedFile.exists()) {
      await savedFile.delete();
    }
  }
}
