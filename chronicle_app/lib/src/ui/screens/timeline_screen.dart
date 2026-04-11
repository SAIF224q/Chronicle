import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/services/entry_service.dart';
import '../../application/services/export_service.dart';
import '../../application/services/timeline_service.dart';
import '../../storage/database/database_service.dart';
import 'create_entry_screen.dart';
import 'edit_entry_screen.dart';
import 'image_viewer_screen.dart';
import '../widgets/timeline_item.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({
    super.key,
    required this.timelineService,
    required this.entryService,
    required this.databaseService,
  });

  final TimelineService timelineService;
  final EntryService entryService;
  final DatabaseService databaseService;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late Future<List<TimelineEntry>> _timelineFuture;
  String? _activeTagFilter;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  void _loadTimeline({String? tag}) {
    _activeTagFilter = tag;
    _timelineFuture = widget.timelineService.loadTimelineEntries(tag: tag);
  }

  void _handleTagTap(String tag) {
    setState(() {
      _loadTimeline(tag: tag);
    });
  }

  void _clearFilter() {
    setState(() {
      _loadTimeline();
    });
  }

  Future<void> _openCreateEntryScreen() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) {
          return CreateEntryScreen(entryService: widget.entryService);
        },
      ),
    );

    if (!mounted || saved != true) {
      return;
    }

    setState(() {
      _loadTimeline(tag: _activeTagFilter);
    });
  }

  Future<void> _openEditEntryScreen(TimelineEntry entry) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) {
          return EditEntryScreen(
            entryService: widget.entryService,
            entryId: entry.entryId,
            initialContent: entry.content,
          );
        },
      ),
    );

    if (!mounted || saved != true) {
      return;
    }

    setState(() {
      _loadTimeline(tag: _activeTagFilter);
    });
  }

  Future<void> _openImageViewer(File file) async {
    if (!await file.exists()) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image file is unavailable.')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return ImageViewerScreen(file: file);
        },
      ),
    );
  }

  Future<void> _exportData() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final exportService = ExportService(
        databaseService: widget.databaseService,
      );

      final result = await exportService.exportJournal();

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(result.archiveFile.path)],
          text: 'Chronicle Journal Export',
          sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported ${result.entryCount} entries with ${result.mediaFileCount} images',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chronicle'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') {
                _exportData();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'export',
                enabled: !_isExporting,
                child: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Row(
                        children: [
                          Icon(Icons.download, size: 20),
                          SizedBox(width: 12),
                          Text('Export Data'),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<TimelineEntry>>(
        future: _timelineFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load the timeline right now.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final entries = snapshot.data ?? const <TimelineEntry>[];
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (_activeTagFilter != null) ...<Widget>[
                      _ActiveFilterBanner(
                        tag: _activeTagFilter!,
                        onClear: _clearFilter,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      _activeTagFilter == null
                          ? 'No entries yet. Your Chronicle timeline will appear here.'
                          : 'No entries found for #$_activeTagFilter.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: <Widget>[
              if (_activeTagFilter != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _ActiveFilterBanner(
                    tag: _activeTagFilter!,
                    onClear: _clearFilter,
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    return TimelineItem(
                      entry: entries[index],
                      onTagTap: _handleTagTap,
                      onEditTap: () => _openEditEntryScreen(entries[index]),
                      onImageTap: _openImageViewer,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateEntryScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ActiveFilterBanner extends StatelessWidget {
  const _ActiveFilterBanner({required this.tag, required this.onClear});

  final String tag;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Filtering by #$tag'),
            const SizedBox(width: 12),
            TextButton(onPressed: onClear, child: const Text('Clear')),
          ],
        ),
      ),
    );
  }
}
