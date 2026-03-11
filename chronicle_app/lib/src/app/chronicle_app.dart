import 'package:flutter/material.dart';

import '../application/services/entry_service.dart';
import '../application/services/timeline_service.dart';
import '../storage/database/database_service.dart';
import '../storage/events/event_service.dart';
import '../storage/media/media_manager.dart';
import '../storage/query/timeline_query_service.dart';
import '../ui/screens/timeline_screen.dart';

class ChronicleApp extends StatelessWidget {
  ChronicleApp({
    super.key,
    TimelineService? timelineService,
    EntryService? entryService,
  }) : _services = _buildServices(
         timelineService: timelineService,
         entryService: entryService,
       );

  final _AppServices _services;

  static _AppServices _buildServices({
    TimelineService? timelineService,
    EntryService? entryService,
  }) {
    if (timelineService != null && entryService != null) {
      return _AppServices(
        timelineService: timelineService,
        entryService: entryService,
      );
    }

    final databaseService = DatabaseService();
    final mediaManager = MediaManager();
    final eventService = EventService(databaseService);

    return _AppServices(
      timelineService:
          timelineService ??
          TimelineService(
            timelineQueryService: TimelineQueryService(databaseService),
            mediaManager: mediaManager,
          ),
      entryService:
          entryService ??
          EntryService(
            databaseService: databaseService,
            eventService: eventService,
            mediaManager: mediaManager,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chronicle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF526D5B)),
      ),
      home: TimelineScreen(
        timelineService: _services.timelineService,
        entryService: _services.entryService,
      ),
    );
  }
}

class _AppServices {
  const _AppServices({
    required this.timelineService,
    required this.entryService,
  });

  final TimelineService timelineService;
  final EntryService entryService;
}
