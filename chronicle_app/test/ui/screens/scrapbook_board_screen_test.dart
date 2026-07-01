import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:chronicle_app/src/application/services/entry_service.dart';
import 'package:chronicle_app/src/application/services/settings_service.dart';
import 'package:chronicle_app/src/application/services/timeline_service.dart';
import 'package:chronicle_app/src/storage/database/database_service.dart';
import 'package:chronicle_app/src/storage/media/media_manager.dart';
import 'package:chronicle_app/src/storage/query/timeline_query_service.dart';
import 'package:chronicle_app/src/ui/screens/scrapbook_board_screen.dart';

class _FakeTimelineService extends TimelineService {
  _FakeTimelineService({
    required super.timelineQueryService,
    required super.mediaManager,
  });

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
        tags: const [],
        mood: 'hype',
      ),
      TimelineEntry(
        entryId: 2,
        type: 'text',
        content: 'Just relaxing reading #music',
        mediaPath: null,
        mediaFile: null,
        createdAt: DateTime(2026, 6, 27, 10, 0),
        isHidden: false,
        tags: const ['music'],
        mood: 'chill',
      ),
    ];
  }
}

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService(super.databaseService);

  String theme = 'corkboard';
  String style = 'grid';
  Map<int, Map<String, double>> positions = {};

  @override
  Future<String> getScrapbookBoardTheme() async => theme;

  @override
  Future<void> setScrapbookBoardTheme(String val) async {
    theme = val;
  }

  @override
  Future<String> getScrapbookWashiStyle() async => style;

  @override
  Future<void> setScrapbookWashiStyle(String val) async {
    style = val;
  }

  @override
  Future<Map<int, Map<String, double>>> getScrapbookLayoutPositions() async => positions;

  @override
  Future<void> setScrapbookLayoutPositions(Map<int, Map<String, double>> val) async {
    positions = val;
  }
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
    settingsService = _FakeSettingsService(databaseService);
  });

  testWidgets('ScrapbookBoardScreen renders canvas, sticky notes, and control panel', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ScrapbookBoardScreen(
          timelineService: timelineService,
          settingsService: settingsService,
        ),
      ),
    );

    // Initial load
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Memory Scrapbook'), findsOneWidget);

    // Verify Sticky Notes are rendered
    expect(find.text('Felt so hyped today!'), findsOneWidget);
    expect(find.text('Just relaxing reading #music'), findsOneWidget);

    // Verify backdrop controls
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    expect(find.byIcon(Icons.style_outlined), findsOneWidget);
    expect(find.byIcon(Icons.grid_view), findsOneWidget);
  });

  testWidgets('Tapping floating customization panel triggers sheets', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: ScrapbookBoardScreen(
          timelineService: timelineService,
          settingsService: settingsService,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap theme palette button
    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();

    // Verify backdrop themes options are visible
    expect(find.text('Choose Backdrop Theme'), findsOneWidget);
    expect(find.text('Pastel Aura'), findsOneWidget);
    expect(find.text('Midnight'), findsOneWidget);

    // Tap Pastel Aura
    await tester.tap(find.text('Pastel Aura'));
    await tester.pumpAndSettle();

    // Verify theme updated in fake settings service
    expect(settingsService.theme, 'pastel_aura');

    // Tap washi style button
    await tester.tap(find.byIcon(Icons.style_outlined));
    await tester.pumpAndSettle();

    // Verify styles choices are visible
    expect(find.text('Customize Pin Style'), findsOneWidget);
    expect(find.text('Glitter'), findsOneWidget);
    expect(find.text('Pushpin'), findsOneWidget);

    // Tap Glitter
    await tester.tap(find.text('Glitter'));
    await tester.pumpAndSettle();

    // Verify washi style updated in fake settings
    expect(settingsService.style, 'glitter');
  });

  testWidgets('Dragging sticky notes updates coordinates in settings', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ScrapbookBoardScreen(
          timelineService: timelineService,
          settingsService: settingsService,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final targetText = find.text('Felt so hyped today!');
    expect(targetText, findsOneWidget);

    // Simulate drag gesture
    final dragGesture = await tester.startGesture(tester.getCenter(targetText));
    await dragGesture.moveBy(const Offset(80, 120));
    await dragGesture.up();

    await tester.pumpAndSettle();

    // Verify card position was saved to settings
    expect(settingsService.positions.isNotEmpty, true);
    expect(settingsService.positions[1]!['x'], isNotNull);
  });
}
