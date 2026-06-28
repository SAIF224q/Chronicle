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
    this.unlockAt,
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
  final int? unlockAt;

  bool get isLocked => unlockAt != null && unlockAt! > DateTime.now().millisecondsSinceEpoch;
}

class VibeStreakInfo {
  final int currentStreak;
  final int longestStreak;

  VibeStreakInfo({
    required this.currentStreak,
    required this.longestStreak,
  });
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
            unlockAt: row.unlockAt,
          );
        })
        .toList(growable: false);
  }

  Future<VibeStreakInfo> getVibeStreak() async {
    final activeDates = await _timelineQueryService.fetchActiveJournalingDates();
    return calculateStreak(activeDates, DateTime.now());
  }

  static VibeStreakInfo calculateStreak(List<String> activeDates, DateTime now) {
    if (activeDates.isEmpty) {
      return VibeStreakInfo(currentStreak: 0, longestStreak: 0);
    }

    // Parse strings to DateTime objects representing local dates (midnight)
    final dates = activeDates.map((d) {
      final parts = d.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    }).toSet().toList(); // Ensure unique
    
    // Sort descending
    dates.sort((a, b) => b.compareTo(a));

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    int currentStreak = 0;
    // Check if current streak is active (has entry today or yesterday)
    if (dates.first == today || dates.first == yesterday) {
      currentStreak = 1;
      for (int i = 0; i < dates.length - 1; i++) {
        final diff = dates[i].difference(dates[i + 1]).inDays;
        if (diff == 1) {
          currentStreak++;
        } else if (diff > 1) {
          break; // Streak broken
        }
      }
    }

    // Calculate longest streak
    int longestStreak = 0;
    if (dates.isNotEmpty) {
      int tempStreak = 1;
      longestStreak = 1;
      for (int i = 0; i < dates.length - 1; i++) {
        final diff = dates[i].difference(dates[i + 1]).inDays;
        if (diff == 1) {
          tempStreak++;
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
        } else if (diff > 1) {
          tempStreak = 1;
        }
      }
    }

    return VibeStreakInfo(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  Future<Map<String, String>> getDailyDominantMoods(DateTime startDate, DateTime endDate) async {
    final rows = await _timelineQueryService.fetchDailyMoodCounts(
      startDate.millisecondsSinceEpoch ~/ 1000,
      endDate.millisecondsSinceEpoch ~/ 1000,
    );
    
    // Post-process to select the highest-scoring mood for each date key.
    // Note: the query is ordered by entry_date, mood_count DESC.
    // Because of the ordering, the first row for each entry_date in the results
    // will be the one with the highest mood_count (the dominant mood)!
    final dominantMoods = <String, String>{};
    for (final row in rows) {
      final date = row['entry_date'] as String;
      final mood = row['mood'] as String;
      if (!dominantMoods.containsKey(date)) {
        dominantMoods[date] = mood;
      }
    }
    return dominantMoods;
  }
}

