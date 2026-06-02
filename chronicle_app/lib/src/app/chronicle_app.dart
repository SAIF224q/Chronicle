import 'package:flutter/material.dart';

import '../application/services/entry_service.dart';
import '../application/services/settings_service.dart';
import '../application/services/timeline_service.dart';
import '../storage/database/database_service.dart';
import '../storage/events/event_service.dart';
import '../storage/media/media_manager.dart';
import '../storage/query/timeline_query_service.dart';
import '../ui/screens/timeline_screen.dart';
import '../ui/theme/chronicle_theme.dart';

class ChronicleApp extends StatefulWidget {
  ChronicleApp({
    super.key,
    TimelineService? timelineService,
    EntryService? entryService,
    SettingsService? settingsService,
    DatabaseService? databaseService,
  }) : _services = _buildServices(
         timelineService: timelineService,
         entryService: entryService,
         settingsService: settingsService,
         databaseService: databaseService,
       );

  final _AppServices _services;

  static _AppServices _buildServices({
    TimelineService? timelineService,
    EntryService? entryService,
    SettingsService? settingsService,
    DatabaseService? databaseService,
  }) {
    if (timelineService != null &&
        entryService != null &&
        settingsService != null &&
        databaseService != null) {
      return _AppServices(
        timelineService: timelineService,
        entryService: entryService,
        settingsService: settingsService,
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
      settingsService: settingsService ?? SettingsService(dbService),
      databaseService: dbService,
    );
  }

  @override
  State<ChronicleApp> createState() => _ChronicleAppState();
}

class _ChronicleAppState extends State<ChronicleApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initTheme();
  }

  Future<void> _initTheme() async {
    await widget._services.databaseService.initializeDatabase();
    await widget._services.settingsService.initializeTheme();
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: widget._services.settingsService.themeNotifier,
      builder: (context, themeName, child) {
        return MaterialApp(
          title: 'Chronicle',
          theme: ChronicleTheme.buildTheme(themeName),
          home: TimelineScreen(
            timelineService: widget._services.timelineService,
            entryService: widget._services.entryService,
            settingsService: widget._services.settingsService,
            databaseService: widget._services.databaseService,
          ),
        );
      },
    );
  }
}

class _AppServices {
  const _AppServices({
    required this.timelineService,
    required this.entryService,
    required this.settingsService,
    required this.databaseService,
  });

  final TimelineService timelineService;
  final EntryService entryService;
  final SettingsService settingsService;
  final DatabaseService databaseService;
}
