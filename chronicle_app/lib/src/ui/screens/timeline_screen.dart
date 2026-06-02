import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/services/entry_service.dart';
import '../../application/services/export_service.dart';
import '../../application/services/settings_service.dart';
import '../../application/services/timeline_service.dart';
import '../../storage/database/database_service.dart';
import 'create_entry_screen.dart';
import 'edit_entry_screen.dart';
import 'image_viewer_screen.dart';
import 'settings_screen.dart';
import '../widgets/timeline_item.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({
    super.key,
    required this.timelineService,
    required this.entryService,
    required this.settingsService,
    required this.databaseService,
  });

  final TimelineService timelineService;
  final EntryService entryService;
  final SettingsService settingsService;
  final DatabaseService databaseService;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  late Future<List<TimelineEntry>> _timelineFuture;
  String? _activeTagFilter;
  final Set<int> _revealedEntryIds = <int>{};
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

  Future<void> _openSettingsScreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) {
          return SettingsScreen(settingsService: widget.settingsService);
        },
      ),
    );
  }

  Future<void> _hideEntry(TimelineEntry entry) async {
    final hasPassword = await widget.settingsService.hasHiddenMessagePassword();
    if (!mounted) {
      return;
    }

    if (!hasPassword) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Set a reveal password'),
            content: const Text(
              'Hidden messages need a password before they can be revealed.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );

      if (openSettings == true && mounted) {
        await _openSettingsScreen();
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete message?'),
          content: const Text(
            'The message will be hidden in place and can be revealed with the owner password.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hide Message'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.entryService.hideEntry(entryId: entry.entryId);
      if (!mounted) {
        return;
      }
      setState(() {
        _revealedEntryIds.remove(entry.entryId);
        _loadTimeline(tag: _activeTagFilter);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to hide the message right now.')),
      );
    }
  }

  Future<void> _revealEntry(TimelineEntry entry) async {
    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        return const _RevealPasswordDialog();
      },
    );

    if (password == null) {
      return;
    }

    final isValid = await widget.settingsService.verifyHiddenMessagePassword(
      password,
    );
    if (!mounted) {
      return;
    }

    if (!isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incorrect password.')));
      return;
    }

    setState(() {
      _revealedEntryIds.add(entry.entryId);
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
              } else if (value == 'settings') {
                _openSettingsScreen();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
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
                    final item = TimelineItem(
                      entry: entries[index],
                      isRevealed: _revealedEntryIds.contains(
                        entries[index].entryId,
                      ),
                      onTagTap: _handleTagTap,
                      onEditTap: () => _openEditEntryScreen(entries[index]),
                      onDeleteTap: () => _hideEntry(entries[index]),
                      onHiddenPlaceholderTap: () =>
                          _revealEntry(entries[index]),
                      onImageTap: _openImageViewer,
                    );

                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 350 + (index * 40).clamp(0, 300)),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 15 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: item,
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

class _RevealPasswordDialog extends StatefulWidget {
  const _RevealPasswordDialog();

  @override
  State<_RevealPasswordDialog> createState() => _RevealPasswordDialogState();
}

class _RevealPasswordDialogState extends State<_RevealPasswordDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reveal message'),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Password',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Reveal')),
      ],
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
