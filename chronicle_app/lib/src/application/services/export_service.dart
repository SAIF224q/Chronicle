import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../storage/database/database_service.dart';

typedef ExportDocumentsDirectoryProvider = Future<Directory> Function();

class ExportResult {
  const ExportResult({
    required this.archiveFile,
    required this.entryCount,
    required this.mediaFileCount,
  });

  final File archiveFile;
  final int entryCount;
  final int mediaFileCount;
}

class ExportService {
  ExportService({
    required DatabaseService databaseService,
    ExportDocumentsDirectoryProvider? documentsDirectoryProvider,
  }) : _databaseService = databaseService,
       _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  final DatabaseService _databaseService;
  final ExportDocumentsDirectoryProvider _documentsDirectoryProvider;

  static const String _chronicleDirectoryName = 'chronicle';

  Future<ExportResult> exportJournal() async {
    final exportEntries = await _loadEntries();
    final documentsDirectory = await _documentsDirectoryProvider();
    final chronicleDirectory = await _ensureDirectory(
      Directory(p.join(documentsDirectory.path, _chronicleDirectoryName)),
    );
    final exportTimestamp = DateTime.now().millisecondsSinceEpoch;
    final stagingDirectory = await _ensureDirectory(
      Directory(
        p.join(
          chronicleDirectory.path,
          'export_staging',
          exportTimestamp.toString(),
        ),
      ),
    );
    final mediaStagingDirectory = await _ensureDirectory(
      Directory(p.join(stagingDirectory.path, 'media')),
    );
    final entriesJson = _buildEntriesJson(exportEntries);
    await File(
      p.join(stagingDirectory.path, 'entries.json'),
    ).writeAsString(entriesJson);

    final copiedMediaCount = await _copyReferencedMedia(
      exportEntries: exportEntries,
      chronicleDirectory: chronicleDirectory,
      mediaStagingDirectory: mediaStagingDirectory,
    );

    final archive = await _buildArchiveFromDirectory(stagingDirectory);
    final zipBytes = ZipEncoder().encodeBytes(archive);
    final exportFile = File(
      p.join(chronicleDirectory.path, 'chronicle_export_$exportTimestamp.zip'),
    );
    await exportFile.writeAsBytes(zipBytes, flush: true);
    await stagingDirectory.delete(recursive: true);

    return ExportResult(
      archiveFile: exportFile,
      entryCount: exportEntries.length,
      mediaFileCount: copiedMediaCount,
    );
  }

  Future<List<_ExportEntry>> _loadEntries() async {
    final entryRows = await _databaseService.rawQuery('''
      SELECT entry_id, type, content, media_path, created_at, updated_at, hidden
      FROM entry_index
      ORDER BY created_at ASC, entry_id ASC
      ''');
    final tagRows = await _databaseService.rawQuery('''
      SELECT entry_id, tag
      FROM entry_tags
      ORDER BY entry_id ASC, tag ASC
      ''');

    final tagsByEntryId = <int, List<String>>{};
    for (final row in tagRows) {
      final entryId = row['entry_id']! as int;
      final tag = row['tag']! as String;
      tagsByEntryId.putIfAbsent(entryId, () => <String>[]).add(tag);
    }

    return entryRows
        .map((row) {
          final entryId = row['entry_id']! as int;
          final isHidden = row['hidden'] == 1;
          return _ExportEntry(
            id: entryId,
            type: row['type']! as String,
            content: isHidden
                ? 'Message deleted'
                : (row['content'] as String?) ?? '',
            mediaPath: isHidden ? null : row['media_path'] as String?,
            createdAt: row['created_at']! as int,
            updatedAt: row['updated_at'] as int?,
            isHidden: isHidden,
            tags: isHidden
                ? const <String>[]
                : List<String>.of(tagsByEntryId[entryId] ?? const <String>[]),
          );
        })
        .toList(growable: false);
  }

  String _buildEntriesJson(List<_ExportEntry> exportEntries) {
    final payload = <String, Object?>{
      'entries': exportEntries.map((entry) => entry.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<int> _copyReferencedMedia({
    required List<_ExportEntry> exportEntries,
    required Directory chronicleDirectory,
    required Directory mediaStagingDirectory,
  }) async {
    final copiedMediaPaths = <String>{};
    var copiedMediaCount = 0;

    for (final entry in exportEntries) {
      final mediaPath = entry.mediaPath;
      if (mediaPath == null ||
          mediaPath.isEmpty ||
          !copiedMediaPaths.add(mediaPath)) {
        continue;
      }

      final relativeSegments = mediaPath
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .toList();
      if (relativeSegments.isEmpty) {
        continue;
      }

      final sourceFile = File(
        p.joinAll(<String>[chronicleDirectory.path, ...relativeSegments]),
      );
      if (!await sourceFile.exists()) {
        continue;
      }

      final destinationFile = File(
        p.joinAll(<String>[
          mediaStagingDirectory.path,
          ...relativeSegments.skip(1),
        ]),
      );
      await destinationFile.parent.create(recursive: true);
      await sourceFile.copy(destinationFile.path);
      copiedMediaCount += 1;
    }

    return copiedMediaCount;
  }

  Future<Directory> _ensureDirectory(Directory directory) async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<Archive> _buildArchiveFromDirectory(Directory directory) async {
    final archive = Archive();
    final entities = directory.listSync(recursive: true);

    for (final entity in entities) {
      final relativePath = p.relative(entity.path, from: directory.path);
      final archivePath = relativePath.replaceAll('\\', '/');

      if (entity is Directory) {
        archive.add(ArchiveFile.directory('$archivePath/'));
        continue;
      }

      if (entity is File) {
        archive.add(ArchiveFile.bytes(archivePath, await entity.readAsBytes()));
      }
    }

    return archive;
  }
}

class _ExportEntry {
  const _ExportEntry({
    required this.id,
    required this.type,
    required this.content,
    required this.mediaPath,
    required this.createdAt,
    required this.updatedAt,
    required this.isHidden,
    required this.tags,
  });

  final int id;
  final String type;
  final String content;
  final String? mediaPath;
  final int createdAt;
  final int? updatedAt;
  final bool isHidden;
  final List<String> tags;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'type': type,
      'content': content,
      'media_path': mediaPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'hidden': isHidden,
      'tags': tags,
    };
  }
}
