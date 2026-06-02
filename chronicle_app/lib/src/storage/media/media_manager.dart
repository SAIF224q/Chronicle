import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef DocumentsDirectoryProvider = Future<Directory> Function();

class MediaManager {
  MediaManager({DocumentsDirectoryProvider? documentsDirectoryProvider})
    : _documentsDirectoryProvider =
          documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  static const String _chronicleDirectoryName = 'chronicle';
  static const String _mediaDirectoryName = 'media';
  static const String _imagesDirectoryName = 'images';

  final DocumentsDirectoryProvider _documentsDirectoryProvider;

  Future<Directory> getMediaDirectory() async {
    final documentsDirectory = await _documentsDirectoryProvider();
    final mediaDirectory = Directory(
      p.join(
        documentsDirectory.path,
        _chronicleDirectoryName,
        _mediaDirectoryName,
        _imagesDirectoryName,
      ),
    );

    if (!await mediaDirectory.exists()) {
      await mediaDirectory.create(recursive: true);
    }

    return mediaDirectory;
  }

  String generateFilename({String extension = '.jpg'}) {
    final now = DateTime.now();
    final normalizedExtension = extension.isEmpty
        ? '.jpg'
        : extension.startsWith('.')
        ? extension.toLowerCase()
        : '.${extension.toLowerCase()}';
    final datePart =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    return '${datePart}_${now.microsecondsSinceEpoch}$normalizedExtension';
  }

  Future<String> saveImage(File image) async {
    if (!await image.exists()) {
      throw ArgumentError.value(
        image.path,
        'image',
        'The source image file does not exist.',
      );
    }

    final mediaDirectory = await getMediaDirectory();
    final extension = p.extension(image.path);

    while (true) {
      final filename = generateFilename(extension: extension);
      final destinationFile = File(p.join(mediaDirectory.path, filename));

      if (await destinationFile.exists()) {
        continue;
      }

      await image.copy(destinationFile.path);
      return '/media/images/$filename';
    }
  }

  Future<String> saveAudio(File audio) async {
    if (!await audio.exists()) {
      throw ArgumentError.value(
        audio.path,
        'audio',
        'The source audio file does not exist.',
      );
    }

    final mediaDirectory = await getMediaDirectory();
    final extension = p.extension(audio.path);

    while (true) {
      final filename = generateFilename(
        extension: extension.isEmpty ? '.m4a' : extension,
      );
      final destinationFile = File(p.join(mediaDirectory.path, filename));

      if (await destinationFile.exists()) {
        continue;
      }

      await audio.copy(destinationFile.path);
      return '/media/images/$filename';
    }
  }
}
