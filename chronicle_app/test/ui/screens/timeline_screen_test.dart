import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:chronicle_app/src/application/services/entry_service.dart';
import 'package:chronicle_app/src/application/services/settings_service.dart';
import 'package:chronicle_app/src/application/services/timeline_service.dart';
import 'package:chronicle_app/src/storage/database/database_service.dart';
import 'package:chronicle_app/src/storage/events/event_service.dart';
import 'package:chronicle_app/src/storage/media/media_manager.dart';
import 'package:chronicle_app/src/storage/query/timeline_query_service.dart';
import 'package:chronicle_app/src/ui/screens/create_entry_screen.dart';
import 'package:chronicle_app/src/ui/screens/timeline_screen.dart';

class _RecordingTimelineService extends TimelineService {
  _RecordingTimelineService(this._entriesByTag)
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

  final Map<String?, List<TimelineEntry>> _entriesByTag;
  final List<String?> requestedTags = <String?>[];

  @override
  Future<List<TimelineEntry>> loadTimelineEntries({
    String? tag,
    String? searchQuery,
    String? mediaTypeFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool sortByOldest = false,
  }) async {
    requestedTags.add(tag);
    return _entriesByTag[tag] ?? const <TimelineEntry>[];
  }
}

class _RecordingEntryService extends EntryService {
  _RecordingEntryService({required this.onCreate})
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

  final Future<EntryRecord> Function(String content, File? image) onCreate;
  final List<String> createdContents = <String>[];

  @override
  Future<EntryRecord> createEntry({
    required String content,
    File? image,
    File? voiceNote,
    String? locationName,
    double? latitude,
    double? longitude,
    String mood = 'none',
    String? transcript,
  }) async {
    createdContents.add(content);
    return onCreate(content, image);
  }
}

class _FakeSettingsService extends SettingsService {
  _FakeSettingsService()
    : super(
        DatabaseService(
          documentsDirectoryProvider: () async => Directory.systemTemp,
          factory: databaseFactoryFfi,
        ),
      );

  @override
  Future<bool> hasHiddenMessagePassword() async => true;

  @override
  Future<bool> verifyHiddenMessagePassword(String password) async {
    return password == 'secret';
  }
}

void main() {
  sqfliteFfiInit();

  testWidgets('tapping a tag filters timeline and clear removes it', (
    WidgetTester tester,
  ) async {
    final timelineService = _RecordingTimelineService(
      <String?, List<TimelineEntry>>{
        null: <TimelineEntry>[
          TimelineEntry(
            entryId: 2,
            type: 'text',
            content: 'General note #ideas',
            mediaPath: null,
            mediaFile: null,
            createdAt: DateTime(2026, 3, 11, 10, 30),
            isHidden: false,
            tags: const <String>['ideas'],
            mood: 'none',
          ),
          TimelineEntry(
            entryId: 1,
            type: 'text',
            content: 'Travel plan #travel',
            mediaPath: null,
            mediaFile: null,
            createdAt: DateTime(2026, 3, 11, 9, 0),
            isHidden: false,
            tags: const <String>['travel'],
            mood: 'none',
          ),
        ],
        'ideas': <TimelineEntry>[
          TimelineEntry(
            entryId: 2,
            type: 'text',
            content: 'General note #ideas',
            mediaPath: null,
            mediaFile: null,
            createdAt: DateTime(2026, 3, 11, 10, 30),
            isHidden: false,
            tags: const <String>['ideas'],
            mood: 'none',
          ),
        ],
      },
    );

    final databaseService = DatabaseService(
      documentsDirectoryProvider: () async => Directory.systemTemp,
      factory: databaseFactoryFfi,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TimelineScreen(
          timelineService: timelineService,
          entryService: _RecordingEntryService(
            onCreate: (content, image) async {
              return EntryRecord(
                entryId: 99,
                type: 'text',
                content: content,
                mediaPath: null,
                tags: const <String>[],
                createdAt: 0,
                mood: 'none',
              );
            },
          ),
          settingsService: _FakeSettingsService(),
          databaseService: databaseService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('General note #ideas'), findsOneWidget);
    expect(find.text('Travel plan #travel'), findsOneWidget);
    expect(timelineService.requestedTags, <String?>[null]);

    await tester.tap(find.text('#ideas'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Filtering by #ideas'), findsOneWidget);
    expect(find.text('General note #ideas'), findsOneWidget);
    expect(find.text('Travel plan #travel'), findsNothing);
    expect(timelineService.requestedTags, <String?>[null, 'ideas']);

    await tester.tap(find.text('Clear'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Filtering by #ideas'), findsNothing);
    expect(find.text('Travel plan #travel'), findsOneWidget);
    expect(timelineService.requestedTags, <String?>[null, 'ideas', null]);
  });

  testWidgets('saving a new entry returns to timeline and refreshes entries', (
    WidgetTester tester,
  ) async {
    final entriesByTag = <String?, List<TimelineEntry>>{
      null: const <TimelineEntry>[],
    };
    final timelineService = _RecordingTimelineService(entriesByTag);
    final entryService = _RecordingEntryService(
      onCreate: (content, image) async {
        entriesByTag[null] = <TimelineEntry>[
          TimelineEntry(
            entryId: 1,
            type: 'text',
            content: content.trim(),
            mediaPath: null,
            mediaFile: null,
            createdAt: DateTime(2026, 3, 11, 12, 0),
            isHidden: false,
            tags: const <String>[],
            mood: 'none',
          ),
        ];

        return EntryRecord(
          entryId: 1,
          type: 'text',
          content: content.trim(),
          mediaPath: null,
          tags: const <String>[],
          createdAt: 1710158400,
          mood: 'none',
        );
      },
    );

    final testDatabaseService = DatabaseService(
      documentsDirectoryProvider: () async => Directory.systemTemp,
      factory: databaseFactoryFfi,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TimelineScreen(
          timelineService: timelineService,
          entryService: entryService,
          settingsService: _FakeSettingsService(),
          databaseService: testDatabaseService,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No entries yet. Your Chronicle timeline will appear here.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.byType(CreateEntryScreen),
        matching: find.byType(TextField),
      ),
      'Fresh Chronicle note',
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(entryService.createdContents, <String>['Fresh Chronicle note']);
    expect(find.text('Fresh Chronicle note'), findsOneWidget);
    expect(timelineService.requestedTags, <String?>[null, null]);
  });

  testWidgets('hidden entries show placeholder and reveal with password', (
    WidgetTester tester,
  ) async {
    final timelineService = _RecordingTimelineService(
      <String?, List<TimelineEntry>>{
        null: <TimelineEntry>[
          TimelineEntry(
            entryId: 7,
            type: 'text',
            content: 'Private note',
            mediaPath: null,
            mediaFile: null,
            createdAt: DateTime(2026, 3, 11, 12, 0),
            isHidden: true,
            tags: const <String>['private'],
            mood: 'none',
          ),
        ],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TimelineScreen(
          timelineService: timelineService,
          entryService: _RecordingEntryService(
            onCreate: (content, image) async {
              return EntryRecord(
                entryId: 99,
                type: 'text',
                content: content,
                mediaPath: null,
                tags: const <String>[],
                createdAt: 0,
                mood: 'none',
              );
            },
          ),
          settingsService: _FakeSettingsService(),
          databaseService: DatabaseService(
            documentsDirectoryProvider: () async => Directory.systemTemp,
            factory: databaseFactoryFfi,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Message deleted'), findsOneWidget);
    expect(find.text('Private note'), findsNothing);

    await tester.tap(find.text('Message deleted'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'secret',
    );
    await tester.tap(find.text('Reveal'));
    await tester.pumpAndSettle();

    expect(find.text('Private note'), findsOneWidget);
    expect(find.text('#private'), findsOneWidget);
  });
}
