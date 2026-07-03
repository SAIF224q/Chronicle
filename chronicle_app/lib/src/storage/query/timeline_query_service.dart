import '../database/database_service.dart';

class TimelineEntryRow {
  const TimelineEntryRow({
    required this.entryId,
    required this.type,
    required this.content,
    required this.mediaPath,
    required this.createdAt,
    required this.updatedAt,
    required this.isHidden,
    required this.tags,
    this.locationName,
    this.latitude,
    this.longitude,
    required this.mood,
    this.unlockAt,
    this.isVent = false,
    this.burnAt,
    this.trackId,
    this.trackTitle,
    this.trackArtist,
    this.trackArtworkUrl,
    this.spotifyUrl,
    this.audioPreviewUrl,
  });

  final int entryId;
  final String type;
  final String content;
  final String? mediaPath;
  final int createdAt;
  final int? updatedAt;
  final bool isHidden;
  final List<String> tags;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String mood;
  final int? unlockAt;
  final bool isVent;
  final int? burnAt;
  final String? trackId;
  final String? trackTitle;
  final String? trackArtist;
  final String? trackArtworkUrl;
  final String? spotifyUrl;
  final String? audioPreviewUrl;
}

class TimelineQueryService {
  TimelineQueryService(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<TimelineEntryRow>> fetchTimelineEntries({
    String? tag,
    String? searchQuery,
    String? mediaTypeFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool sortByOldest = false,
  }) async {
    final whereClauses = <String>['archived = ?'];
    final whereArgs = <Object?>[0];

    final normalizedTag = tag?.trim().toLowerCase();
    if (normalizedTag != null && normalizedTag.isNotEmpty) {
      whereClauses.add('''
        entry_id IN (
          SELECT entry_id FROM entry_tags WHERE tag = ?
        )
      ''');
      whereArgs.add(normalizedTag);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add(
        '((content LIKE ? OR track_title LIKE ? OR track_artist LIKE ?) AND (unlock_at IS NULL OR unlock_at <= ?))',
      );
      final bindQuery = '%${searchQuery.trim()}%';
      whereArgs.add(bindQuery);
      whereArgs.add(bindQuery);
      whereArgs.add(bindQuery);
      whereArgs.add(DateTime.now().millisecondsSinceEpoch);
    }

    if (mediaTypeFilter != null && mediaTypeFilter != 'all') {
      whereClauses.add('type = ?');
      whereArgs.add(mediaTypeFilter);
    }

    if (startDate != null) {
      whereClauses.add('created_at >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch ~/ 1000);
    }

    if (endDate != null) {
      whereClauses.add('created_at <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch ~/ 1000);
    }

    final whereString = whereClauses.join(' AND ');
    final orderBy = sortByOldest ? 'created_at ASC, entry_id ASC' : 'created_at DESC, entry_id DESC';

    final entryRows = await _databaseService.rawQuery(
      '''
      SELECT entry_id, type, content, media_path, created_at,
             updated_at, hidden, location_name, latitude, longitude, mood, unlock_at, is_vent, burn_at,
             track_id, track_title, track_artist, track_artwork_url, spotify_url, audio_preview_url
      FROM entry_index
      WHERE $whereString
      ORDER BY $orderBy
      ''',
      whereArgs,
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
            isHidden: row['hidden'] == 1,
            tags: List<String>.of(tagsByEntryId[entryId] ?? const <String>[]),
            locationName: row['location_name'] as String?,
            latitude: row['latitude'] as double?,
            longitude: row['longitude'] as double?,
            mood: row['mood'] as String? ?? 'none',
            unlockAt: row['unlock_at'] as int?,
            isVent: row['is_vent'] == 1,
            burnAt: row['burn_at'] as int?,
            trackId: row['track_id'] as String?,
            trackTitle: row['track_title'] as String?,
            trackArtist: row['track_artist'] as String?,
            trackArtworkUrl: row['track_artwork_url'] as String?,
            spotifyUrl: row['spotify_url'] as String?,
            audioPreviewUrl: row['audio_preview_url'] as String?,
          );
        })
        .toList(growable: false);
  }

  Future<List<Map<String, Object?>>> fetchDailyMoodCounts(
    int startTimestampSeconds,
    int endTimestampSeconds,
  ) async {
    return await _databaseService.rawQuery(
      '''
      SELECT 
        DATE(created_at, 'unixepoch', 'localtime') as entry_date,
        mood,
        COUNT(mood) as mood_count
      FROM entry_index
      WHERE archived = 0 
        AND created_at >= ? 
        AND created_at <= ?
      GROUP BY entry_date, mood
      ORDER BY entry_date ASC, mood_count DESC
      ''',
      <Object?>[startTimestampSeconds, endTimestampSeconds],
    );
  }

  Future<List<String>> fetchActiveJournalingDates() async {
    final rows = await _databaseService.rawQuery(
      '''
      SELECT DISTINCT DATE(created_at, 'unixepoch', 'localtime') as entry_date
      FROM entry_index
      WHERE archived = 0
      ORDER BY entry_date DESC
      ''',
    );
    return rows.map((row) => row['entry_date']! as String).toList();
  }
}
