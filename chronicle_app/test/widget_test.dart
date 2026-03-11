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
  _FakeTimelineService()
    : super(
        timelineQueryService: TimelineQueryService(
          DatabaseService(
            documentsDirectoryProvider: () async => Directory.systemTemp,
            factory: databaseFactoryFfi,
          ),
        ),
        mediaManager: MediaManager(
          documentsDirectoryProvider: () async => Directory.systemTemp,
        ),
      );

  @override
  Future<List<TimelineEntry>> loadTimelineEntries({String? tag}) async {
    return const <TimelineEntry>[];
  }
}

class _FakeEntryService extends EntryService {
  _FakeEntryService()
    : super(
        databaseService: DatabaseService(
          documentsDirectoryProvider: () async => Directory.systemTemp,
          factory: databaseFactoryFfi,
        ),
        eventService: EventService(
          DatabaseService(
            documentsDirectoryProvider: () async => Directory.systemTemp,
            factory: databaseFactoryFfi,
          ),
        ),
        mediaManager: MediaManager(
          documentsDirectoryProvider: () async => Directory.systemTemp,
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders Chronicle shell', (WidgetTester tester) async {
    sqfliteFfiInit();
    await tester.pumpWidget(
      ChronicleApp(
        timelineService: _FakeTimelineService(),
        entryService: _FakeEntryService(),
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
