import 'dart:io';

import 'package:flutter/material.dart';

import '../../application/services/entry_service.dart';
import '../../application/services/timeline_service.dart';
import 'create_entry_screen.dart';
import 'edit_entry_screen.dart';
import 'image_viewer_screen.dart';
import '../widgets/timeline_item.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({
    super.key,
    required this.timelineService,
    required this.entryService,
  });

  final TimelineService timelineService;
  final EntryService entryService;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late Future<List<TimelineEntry>> _timelineFuture;
  String? _activeTagFilter;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chronicle')),
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
