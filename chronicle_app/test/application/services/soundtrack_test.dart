import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

import 'package:chronicle_app/src/application/services/entry_service.dart';
import 'package:chronicle_app/src/application/services/timeline_service.dart';
import 'package:chronicle_app/src/storage/database/database_service.dart';
import 'package:chronicle_app/src/storage/database/chronicle_schema.dart';
import 'package:chronicle_app/src/storage/media/media_manager.dart';
import 'package:chronicle_app/src/storage/events/event_service.dart';
import 'package:chronicle_app/src/storage/query/timeline_query_service.dart';

void main() {
  late DatabaseService databaseService;
  late MediaManager mediaManager;
  late EntryService entryService;
  late TimelineService timelineService;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    databaseService = DatabaseService(
      documentsDirectoryProvider: () async => Directory.systemTemp,
      factory: databaseFactoryFfi,
    );
    // Delete any old databases
    final path = await databaseService.getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    await databaseService.initializeDatabase();
    mediaManager = MediaManager(
      documentsDirectoryProvider: () async => Directory.systemTemp,
    );
    entryService = EntryService(
      databaseService: databaseService,
      eventService: EventService(databaseService),
      mediaManager: mediaManager,
    );
    timelineService = TimelineService(
      timelineQueryService: TimelineQueryService(databaseService),
      mediaManager: mediaManager,
    );
  });

  tearDown(() async {
    await databaseService.close();
  });

  group('Aesthetic Soundtrack Attachment Tests', () {
    test('creates, queries, searches, and clears entry soundtracks', () async {
      // 1. Create an entry with soundtrack details
      final entry = await entryService.createEntry(
        content: 'Cruising through Seattle in the rain',
        trackId: 'track123',
        trackTitle: 'Sweater Weather',
        trackArtist: 'The Neighbourhood',
        trackArtworkUrl: 'https://images.unsplash.com/photo-1475924156734',
        spotifyUrl: 'https://open.spotify.com/track/123',
        audioPreviewUrl: 'https://www.soundhelix.com/song1.mp3',
      );

      // Verify the returned EntryRecord has the fields mapped
      expect(entry.trackId, 'track123');
      expect(entry.trackTitle, 'Sweater Weather');
      expect(entry.trackArtist, 'The Neighbourhood');

      // 2. Query the timeline entries
      final timeline = await timelineService.loadTimelineEntries();
      expect(timeline.length, 1);
      final fetched = timeline.first;
      expect(fetched.hasSoundtrack, true);
      expect(fetched.trackTitle, 'Sweater Weather');
      expect(fetched.trackArtist, 'The Neighbourhood');
      expect(fetched.trackArtworkUrl, 'https://images.unsplash.com/photo-1475924156734');
      expect(fetched.spotifyUrl, 'https://open.spotify.com/track/123');
      expect(fetched.audioPreviewUrl, 'https://www.soundhelix.com/song1.mp3');

      // 3. Verify search matches on track title and artist
      final searchByTitle = await timelineService.loadTimelineEntries(searchQuery: 'sweater');
      expect(searchByTitle.length, 1);

      final searchByArtist = await timelineService.loadTimelineEntries(searchQuery: 'neighbourhood');
      expect(searchByArtist.length, 1);

      final searchNoMatch = await timelineService.loadTimelineEntries(searchQuery: 'pink floyd');
      expect(searchNoMatch.isEmpty, true);

      // 4. Edit entry to remove soundtrack
      final edited = await entryService.editEntry(
        entryId: entry.entryId,
        content: 'Seattle Rain...',
        clearSoundtrack: true,
      );

      expect(edited.trackTitle, isNull);
      expect(edited.trackId, isNull);

      final timelineAfterClear = await timelineService.loadTimelineEntries();
      expect(timelineAfterClear.first.hasSoundtrack, false);
      expect(timelineAfterClear.first.trackTitle, isNull);
    });
  });
}
