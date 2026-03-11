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
    required this.tags,
  });

  final int entryId;
  final String type;
  final String content;
  final String? mediaPath;
  final File? mediaFile;
  final DateTime createdAt;
  final List<String> tags;
}

class TimelineService {
  TimelineService({
    required TimelineQueryService timelineQueryService,
    required MediaManager mediaManager,
  }) : _timelineQueryService = timelineQueryService,
       _mediaManager = mediaManager;

  final TimelineQueryService _timelineQueryService;
  final MediaManager _mediaManager;

  Future<List<TimelineEntry>> loadTimelineEntries({String? tag}) async {
    final rows = await _timelineQueryService.fetchTimelineEntries(tag: tag);
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
            tags: List<String>.of(row.tags, growable: false),
          );
        })
        .toList(growable: false);
  }
}
