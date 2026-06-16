import 'dart:async';
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

  String _searchQuery = '';
  String _mediaTypeFilter = 'all';
  bool _sortByOldest = false;
  String _dateFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isFilterPanelExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _loadTimeline({String? tag}) {
    if (tag != null) {
      _activeTagFilter = tag;
    }
    _timelineFuture = widget.timelineService.loadTimelineEntries(
      tag: _activeTagFilter,
      searchQuery: _searchQuery,
      mediaTypeFilter: _mediaTypeFilter,
      sortByOldest: _sortByOldest,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query;
        _loadTimeline();
      });
    });
  }

  DateTime? _getStartDateForFilter(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return now.subtract(const Duration(days: 30));
      default:
        return null;
    }
  }

  void _handleTagTap(String tag) {
    setState(() {
      _loadTimeline(tag: tag);
    });
  }

  void _clearFilter() {
    setState(() {
      _activeTagFilter = null;
      _searchQuery = '';
      _searchController.clear();
      _mediaTypeFilter = 'all';
      _sortByOldest = false;
      _dateFilter = 'all';
      _startDate = null;
      _endDate = null;
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
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterPanel(),
          Expanded(
            child: FutureBuilder<List<TimelineEntry>>(
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
                final hasActiveFilters = _activeTagFilter != null ||
                    _searchQuery.isNotEmpty ||
                    _mediaTypeFilter != 'all' ||
                    _dateFilter != 'all';

                if (entries.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (_activeTagFilter != null) ...[
                            _ActiveFilterBanner(
                              tag: _activeTagFilter!,
                              onClear: _clearFilter,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            hasActiveFilters
                                ? 'No entries match your search/filters.'
                                : 'No entries yet. Your Chronicle timeline will appear here.',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          if (hasActiveFilters && _activeTagFilter == null) ...[
                            const SizedBox(height: 16),
                            FilledButton.tonal(
                              onPressed: _clearFilter,
                              child: const Text('Clear All Filters'),
                            ),
                          ],
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateEntryScreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant.withOpacity(0.8)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {});
                  _onSearchChanged(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search thoughts, locations...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                  });
                  _onSearchChanged('');
                },
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: _isFilterPanelExpanded ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              onPressed: () {
                setState(() {
                  _isFilterPanelExpanded = !_isFilterPanelExpanded;
                });
              },
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: !_isFilterPanelExpanded
          ? const SizedBox.shrink()
          : Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Media Type',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'All',
                          selected: _mediaTypeFilter == 'all',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _mediaTypeFilter = 'all';
                                _loadTimeline();
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Text',
                          selected: _mediaTypeFilter == 'text',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _mediaTypeFilter = 'text';
                                _loadTimeline();
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Images',
                          selected: _mediaTypeFilter == 'image',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _mediaTypeFilter = 'image';
                                _loadTimeline();
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Voice Notes',
                          selected: _mediaTypeFilter == 'voice',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _mediaTypeFilter = 'voice';
                                _loadTimeline();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Time Range',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'All Time',
                          selected: _dateFilter == 'all',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _dateFilter = 'all';
                                _startDate = null;
                                _loadTimeline();
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Today',
                          selected: _dateFilter == 'today',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _dateFilter = 'today';
                                _startDate = _getStartDateForFilter('today');
                                _loadTimeline();
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Last 7 Days',
                          selected: _dateFilter == 'week',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _dateFilter = 'week';
                                _startDate = _getStartDateForFilter('week');
                                _loadTimeline();
                              });
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          label: 'Last 30 Days',
                          selected: _dateFilter == 'month',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _dateFilter = 'month';
                                _startDate = _getStartDateForFilter('month');
                                _loadTimeline();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sort Order',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildFilterChip(
                        label: 'Newest First',
                        selected: !_sortByOldest,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _sortByOldest = false;
                              _loadTimeline();
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildFilterChip(
                        label: 'Oldest First',
                        selected: _sortByOldest,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _sortByOldest = true;
                              _loadTimeline();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
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
