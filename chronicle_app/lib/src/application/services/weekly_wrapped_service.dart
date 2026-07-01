import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../storage/database/database_service.dart';
import '../../storage/database/chronicle_schema.dart';
import '../../storage/media/media_manager.dart';
import 'entry_service.dart';
import 'settings_service.dart';
import 'timeline_service.dart';

class WeeklyWrappedService {
  final DatabaseService _databaseService;
  final TimelineService _timelineService;
  final EntryService _entryService;
  final SettingsService _settingsService;
  final MediaManager _mediaManager;

  WeeklyWrappedService({
    required DatabaseService databaseService,
    required TimelineService timelineService,
    required EntryService entryService,
    required SettingsService settingsService,
    required MediaManager mediaManager,
  })  : _databaseService = databaseService,
        _timelineService = timelineService,
        _entryService = entryService,
        _settingsService = settingsService,
        _mediaManager = mediaManager;

  static const Set<String> _stopWords = {
    'the', 'and', 'a', 'to', 'of', 'in', 'is', 'i', 'it', 'that', 'you', 'he', 'was', 'for', 'on', 'are', 'as',
    'with', 'his', 'they', 'at', 'be', 'this', 'have', 'from', 'or', 'one', 'had', 'by', 'word', 'but', 'not',
    'what', 'all', 'were', 'we', 'when', 'your', 'can', 'said', 'there', 'use', 'an', 'each', 'which', 'she',
    'do', 'how', 'their', 'if', 'will', 'up', 'other', 'about', 'out', 'many', 'then', 'them', 'these', 'so',
    'some', 'her', 'would', 'make', 'like', 'him', 'into', 'time', 'has', 'look', 'two', 'more', 'write', 'go',
    'see', 'no', 'way', 'could', 'my', 'me', 'than', 'first', 'been', 'its', 'who', 'now', 'people', 'just',
    'very', 'after', 'only', 'over', 'did', 'down', 'here', 'before', 'our', 'get', 'also', 'want'
  };

  /// Calculates year-week string code (e.g. '2026-W26') for ISO week.
  String getYearWeekCode(DateTime date) {
    // Find Thursday of this week
    final thursday = date.add(Duration(days: 3 - ((date.weekday - 1) % 7)));
    final firstDayOfYear = DateTime(thursday.year, 1, 1);
    final dayOfYear = thursday.difference(firstDayOfYear).inDays + 1;
    final weekNumber = ((dayOfYear - 1) / 7).floor() + 1;
    return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Calculates Monday 00:00:00 and Sunday 23:59:59 boundaries for a given date's week.
  Map<String, DateTime> getWeekBoundaries(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final sunday = date.add(Duration(days: 7 - date.weekday));
    return {
      'start': DateTime(monday.year, monday.month, monday.day, 0, 0, 0),
      'end': DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59, 999),
    };
  }

  String _formatWeekLabel(DateTime monday, DateTime sunday) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final startMonth = months[monday.month - 1];
    final endMonth = months[sunday.month - 1];

    if (monday.month == sunday.month) {
      return '$startMonth ${monday.day} – ${sunday.day}';
    } else {
      return '$startMonth ${monday.day} – $endMonth ${sunday.day}';
    }
  }

  /// Generates weekly wrapped if criteria met and returns created TimelineEntry, or null if ignored.
  Future<TimelineEntry?> checkAndGenerateWeeklyWrapped(DateTime now) async {
    // 1. Determine target week
    final targetDate = now.weekday == 7 && now.hour >= 20
        ? now
        : now.subtract(Duration(days: now.weekday)); // prev week

    final weekCode = getYearWeekCode(targetDate);
    final lastGenerated = await _settingsService.getLastWeeklyWrappedDate();
    if (lastGenerated == weekCode) {
      return null; // Already generated for this week
    }

    final boundaries = getWeekBoundaries(targetDate);
    final startOfRange = boundaries['start']!;
    final endOfRange = boundaries['end']!;

    // 2. Fetch entries in date range
    final entries = await _timelineService.loadTimelineEntries(
      startDate: startOfRange,
      endDate: endOfRange,
      sortByOldest: true,
    );

    // Filter out bot entries from count
    final userEntries = entries.where((e) => !e.isBot).toList();
    if (userEntries.length < 3) {
      return null; // Not enough data
    }

    // 3. Perform stats calculations
    final totalEntries = userEntries.length;
    double voiceMinutes = 0.0;
    final Map<String, int> moodCounts = {};
    final Map<int, int> hourCounts = {};

    for (final entry in userEntries) {
      // Mood count
      if (entry.mood != 'none') {
        moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      }
      // Peak hour
      final hour = entry.createdAt.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;

      // Voice minutes estimation
      if (entry.type == 'voice' && entry.mediaPath != null) {
        try {
          final mediaDirectory = await _mediaManager.getMediaDirectory();
          final file = File(p.join(mediaDirectory.path, p.basename(entry.mediaPath!)));
          if (await file.exists()) {
            final size = await file.length();
            // Estimating AAC LC 128kbps -> ~16000 bytes/sec
            final seconds = size / 16000.0;
            voiceMinutes += seconds / 60.0;
          }
        } catch (_) {}
      }
    }

    // Find dominant mood
    String dominantMood = 'none';
    if (moodCounts.isNotEmpty) {
      final sortedMoods = moodCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      dominantMood = sortedMoods.first.key;
    }

    // Mood percentages
    final Map<String, int> moodPercentages = {};
    final totalMoodEntries = userEntries.where((e) => e.mood != 'none').length;
    if (totalMoodEntries > 0) {
      moodCounts.forEach((mood, count) {
        moodPercentages[mood] = ((count / totalMoodEntries) * 100).round();
      });
    }

    // Top Keywords
    final topKeywords = _extractTopKeywords(userEntries);

    // Peak hour mode
    int peakHour = 20; // Default 8 PM
    if (hourCounts.isNotEmpty) {
      final sortedHours = hourCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      peakHour = sortedHours.first.key;
    }

    // Streak
    int currentStreak = 0;
    try {
      final streakInfo = await _timelineService.getVibeStreak();
      currentStreak = streakInfo.currentStreak;
    } catch (_) {}

    // 4. Create metadata JSON content
    final payload = {
      'week_label': _formatWeekLabel(startOfRange, endOfRange),
      'start_timestamp': startOfRange.millisecondsSinceEpoch ~/ 1000,
      'end_timestamp': endOfRange.millisecondsSinceEpoch ~/ 1000,
      'total_entries': totalEntries,
      'voice_minutes': double.parse(voiceMinutes.toStringAsFixed(1)),
      'dominant_mood': dominantMood,
      'mood_percentages': moodPercentages,
      'top_keywords': topKeywords,
      'peak_hour': peakHour,
      'streak': currentStreak,
      'viewed': false,
    };

    final contentStr = json.encode(payload);

    // 5. Insert bot entry into timeline database
    final record = await _entryService.createBotEntry(
      content: contentStr,
      type: 'weekly_wrapped',
      mood: dominantMood,
    );

    // 6. Update last weekly wrapped setting date
    await _settingsService.setLastWeeklyWrappedDate(weekCode);

    return TimelineEntry(
      entryId: record.entryId,
      type: 'weekly_wrapped',
      content: contentStr,
      mediaPath: null,
      mediaFile: null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(record.createdAt * 1000),
      isHidden: false,
      tags: const [],
      mood: dominantMood,
    );
  }

  List<String> _extractTopKeywords(List<TimelineEntry> entries) {
    final Map<String, int> frequencies = {};

    for (final entry in entries) {
      for (final tag in entry.tags) {
        final normalized = '#${tag.toLowerCase()}';
        frequencies[normalized] = (frequencies[normalized] ?? 0) + 2; // Weight tags higher
      }
    }

    final cleanWordRegex = RegExp(r'^[a-z]{3,}$');
    for (final entry in entries) {
      final words = entry.content.toLowerCase().split(RegExp(r'[^a-zA-Z#]+'));
      for (final word in words) {
        if (word.isEmpty) continue;
        if (word.startsWith('#')) {
          frequencies[word] = (frequencies[word] ?? 0) + 2;
        } else if (cleanWordRegex.hasMatch(word) && !_stopWords.contains(word)) {
          frequencies[word] = (frequencies[word] ?? 0) + 1;
        }
      }
    }

    final sorted = frequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(8).map((e) => e.key).toList();
  }

  /// Updates viewed status of a weekly wrapped entry inside the sqlite database index.
  Future<void> markWeeklyWrappedAsViewed(int entryId) async {
    await _databaseService.transaction((transaction) async {
      final rows = await transaction.query(
        ChronicleSchema.entryIndexTable,
        where: 'entry_id = ?',
        whereArgs: [entryId],
      );

      if (rows.isNotEmpty) {
        final content = rows.first['content'] as String;
        try {
          final data = json.decode(content) as Map<String, dynamic>;
          data['viewed'] = true;
          final updatedContent = json.encode(data);

          await transaction.update(
            ChronicleSchema.entryIndexTable,
            <String, Object?>{'content': updatedContent},
            where: 'entry_id = ?',
            whereArgs: [entryId],
          );
        } catch (_) {}
      }
    });
  }
}
