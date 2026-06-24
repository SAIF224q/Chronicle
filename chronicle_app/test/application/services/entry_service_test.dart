import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:chronicle_app/src/application/services/entry_service.dart';
import 'package:chronicle_app/src/storage/database/database_service.dart';
import 'package:chronicle_app/src/storage/events/event_service.dart';
import 'package:chronicle_app/src/storage/media/media_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EntryService', () {
    late Directory tempDirectory;
    late DatabaseService databaseService;
    late EventService eventService;
    late MediaManager mediaManager;
    late EntryService entryService;

    setUpAll(() {
      sqfliteFfiInit();
    });

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('chronicle_entry_');
      databaseService = DatabaseService(
        documentsDirectoryProvider: () async => tempDirectory,
        factory: databaseFactoryFfi,
      );
      await databaseService.initializeDatabase();
      eventService = EventService(databaseService);
      mediaManager = MediaManager(
        documentsDirectoryProvider: () async => tempDirectory,
      );
      entryService = EntryService(
        databaseService: databaseService,
        eventService: eventService,
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
      'createEntry writes entry and tag events and updates index tables',
      () async {
        final entry = await entryService.createEntry(
          content: 'Interesting idea #startup #ai',
        );

        expect(entry.entryId, 1);
        expect(entry.type, 'text');
        expect(entry.mediaPath, isNull);
        expect(entry.tags, <String>['startup', 'ai']);

        final events = await databaseService.rawQuery('''
        SELECT event_type, entry_id, payload, created_at
        FROM events
        ORDER BY id
        ''');
        expect(events, hasLength(3));
        expect(events[0]['event_type'], 'EntryCreated');
        expect(events[1]['event_type'], 'TagAdded');
        expect(events[2]['event_type'], 'TagAdded');
        expect(events.every((event) => event['entry_id'] == 1), isTrue);

        final entryPayload =
            jsonDecode(events[0]['payload']! as String) as Map<String, dynamic>;
        expect(entryPayload['type'], 'text');
        expect(entryPayload['content'], 'Interesting idea #startup #ai');
        expect(entryPayload['media_path'], isNull);

        final tagPayloads = events
            .skip(1)
            .map(
              (event) =>
                  jsonDecode(event['payload']! as String)
                      as Map<String, dynamic>,
            )
            .map((payload) => payload['tag'])
            .toList();
        expect(tagPayloads, <String>['startup', 'ai']);

        final entryIndexRows = await databaseService.rawQuery('''
        SELECT entry_id, type, content, media_path, archived
        FROM entry_index
        ''');
        expect(entryIndexRows, hasLength(1));
        expect(entryIndexRows.single['entry_id'], 1);
        expect(entryIndexRows.single['type'], 'text');
        expect(
          entryIndexRows.single['content'],
          'Interesting idea #startup #ai',
        );
        expect(entryIndexRows.single['media_path'], isNull);
        expect(entryIndexRows.single['archived'], 0);

        final entryTagRows = await databaseService.rawQuery('''
        SELECT entry_id, tag
        FROM entry_tags
        ORDER BY rowid
        ''');
        expect(entryTagRows, <Map<String, Object?>>[
          <String, Object?>{'entry_id': 1, 'tag': 'startup'},
          <String, Object?>{'entry_id': 1, 'tag': 'ai'},
        ]);
      },
    );

    test('createEntry saves image and stores relative media path', () async {
      final sourceImage = File('${tempDirectory.path}/picked.jpg');
      await sourceImage.writeAsBytes(<int>[1, 2, 3, 4]);

      final entry = await entryService.createEntry(
        content: 'Photo memory #travel',
        image: sourceImage,
      );

      expect(entry.entryId, 1);
      expect(entry.type, 'image');
      expect(entry.mediaPath, startsWith('/media/images/'));
      expect(entry.tags, <String>['travel']);

      final savedImage = File(
        '${tempDirectory.path}/chronicle${entry.mediaPath!.replaceAll('/', Platform.pathSeparator)}',
      );
      expect(await savedImage.exists(), isTrue);
      expect(await savedImage.readAsBytes(), <int>[1, 2, 3, 4]);

      final entryIndexRows = await databaseService.rawQuery('''
        SELECT type, media_path
        FROM entry_index
        ''');
      expect(entryIndexRows.single['type'], 'image');
      expect(entryIndexRows.single['media_path'], entry.mediaPath);
    });

    test('createEntry saves voiceNote and stores relative media path', () async {
      final sourceVoice = File('${tempDirectory.path}/note.m4a');
      await sourceVoice.writeAsBytes(<int>[5, 6, 7, 8]);

      final entry = await entryService.createEntry(
        content: 'Voice message #audio',
        voiceNote: sourceVoice,
      );

      expect(entry.entryId, 1);
      expect(entry.type, 'voice');
      expect(entry.mediaPath, startsWith('/media/images/'));
      expect(entry.tags, <String>['audio']);

      final savedVoice = File(
        '${tempDirectory.path}/chronicle${entry.mediaPath!.replaceAll('/', Platform.pathSeparator)}',
      );
      expect(await savedVoice.exists(), isTrue);
      expect(await savedVoice.readAsBytes(), <int>[5, 6, 7, 8]);

      final entryIndexRows = await databaseService.rawQuery('''
        SELECT type, media_path
        FROM entry_index
        ''');
      expect(entryIndexRows.single['type'], 'voice');
      expect(entryIndexRows.single['media_path'], entry.mediaPath);
    });

    test(
      'createEntry uses incremental entry ids and unique lowercase tags',
      () async {
        await entryService.createEntry(content: 'First #AI #ai #Notes');
        final secondEntry = await entryService.createEntry(content: 'Second');

        expect(secondEntry.entryId, 2);

        final entryTagRows = await databaseService.rawQuery('''
        SELECT entry_id, tag
        FROM entry_tags
        ORDER BY rowid
        ''');
        expect(entryTagRows, <Map<String, Object?>>[
          <String, Object?>{'entry_id': 1, 'tag': 'ai'},
          <String, Object?>{'entry_id': 1, 'tag': 'notes'},
        ]);
      },
    );

    test('editEntry updates content, tags and edited timestamp', () async {
      final created = await entryService.createEntry(
        content: 'Old content #ideas #travel',
      );

      await Future<void>.delayed(const Duration(milliseconds: 5));
      final edited = await entryService.editEntry(
        entryId: created.entryId,
        content: 'Updated content #ideas #work',
      );

      expect(edited.entryId, created.entryId);
      expect(edited.content, 'Updated content #ideas #work');
      expect(edited.tags, <String>['ideas', 'work']);

      final entryIndexRows = await databaseService.rawQuery(
        '''
        SELECT content, updated_at
        FROM entry_index
        WHERE entry_id = ?
      ''',
        <Object?>[created.entryId],
      );
      expect(entryIndexRows.single['content'], 'Updated content #ideas #work');
      expect(entryIndexRows.single['updated_at'], isA<int>());

      final entryTagRows = await databaseService.rawQuery(
        '''
        SELECT tag
        FROM entry_tags
        WHERE entry_id = ?
        ORDER BY tag ASC
      ''',
        <Object?>[created.entryId],
      );
      expect(entryTagRows.map((row) => row['tag']).toList(), <Object?>[
        'ideas',
        'work',
      ]);

      final eventRows = await databaseService.rawQuery(
        '''
        SELECT event_type
        FROM events
        WHERE entry_id = ?
        ORDER BY id ASC
      ''',
        <Object?>[created.entryId],
      );
      expect(eventRows.map((row) => row['event_type']).toList(), <Object?>[
        'EntryCreated',
        'TagAdded',
        'TagAdded',
        'EntryEdited',
        'TagRemoved',
        'TagAdded',
      ]);
    });

    test('hideEntry hides message in place and records event', () async {
      final created = await entryService.createEntry(content: 'Secret note');

      await entryService.hideEntry(entryId: created.entryId);

      final entryIndexRows = await databaseService.rawQuery(
        '''
        SELECT hidden, content
        FROM entry_index
        WHERE entry_id = ?
      ''',
        <Object?>[created.entryId],
      );
      expect(entryIndexRows.single['hidden'], 1);
      expect(entryIndexRows.single['content'], 'Secret note');

      final eventRows = await databaseService.rawQuery(
        '''
        SELECT event_type
        FROM events
        WHERE entry_id = ?
        ORDER BY id ASC
      ''',
        <Object?>[created.entryId],
      );
      expect(eventRows.map((row) => row['event_type']).toList(), <Object?>[
        'EntryCreated',
        'EntryHidden',
      ]);
    });

    test('createEntry saves location details correctly', () async {
      final entry = await entryService.createEntry(
        content: 'Journaling at a coffee shop',
        locationName: 'Coffee Shop, Seattle',
        latitude: 47.6062,
        longitude: -122.3321,
      );

      expect(entry.entryId, 1);
      expect(entry.locationName, 'Coffee Shop, Seattle');
      expect(entry.latitude, 47.6062);
      expect(entry.longitude, -122.3321);

      final entryIndexRows = await databaseService.rawQuery('''
        SELECT location_name, latitude, longitude
        FROM entry_index
        WHERE entry_id = ?
      ''', [entry.entryId]);
      
      expect(entryIndexRows.single['location_name'], 'Coffee Shop, Seattle');
      expect(entryIndexRows.single['latitude'], 47.6062);
      expect(entryIndexRows.single['longitude'], -122.3321);

      final eventRows = await databaseService.rawQuery('''
        SELECT payload
        FROM events
        WHERE entry_id = ? AND event_type = 'EntryCreated'
      ''', [entry.entryId]);
      
      final payload = jsonDecode(eventRows.single['payload']! as String) as Map<String, dynamic>;
      expect(payload['location_name'], 'Coffee Shop, Seattle');
      expect(payload['latitude'], 47.6062);
      expect(payload['longitude'], -122.3321);
    });

    test('createEntry stores custom mood in index and payload', () async {
      final entry = await entryService.createEntry(
        content: 'Feeling great!',
        mood: 'hype',
      );

      expect(entry.mood, 'hype');

      final entryIndexRows = await databaseService.rawQuery('''
        SELECT mood
        FROM entry_index
        WHERE entry_id = ?
      ''', [entry.entryId]);
      expect(entryIndexRows.single['mood'], 'hype');

      final eventRows = await databaseService.rawQuery('''
        SELECT payload
        FROM events
        WHERE entry_id = ? AND event_type = 'EntryCreated'
      ''', [entry.entryId]);
      final payload = jsonDecode(eventRows.single['payload']! as String) as Map<String, dynamic>;
      expect(payload['mood'], 'hype');
    });

    test('editEntry updates mood in index and payload', () async {
      final entry = await entryService.createEntry(content: 'Just woke up');
      expect(entry.mood, 'none');

      final edited = await entryService.editEntry(
        entryId: entry.entryId,
        content: 'Feeling awesome now!',
        mood: 'hype',
      );
      expect(edited.mood, 'hype');

      final entryIndexRows = await databaseService.rawQuery('''
        SELECT mood
        FROM entry_index
        WHERE entry_id = ?
      ''', [entry.entryId]);
      expect(entryIndexRows.single['mood'], 'hype');

      final eventRows = await databaseService.rawQuery('''
        SELECT payload
        FROM events
        WHERE entry_id = ? AND event_type = 'EntryEdited'
      ''', [entry.entryId]);
      final payload = jsonDecode(eventRows.single['payload']! as String) as Map<String, dynamic>;
      expect(payload['mood'], 'hype');
    });

    test('editEntry preserves existing mood if not specified', () async {
      final entry = await entryService.createEntry(
        content: 'Chilling out',
        mood: 'chill',
      );
      expect(entry.mood, 'chill');

      final edited = await entryService.editEntry(
        entryId: entry.entryId,
        content: 'Still chilling, but editing text',
      );
      expect(edited.mood, 'chill');

      final entryIndexRows = await databaseService.rawQuery('''
        SELECT mood
        FROM entry_index
        WHERE entry_id = ?
      ''', [entry.entryId]);
      expect(entryIndexRows.single['mood'], 'chill');
    });
  });
}
