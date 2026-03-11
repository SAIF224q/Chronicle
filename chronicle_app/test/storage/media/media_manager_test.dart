import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle_app/src/storage/media/media_manager.dart';

class _CollisionMediaManager extends MediaManager {
  _CollisionMediaManager({
    required super.documentsDirectoryProvider,
    required List<String> filenames,
  }) : _filenames = filenames;

  final List<String> _filenames;
  int _index = 0;

  @override
  String generateFilename({String extension = '.jpg'}) {
    final filename = _filenames[_index];
    _index += 1;
    return filename;
  }
}

void main() {
  group('MediaManager', () {
    late Directory tempDirectory;
    late MediaManager mediaManager;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp('chronicle_media_');
      mediaManager = MediaManager(
        documentsDirectoryProvider: () async => tempDirectory,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'getMediaDirectory creates chronicle/media/images structure',
      () async {
        final mediaDirectory = await mediaManager.getMediaDirectory();

        expect(await mediaDirectory.exists(), isTrue);
        expect(
          mediaDirectory.path.replaceAll('\\', '/'),
          endsWith('chronicle/media/images'),
        );
      },
    );

    test('generateFilename uses timestamp-based filenames', () {
      final filename = mediaManager.generateFilename(extension: '.png');

      expect(filename, matches(RegExp(r'^\d{8}_\d+\.png$')));
    });

    test('saveImage copies file and returns a relative media path', () async {
      final sourceImage = File('${tempDirectory.path}/source.jpg');
      await sourceImage.writeAsBytes(<int>[1, 2, 3, 4]);

      final relativePath = await mediaManager.saveImage(sourceImage);
      final filename = relativePath.split('/').last;
      final savedImage = File(
        '${tempDirectory.path}/chronicle/media/images/$filename',
      );

      expect(relativePath, startsWith('/media/images/'));
      expect(await savedImage.exists(), isTrue);
      expect(await savedImage.readAsBytes(), <int>[1, 2, 3, 4]);
    });

    test('saveImage never overwrites an existing file', () async {
      final collisionManager = _CollisionMediaManager(
        documentsDirectoryProvider: () async => tempDirectory,
        filenames: <String>[
          '20260311_1710183382.jpg',
          '20260311_1710183383.jpg',
        ],
      );
      final mediaDirectory = await collisionManager.getMediaDirectory();
      final existingFile = File(
        '${mediaDirectory.path}/20260311_1710183382.jpg',
      );
      await existingFile.writeAsBytes(<int>[9, 9, 9]);

      final sourceImage = File('${tempDirectory.path}/source.jpg');
      await sourceImage.writeAsBytes(<int>[1, 2, 3, 4]);

      final relativePath = await collisionManager.saveImage(sourceImage);
      final savedImage = File('${mediaDirectory.path}/20260311_1710183383.jpg');

      expect(relativePath, '/media/images/20260311_1710183383.jpg');
      expect(await existingFile.readAsBytes(), <int>[9, 9, 9]);
      expect(await savedImage.readAsBytes(), <int>[1, 2, 3, 4]);
    });
  });
}
