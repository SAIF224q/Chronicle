import 'package:flutter/material.dart';

import '../application/services/entry_service.dart';
import '../application/services/timeline_service.dart';
import '../storage/database/database_service.dart';
import '../storage/events/event_service.dart';
import '../storage/media/media_manager.dart';
import '../storage/query/timeline_query_service.dart';
import '../ui/screens/timeline_screen.dart';
import '../ui/theme/chronicle_theme.dart';

class ChronicleApp extends StatelessWidget {
  ChronicleApp({
    super.key,
    TimelineService? timelineService,
    EntryService? entryService,
    DatabaseService? databaseService,
  }) : _services = _buildServices(
         timelineService: timelineService,
         entryService: entryService,
         databaseService: databaseService,
       );

  final _AppServices _services;

  static _AppServices _buildServices({
    TimelineService? timelineService,
    EntryService? entryService,
    DatabaseService? databaseService,
  }) {
    if (timelineService != null &&
        entryService != null &&
        databaseService != null) {
      return _AppServices(
        timelineService: timelineService,
        entryService: entryService,
        databaseService: databaseService,
      );
    }

    final dbService = databaseService ?? DatabaseService();
    final mediaManager = MediaManager();
    final eventService = EventService(dbService);

    return _AppServices(
      timelineService:
          timelineService ??
          TimelineService(
            timelineQueryService: TimelineQueryService(dbService),
            mediaManager: mediaManager,
          ),
      entryService:
          entryService ??
          EntryService(
            databaseService: dbService,
            eventService: eventService,
            mediaManager: mediaManager,
          ),
      databaseService: dbService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chronicle',
      theme: ChronicleTheme.buildTheme(),
      home: TimelineScreen(
        timelineService: _services.timelineService,
        entryService: _services.entryService,
        databaseService: _services.databaseService,
      ),
    );
  }
}

class _AppServices {
  const _AppServices({
    required this.timelineService,
    required this.entryService,
    required this.databaseService,
  });

  final TimelineService timelineService;
  final EntryService entryService;
  final DatabaseService databaseService;
}
