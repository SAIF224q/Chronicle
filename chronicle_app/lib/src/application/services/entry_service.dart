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
