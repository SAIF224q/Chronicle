import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:chronicle_app/src/application/services/entry_service.dart';
import 'package:chronicle_app/src/application/services/export_service.dart';
import 'package:chronicle_app/src/storage/database/database_service.dart';
import 'package:chronicle_app/src/storage/events/event_service.dart';
import 'package:chronicle_app/src/storage/media/media_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExportService', () {
    late Directory tempDirectory;
    late DatabaseService databaseService;
    late MediaManager mediaManager;
    late EntryService entryService;
    late ExportService exportService;

    setUpAll(() {
      sqfliteFfiInit();
    });

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'chronicle_export_',
      );
      databaseService = DatabaseService(
        documentsDirectoryProvider: () async => tempDirectory,
        factory: databaseFactoryFfi,
      );
      await databaseService.initializeDatabase();
      mediaManager = MediaManager(
        documentsDirectoryProvider: () async => tempDirectory,
      );
      entryService = EntryService(
        databaseService: databaseService,
        eventService: EventService(databaseService),
        mediaManager: mediaManager,
      );
      exportService = ExportService(
        databaseService: databaseService,
        documentsDirectoryProvider: () async => tempDirectory,
      );
    });

    tearDown(() async {
      await databaseService.close();
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'exportJournal creates zip with entries.json and media files',
      () async {
        await entryService.createEntry(
          content: 'My first Chronicle entry #ideas',
        );
        final sourceImage = File('${tempDirectory.path}/picked.jpg');
        await sourceImage.writeAsBytes(<int>[1, 2, 3, 4]);
        await entryService.createEntry(
          content: 'Photo memory #travel',
          image: sourceImage,
        );

        final entryCountBefore =
            (await databaseService.rawQuery(
                  'SELECT COUNT(*) AS count FROM entry_index',
                )).single['count']!
                as int;
        final tagCountBefore =
            (await databaseService.rawQuery(
                  'SELECT COUNT(*) AS count FROM entry_tags',
                )).single['count']!
                as int;

        final result = await exportService.exportJournal();

        expect(await result.archiveFile.exists(), isTrue);
        expect(result.entryCount, 2);
        expect(result.mediaFileCount, 1);

        final archive = ZipDecoder().decodeBytes(
          await result.archiveFile.readAsBytes(),
        );
        final fileNames = archive.files.map((file) => file.name).toSet();
        expect(fileNames, contains('entries.json'));
        expect(fileNames, contains('media/'));
        expect(fileNames, contains('media/images/'));
        final mediaFileName = fileNames.firstWhere(
          (name) => name.startsWith('media/images/') && name.endsWith('.jpg'),
        );
        expect(mediaFileName, endsWith('.jpg'));

        final entriesJsonFile = archive.files.firstWhere(
          (file) => file.name == 'entries.json',
        );
        final entriesJson =
            jsonDecode(utf8.decode(entriesJsonFile.content))
                as Map<String, dynamic>;
        final entries = entriesJson['entries'] as List<dynamic>;
        expect(entries, hasLength(2));
        expect(entries.first['content'], 'My first Chronicle entry #ideas');
        expect(entries.first['tags'], <String>['ideas']);
        expect(entries.last['type'], 'image');
        expect(entries.last['media_path'], startsWith('/media/images/'));
        expect(entries.last['tags'], <String>['travel']);

        final exportedMediaFile = archive.files.firstWhere(
          (file) => file.name == mediaFileName,
        );
        expect(exportedMediaFile.content, isNotNull);

        final entryCountAfter =
            (await databaseService.rawQuery(
                  'SELECT COUNT(*) AS count FROM entry_index',
                )).single['count']!
                as int;
        final tagCountAfter =
            (await databaseService.rawQuery(
                  'SELECT COUNT(*) AS count FROM entry_tags',
                )).single['count']!
                as int;
        expect(entryCountAfter, entryCountBefore);
        expect(tagCountAfter, tagCountBefore);
      },
    );
  });
}
