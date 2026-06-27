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
        expect(entries[0].isHidden, isFalse);
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

    test('loadTimelineEntries searches text content and location', () async {
      await entryService.createEntry(
        content: 'Went to the grocery store to buy apples',
        locationName: 'Supermarket',
      );
      await entryService.createEntry(
        content: 'Relaxing at home',
        locationName: 'My House',
      );

      final searchResults = await timelineService.loadTimelineEntries(searchQuery: 'grocery');
      expect(searchResults, hasLength(1));
      expect(searchResults.single.content, contains('grocery'));
    });

    test('loadTimelineEntries filters by media type and sort order', () async {
      await entryService.createEntry(content: 'Just text entry');
      
      final sourceImage = File('${tempDirectory.path}/test_img.jpg');
      await sourceImage.writeAsBytes(<int>[1, 2, 3]);
      await entryService.createEntry(
        content: 'Entry with image',
        image: sourceImage,
      );

      final textOnly = await timelineService.loadTimelineEntries(mediaTypeFilter: 'text');
      expect(textOnly, hasLength(1));
      expect(textOnly.single.content, 'Just text entry');

      final imageOnly = await timelineService.loadTimelineEntries(mediaTypeFilter: 'image');
      expect(imageOnly, hasLength(1));
      expect(imageOnly.single.content, 'Entry with image');

      final oldestFirst = await timelineService.loadTimelineEntries(sortByOldest: true);
      expect(oldestFirst, hasLength(2));
      expect(oldestFirst.first.content, 'Just text entry');
      expect(oldestFirst.last.content, 'Entry with image');
    });

    test('loadTimelineEntries returns correct mood values', () async {
      await entryService.createEntry(
        content: 'Chilling out',
        mood: 'chill',
      );
      await entryService.createEntry(
        content: 'Hype vibe',
        mood: 'hype',
      );

      final entries = await timelineService.loadTimelineEntries();
      expect(entries, hasLength(2));
      expect(entries[0].content, 'Hype vibe');
      expect(entries[0].mood, 'hype');
      expect(entries[1].content, 'Chilling out');
      expect(entries[1].mood, 'chill');
    });

    test('loadTimelineEntries text search ignores locked entries', () async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final unlockFuture = nowMs + 1000 * 60 * 60; // 1 hour in future

      await entryService.createEntry(
        content: 'Secret locked time capsule content',
        unlockAt: unlockFuture,
      );

      await entryService.createEntry(
        content: 'Unlocked visible content',
      );

      // Searching for "content" should only match the unlocked one
      final searchResults = await timelineService.loadTimelineEntries(searchQuery: 'content');
      expect(searchResults, hasLength(1));
      expect(searchResults.single.content, 'Unlocked visible content');
      
      // Loading timeline without search query should return both, but one is locked
      final allEntries = await timelineService.loadTimelineEntries(sortByOldest: true);
      expect(allEntries, hasLength(2));
      expect(allEntries[0].isLocked, isTrue);
      expect(allEntries[1].isLocked, isFalse);
    });
  });
}
