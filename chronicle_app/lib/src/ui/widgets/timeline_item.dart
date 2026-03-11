import 'dart:io';

import 'package:flutter/material.dart';

import '../../application/services/timeline_service.dart';

class TimelineItem extends StatelessWidget {
  const TimelineItem({super.key, required this.entry, required this.onTagTap});

  final TimelineEntry entry;
  final ValueChanged<String> onTagTap;

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
                Text(
                  _formatTimestamp(entry.createdAt),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (entry.content.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    entry.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                if (entry.mediaFile != null) ...<Widget>[
                  const SizedBox(height: 12),
                  _TimelineImage(file: entry.mediaFile!),
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

class _TimelineImage extends StatelessWidget {
  const _TimelineImage({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: file.existsSync()
            ? Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const _MissingMediaPlaceholder();
                },
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
