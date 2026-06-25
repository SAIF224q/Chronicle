import 'dart:io';

import 'package:path/path.dart' as p;

import '../../storage/media/media_manager.dart';
import '../../storage/query/timeline_query_service.dart';

class TimelineEntry {
  const TimelineEntry({
    required this.entryId,
    required this.type,
    required this.content,
    required this.mediaPath,
    required this.mediaFile,
    required this.createdAt,
    this.updatedAt,
    required this.isHidden,
    required this.tags,
    this.locationName,
    this.latitude,
    this.longitude,
    required this.mood,
    this.transcript,
  });

  final int entryId;
  final String type;
  final String content;
  final String? mediaPath;
  final File? mediaFile;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isHidden;
  final List<String> tags;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String mood;
  final String? transcript;
}

class TimelineService {
  TimelineService({
    required TimelineQueryService timelineQueryService,
    required MediaManager mediaManager,
  }) : _timelineQueryService = timelineQueryService,
       _mediaManager = mediaManager;

  final TimelineQueryService _timelineQueryService;
  final MediaManager _mediaManager;

  Future<List<TimelineEntry>> loadTimelineEntries({
    String? tag,
    String? searchQuery,
    String? mediaTypeFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool sortByOldest = false,
  }) async {
    final rows = await _timelineQueryService.fetchTimelineEntries(
      tag: tag,
      searchQuery: searchQuery,
      mediaTypeFilter: mediaTypeFilter,
      startDate: startDate,
      endDate: endDate,
      sortByOldest: sortByOldest,
    );
    final mediaDirectory = await _mediaManager.getMediaDirectory();

    return rows
        .map((row) {
          final mediaFile = row.mediaPath == null
              ? null
              : File(p.join(mediaDirectory.path, p.basename(row.mediaPath!)));

          return TimelineEntry(
            entryId: row.entryId,
            type: row.type,
            content: row.content,
            mediaPath: row.mediaPath,
            mediaFile: mediaFile,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              row.createdAt * 1000,
            ),
            updatedAt: row.updatedAt == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(row.updatedAt! * 1000),
            isHidden: row.isHidden,
            tags: List<String>.of(row.tags, growable: false),
            locationName: row.locationName,
            latitude: row.latitude,
            longitude: row.longitude,
            mood: row.mood,
            transcript: row.transcript,
          );
        })
        .toList(growable: false);
  }
}
