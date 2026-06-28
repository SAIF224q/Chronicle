import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chronicle_app/src/application/services/settings_service.dart';
import 'package:chronicle_app/src/application/services/timeline_service.dart';
import 'package:chronicle_app/src/storage/database/database_service.dart';
import 'package:chronicle_app/src/storage/query/timeline_query_service.dart';
import 'package:chronicle_app/src/storage/media/media_manager.dart';
import 'package:chronicle_app/src/ui/screens/vibe_calendar_screen.dart';

class _FakeTimelineService extends TimelineService {
  _FakeTimelineService({
    required super.timelineQueryService,
    required super.mediaManager,
  });

  @override
  Future<Map<String, String>> getDailyDominantMoods(DateTime startDate, DateTime endDate) async {
    return {
      '2026-06-28': 'hype',
      '2026-06-27': 'chill',
    };
  }

  @override
  Future<VibeStreakInfo> getVibeStreak() async {
    return VibeStreakInfo(currentStreak: 2, longestStreak: 5);
  }

  @override
  Future<List<TimelineEntry>> loadTimelineEntries({
    String? tag,
    String? searchQuery,
    String? mediaTypeFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool sortByOldest = false,
  }) async {
    return [
      TimelineEntry(
        entryId: 1,
        type: 'text',
        content: 'Felt so hyped today!',
        mediaPath: null,
        mediaFile: null,
        createdAt: DateTime(2026, 6, 28, 14, 30),
        isHidden: false,
        tags: [],
        mood: 'hype',
      )
    ];
  }
}

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService({required DatabaseService databaseService}) : super(databaseService);

  @override
  Future<int> getVibeCalendarStartDayOfWeek() async => 1; // Monday

  @override
  Future<bool> getVibeCalendarShowStreaks() async => true;
}

void main() {
  late DatabaseService databaseService;
  late TimelineQueryService queryService;
  late MediaManager mediaManager;
  late _FakeTimelineService timelineService;
  late _FakeSettingsService settingsService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseService = DatabaseService(
      documentsDirectoryProvider: () async => Directory.systemTemp,
      factory: databaseFactoryFfi,
    );
    queryService = TimelineQueryService(databaseService);
    mediaManager = MediaManager(
      documentsDirectoryProvider: () async => Directory.systemTemp,
    );
    timelineService = _FakeTimelineService(
      timelineQueryService: queryService,
      mediaManager: mediaManager,
    );
    settingsService = _FakeSettingsService(
      databaseService: databaseService,
    );
  });

  testWidgets('VibeCalendarScreen renders calendar grid and streak cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: VibeCalendarScreen(
          timelineService: timelineService,
          settingsService: settingsService,
        ),
      ),
    );

    // Initial loading
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify main components are present
    expect(find.textContaining('My Vibe Calendar'), findsOneWidget);
    expect(find.textContaining('Current Streak'), findsOneWidget);
    expect(find.text('2 Days'), findsOneWidget);
    expect(find.text('5 Days'), findsOneWidget);

    // Verify grid elements (e.g. weekday headers)
    expect(find.text('M'), findsOneWidget);
    expect(find.text('S'), findsWidgets); // Sunday & Saturday

    // Verify mood legend pills
    expect(find.text('Hype'), findsOneWidget);
    expect(find.text('Chill'), findsOneWidget);
    expect(find.text('Chaotic'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
    expect(find.text('Stressed'), findsOneWidget);
    expect(find.text('Grateful'), findsOneWidget);
  });
}
