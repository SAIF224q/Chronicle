import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:chronicle_app/src/app/chronicle_app.dart';
import 'package:chronicle_app/src/application/services/entry_service.dart';
import 'package:chronicle_app/src/application/services/settings_service.dart';
import 'package:chronicle_app/src/application/services/timeline_service.dart';
import 'package:chronicle_app/src/storage/database/database_service.dart';
import 'package:chronicle_app/src/storage/events/event_service.dart';
import 'package:chronicle_app/src/storage/media/media_manager.dart';
import 'package:chronicle_app/src/storage/query/timeline_query_service.dart';

class _FakeTimelineService extends TimelineService {
  _FakeTimelineService({
    required super.timelineQueryService,
    required super.mediaManager,
  });

  @override
  Future<List<TimelineEntry>> loadTimelineEntries({String? tag}) async {
    return const <TimelineEntry>[];
  }
}

class _FakeEntryService extends EntryService {
  _FakeEntryService({
    required super.databaseService,
    required super.eventService,
    required super.mediaManager,
  });
}

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService({required DatabaseService databaseService})
    : super(databaseService);

  @override
  Future<void> initializeTheme() async {
    themeNotifier.value = 'sunset_coral';
  }

  @override
  Future<String> getSelectedTheme() async {
    return 'sunset_coral';
  }

  @override
  Future<void> setSelectedTheme(String themeName) async {
    themeNotifier.value = themeName;
  }
}

class _FakeDatabaseService extends DatabaseService {
  _FakeDatabaseService() : super(factory: databaseFactoryFfi);

  @override
  Future<void> initializeDatabase() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders Chronicle shell', (WidgetTester tester) async {
    sqfliteFfiInit();
    final testDbService = _FakeDatabaseService();
    final timelineQueryService = TimelineQueryService(testDbService);
    final mediaManager = MediaManager(
      documentsDirectoryProvider: () async => Directory.systemTemp,
    );

    await tester.pumpWidget(
      ChronicleApp(
        timelineService: _FakeTimelineService(
          timelineQueryService: timelineQueryService,
          mediaManager: mediaManager,
        ),
        entryService: _FakeEntryService(
          databaseService: testDbService,
          eventService: EventService(testDbService),
          mediaManager: mediaManager,
        ),
        settingsService: _FakeSettingsService(databaseService: testDbService),
        databaseService: testDbService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chronicle'), findsOneWidget);
    expect(
      find.text('No entries yet. Your Chronicle timeline will appear here.'),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
