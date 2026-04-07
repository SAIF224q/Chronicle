import '../database/database_service.dart';

class TimelineEntryRow {
  const TimelineEntryRow({
    required this.entryId,
    required this.type,
    required this.content,
    required this.mediaPath,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
  });

  final int entryId;
  final String type;
  final String content;
  final String? mediaPath;
  final int createdAt;
  final int? updatedAt;
  final List<String> tags;
}

class TimelineQueryService {
  TimelineQueryService(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<TimelineEntryRow>> fetchTimelineEntries({String? tag}) async {
    final normalizedTag = tag?.trim().toLowerCase();
    final entryRows = normalizedTag == null || normalizedTag.isEmpty
        ? await _databaseService.rawQuery(
            '''
              SELECT entry_id, type, content, media_path, created_at
                     , updated_at
              FROM entry_index
              WHERE archived = ?
              ORDER BY created_at DESC, entry_id DESC
              ''',
            <Object?>[0],
          )
        : await _databaseService.rawQuery(
            '''
              SELECT entry_index.entry_id, entry_index.type, entry_index.content,
                     entry_index.media_path, entry_index.created_at,
                     entry_index.updated_at
              FROM entry_index
              JOIN entry_tags
              ON entry_index.entry_id = entry_tags.entry_id
              WHERE entry_tags.tag = ?
              AND entry_index.archived = ?
              ORDER BY entry_index.created_at DESC, entry_index.entry_id DESC
              ''',
            <Object?>[normalizedTag, 0],
          );

    if (entryRows.isEmpty) {
      return const <TimelineEntryRow>[];
    }

    final entryIds = entryRows.map((row) => row['entry_id']! as int).toList();
    final placeholders = List<String>.filled(entryIds.length, '?').join(', ');
    final tagRows = await _databaseService.rawQuery('''
      SELECT entry_id, tag
      FROM entry_tags
      WHERE entry_id IN ($placeholders)
      ORDER BY entry_id ASC, tag ASC
      ''', entryIds.cast<Object?>());

    final tagsByEntryId = <int, List<String>>{};
    for (final row in tagRows) {
      final entryId = row['entry_id']! as int;
      final tag = row['tag']! as String;
      tagsByEntryId.putIfAbsent(entryId, () => <String>[]).add(tag);
    }

    return entryRows
        .map((row) {
          final entryId = row['entry_id']! as int;
          return TimelineEntryRow(
            entryId: entryId,
            type: row['type']! as String,
            content: (row['content'] as String?) ?? '',
            mediaPath: row['media_path'] as String?,
            createdAt: row['created_at']! as int,
            updatedAt: row['updated_at'] as int?,
            tags: List<String>.of(tagsByEntryId[entryId] ?? const <String>[]),
          );
        })
        .toList(growable: false);
  }
}
