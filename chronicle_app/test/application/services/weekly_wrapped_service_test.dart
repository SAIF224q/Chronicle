import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chronicle_app/src/application/services/entry_service.dart';
import 'package:chronicle_app/src/application/services/settings_service.dart';
import 'package:chronicle_app/src/application/services/timeline_service.dart';
import 'package:chronicle_app/src/application/services/weekly_wrapped_service.dart';
import 'package:chronicle_app/src/storage/database/database_service.dart';
import 'package:chronicle_app/src/storage/events/event_service.dart';
import 'package:chronicle_app/src/storage/media/media_manager.dart';
import 'package:chronicle_app/src/storage/query/timeline_query_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WeeklyWrappedService', () {
    late Directory tempDirectory;
    late DatabaseService databaseService;
    late MediaManager mediaManager;
    late TimelineService timelineService;
    late EntryService entryService;
    late SettingsService settingsService;
    late WeeklyWrappedService wrappedService;

    setUpAll(() {
      sqfliteFfiInit();
    });

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('chronicle_wrapped_test_');
      databaseService = DatabaseService(
        documentsDirectoryProvider: () async => tempDirectory,
        factory: databaseFactoryFfi,
      );
      await databaseService.initializeDatabase();
      mediaManager = MediaManager(
        documentsDirectoryProvider: () async => tempDirectory,
      );
      final eventService = EventService(databaseService);
      entryService = EntryService(
        databaseService: databaseService,
        eventService: eventService,
        mediaManager: mediaManager,
      );
      timelineService = TimelineService(
        timelineQueryService: TimelineQueryService(databaseService),
        mediaManager: mediaManager,
      );
      settingsService = SettingsService(databaseService);
      wrappedService = WeeklyWrappedService(
        databaseService: databaseService,
        timelineService: timelineService,
        entryService: entryService,
        settingsService: settingsService,
        mediaManager: mediaManager,
      );
    });

    tearDown(() async {
      await databaseService.close();
      await tempDirectory.delete(recursive: true);
    });

    test('getYearWeekCode calculates correct ISO week code', () {
      final date = DateTime(2026, 6, 24); // A Wednesday
      final code = wrappedService.getYearWeekCode(date);
      expect(code, '2026-W26');
    });

    test('getWeekBoundaries returns correct Monday/Sunday boundaries', () {
      final date = DateTime(2026, 6, 24); // Wednesday
      final boundaries = wrappedService.getWeekBoundaries(date);
      expect(boundaries['start']!.weekday, DateTime.monday);
      expect(boundaries['start']!.day, 22); // Monday, June 22
      expect(boundaries['end']!.weekday, DateTime.sunday);
      expect(boundaries['end']!.day, 28); // Sunday, June 28
    });

    test('checkAndGenerateWeeklyWrapped returns null when user has < 3 entries', () async {
      final now = DateTime.now();
      final sunday = now.add(Duration(days: 7 - now.weekday));
      final testDate = DateTime(sunday.year, sunday.month, sunday.day, 21, 0);

      // Generate only 2 entries in this week range
      await entryService.createEntry(content: 'Entry 1', mood: 'chill');
      await entryService.createEntry(content: 'Entry 2', mood: 'hype');

      final result = await wrappedService.checkAndGenerateWeeklyWrapped(testDate);
      expect(result, isNull);
    });

    test('checkAndGenerateWeeklyWrapped computes stats and inserts entry when >= 3 entries exist', () async {
      final now = DateTime.now();
      final sunday = now.add(Duration(days: 7 - now.weekday));
      final testDate = DateTime(sunday.year, sunday.month, sunday.day, 21, 0);
      final expectedWeekCode = wrappedService.getYearWeekCode(testDate);
      
      // Generate 3 entries in this week range
      await entryService.createEntry(content: 'I am so excited and full of energy #hype', mood: 'hype');
      await entryService.createEntry(content: 'Just relaxing reading #music', mood: 'chill');
      await entryService.createEntry(content: 'Another chill night', mood: 'chill');

      final result = await wrappedService.checkAndGenerateWeeklyWrapped(testDate);
      expect(result, isNotNull);
      expect(result!.type, 'weekly_wrapped');

      final data = json.decode(result.content) as Map<String, dynamic>;
      expect(data['total_entries'], 3);
      expect(data['dominant_mood'], 'chill');
      expect(data['mood_percentages']['chill'], 67);
      expect(data['top_keywords'].contains('#music'), true);
      expect(data['viewed'], false);

      // Verify last weekly wrapped setting was set
      final lastGenerated = await settingsService.getLastWeeklyWrappedDate();
      expect(lastGenerated, expectedWeekCode);
    });

    test('markWeeklyWrappedAsViewed updates the viewed key in database', () async {
      final now = DateTime.now();
      final sunday = now.add(Duration(days: 7 - now.weekday));
      final testDate = DateTime(sunday.year, sunday.month, sunday.day, 21, 0);

      await entryService.createEntry(content: 'Entry 1', mood: 'hype');
      await entryService.createEntry(content: 'Entry 2', mood: 'chill');
      await entryService.createEntry(content: 'Entry 3', mood: 'chill');

      final entry = await wrappedService.checkAndGenerateWeeklyWrapped(testDate);
      expect(entry, isNotNull);

      await wrappedService.markWeeklyWrappedAsViewed(entry!.entryId);

      final loaded = await timelineService.loadTimelineEntries();
      final wrappedEntry = loaded.firstWhere((e) => e.type == 'weekly_wrapped');
      final data = json.decode(wrappedEntry.content) as Map<String, dynamic>;
      expect(data['viewed'], true);
    });
  });
}
