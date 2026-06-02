import 'dart:io';

import 'package:flutter/material.dart';

import '../../application/services/timeline_service.dart';
import 'audio_player_widget.dart';

class TimelineItem extends StatelessWidget {
  const TimelineItem({
    super.key,
    required this.entry,
    required this.isRevealed,
    required this.onTagTap,
    required this.onEditTap,
    required this.onDeleteTap,
    required this.onHiddenPlaceholderTap,
    required this.onImageTap,
  });

  final TimelineEntry entry;
  final bool isRevealed;
  final ValueChanged<String> onTagTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onHiddenPlaceholderTap;
  final ValueChanged<File> onImageTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 16),
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Created: ${_formatTimestamp(entry.createdAt)}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    IconButton(
                      onPressed: entry.isHidden && !isRevealed
                          ? null
                          : onEditTap,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Edit entry',
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: entry.isHidden && !isRevealed
                          ? null
                          : onDeleteTap,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Delete message',
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                if (entry.updatedAt != null)
                  Text(
                    'Edited: ${_formatTimestamp(entry.updatedAt!)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (entry.isHidden && !isRevealed) ...<Widget>[
                  const SizedBox(height: 10),
                  _HiddenMessagePlaceholder(onTap: onHiddenPlaceholderTap),
                ] else ...<Widget>[
                  if (entry.content.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      entry.content,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  if (entry.mediaFile != null) ...<Widget>[
                    const SizedBox(height: 12),
                    entry.type == 'voice'
                        ? AudioPlayerWidget(audioFile: entry.mediaFile!)
                        : _TimelineImage(file: entry.mediaFile!, onTap: onImageTap),
                  ],
                  if (entry.tags.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: entry.tags
                          .map(
                            (tag) => ActionChip(
                              label: Text('#$tag'),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                              onPressed: () => onTagTap(tag),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';

    return '${timestamp.day}/${timestamp.month}/${timestamp.year} '
        '$hour:$minute $period';
  }
}

class _HiddenMessagePlaceholder extends StatelessWidget {
  const _HiddenMessagePlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.visibility_off_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Message deleted',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineImage extends StatelessWidget {
  const _TimelineImage({required this.file, required this.onTap});

  final File file;
  final ValueChanged<File> onTap;

  @override
  Widget build(BuildContext context) {
    final exists = file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: exists
            ? InkWell(
                onTap: () => onTap(file),
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const _MissingMediaPlaceholder();
                  },
                ),
              )
            : const _MissingMediaPlaceholder(),
      ),
    );
  }
}

class _MissingMediaPlaceholder extends StatelessWidget {
  const _MissingMediaPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Text(
          'Image unavailable',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
