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
  });

  final int entryId;
  final String type;
  final String content;
  final String? mediaPath;
  final List<String> tags;
  final int createdAt;
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

  static final RegExp _hashtagPattern = RegExp(r'(?<!\S)#([A-Za-z0-9_]+)');

  Future<EntryRecord> createEntry({
    required String content,
    File? image,
  }) async {
    final normalizedContent = content.trim();
    if (normalizedContent.isEmpty && image == null) {
      throw ArgumentError('An entry must include text content or an image.');
    }

    String? mediaPath;
    if (image != null) {
      mediaPath = await _mediaManager.saveImage(image);
    }

    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final tags = _extractTags(content);

    try {
      return await _databaseService.transaction((transaction) async {
        final entryId = await _generateEntryId(transaction);
        final type = mediaPath == null ? 'text' : 'image';

        await _eventService.writeEvent(
          ChronicleEventDraft(
            eventType: 'EntryCreated',
            entryId: entryId,
            payload: <String, Object?>{
              'type': type,
              'content': normalizedContent,
              'media_path': mediaPath,
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
        );
      });
    } catch (_) {
      if (mediaPath != null) {
        await _deleteSavedMedia(mediaPath);
      }
      rethrow;
    }
  }

  Future<EntryRecord> editEntry({
    required int entryId,
    required String content,
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
        ],
        where: 'entry_id = ?',
        whereArgs: <Object?>[entryId],
        limit: 1,
      );

      if (existingRows.isEmpty) {
        throw StateError('Entry $entryId was not found.');
      }

      final existing = existingRows.single;
      final type = existing['type']! as String;
      final mediaPath = existing['media_path'] as String?;
      final createdAt = existing['created_at']! as int;
      final normalizedContent = content.trim();

      if (type == 'text' && normalizedContent.isEmpty) {
        throw ArgumentError('Text entries must include content after editing.');
      }

      await _eventService.writeEvent(
        ChronicleEventDraft(
          eventType: 'EntryEdited',
          entryId: entryId,
          payload: <String, Object?>{'content': normalizedContent},
          createdAt: editedAt,
        ),
        executor: transaction,
      );

      await transaction.update(
        ChronicleSchema.entryIndexTable,
        <String, Object?>{'content': normalizedContent, 'updated_at': editedAt},
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
      final newTags = _extractTags(content).toSet();

      final tagsToRemove = existingTags.difference(newTags).toList()..sort();
      final tagsToAdd = newTags.difference(existingTags).toList()..sort();

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
        tags: List<String>.of(newTags.toList()..sort(), growable: false),
        createdAt: createdAt,
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
