import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:chronicle_app/src/application/services/entry_service.dart';
import 'package:chronicle_app/src/application/services/timeline_service.dart';
import 'package:chronicle_app/src/storage/database/database_service.dart';
import 'package:chronicle_app/src/storage/events/event_service.dart';
import 'package:chronicle_app/src/storage/media/media_manager.dart';
import 'package:chronicle_app/src/storage/query/timeline_query_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimelineService', () {
    late Directory tempDirectory;
    late DatabaseService databaseService;
    late MediaManager mediaManager;
    late TimelineService timelineService;
    late EntryService entryService;

    setUpAll(() {
      sqfliteFfiInit();
    });

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'chronicle_timeline_',
      );
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
    });

    tearDown(() async {
      await databaseService.close();
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'loadTimelineEntries returns newest entries first with tags',
      () async {
        await entryService.createEntry(content: 'Older note #journal');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await entryService.createEntry(content: 'Newer note #ideas #ai');

        final entries = await timelineService.loadTimelineEntries();

        expect(entries, hasLength(2));
        expect(entries[0].content, 'Newer note #ideas #ai');
        expect(entries[0].tags, <String>['ai', 'ideas']);
        expect(entries[1].content, 'Older note #journal');
        expect(entries[1].tags, <String>['journal']);
      },
    );

    test('loadTimelineEntries filters by tag', () async {
      await entryService.createEntry(content: 'Planning note #ideas');
      await entryService.createEntry(content: 'Travel memory #travel');

      final entries = await timelineService.loadTimelineEntries(tag: 'ideas');

      expect(entries, hasLength(1));
      expect(entries.single.content, 'Planning note #ideas');
      expect(entries.single.tags, <String>['ideas']);
    });
  });
}
