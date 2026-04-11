import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:chronicle_app/src/app/chronicle_app.dart';
import 'package:chronicle_app/src/application/services/entry_service.dart';
import 'package:chronicle_app/src/application/services/timeline_service.dart';
import 'package:chronicle_app/src/storage/database/database_service.dart';
import 'package:chronicle_app/src/storage/events/event_service.dart';
import 'package:chronicle_app/src/storage/media/media_manager.dart';
import 'package:chronicle_app/src/storage/query/timeline_query_service.dart';

class _FakeTimelineService extends TimelineService {
  _FakeTimelineService({
    required TimelineQueryService timelineQueryService,
    required MediaManager mediaManager,
  }) : super(
         timelineQueryService: timelineQueryService,
         mediaManager: mediaManager,
       );

  @override
  Future<List<TimelineEntry>> loadTimelineEntries({String? tag}) async {
    return const <TimelineEntry>[];
  }
}

class _FakeEntryService extends EntryService {
  _FakeEntryService({
    required DatabaseService databaseService,
    required EventService eventService,
    required MediaManager mediaManager,
  }) : super(
         databaseService: databaseService,
         eventService: eventService,
         mediaManager: mediaManager,
       );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders Chronicle shell', (WidgetTester tester) async {
    sqfliteFfiInit();
    final testDbService = DatabaseService(
      documentsDirectoryProvider: () async => Directory.systemTemp,
      factory: databaseFactoryFfi,
    );
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
        databaseService: testDbService,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Chronicle'), findsOneWidget);
    expect(
      find.text('No entries yet. Your Chronicle timeline will appear here.'),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
