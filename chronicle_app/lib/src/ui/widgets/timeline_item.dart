import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/services/timeline_service.dart';
import 'audio_player_widget.dart';
import 'vibe_selector_strip.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = _getTextColor(context, entry.mood);
    final secondaryTextColor = _getSecondaryTextColor(context, entry.mood);

    return Align(
      alignment: Alignment.centerLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 500), // Slightly more compact chat feel
            margin: const EdgeInsets.only(bottom: 20), // Better spacing between cards
            decoration: _getBubbleDecoration(context, entry.mood),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (entry.isHidden && !isRevealed) ...<Widget>[
                    _HiddenMessagePlaceholder(onTap: onHiddenPlaceholderTap),
                  ] else ...<Widget>[
                    if (entry.content.isNotEmpty) ...<Widget>[
                      Text(
                        entry.content,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: textColor,
                          fontSize: 16,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (entry.mediaFile != null) ...<Widget>[
                      const SizedBox(height: 12),
                      entry.type == 'voice'
                          ? AudioPlayerWidget(audioFile: entry.mediaFile!)
                          : _TimelineImage(file: entry.mediaFile!, onTap: onImageTap),
                    ],
                    if (entry.locationName != null && entry.locationName!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      _buildLocationChip(context, entry.mood),
                    ],
                    if (entry.tags.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.tags
                            .map((tag) => _buildTagChip(context, tag, entry.mood))
                            .toList(growable: false),
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  // Bottom metadata & action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _formatTimestamp(entry.createdAt) + (entry.updatedAt != null ? ' (edited)' : ''),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: secondaryTextColor.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: entry.isHidden && !isRevealed ? null : onEditTap,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 16,
                            tooltip: 'Edit entry',
                            icon: const Icon(Icons.edit_outlined),
                            color: secondaryTextColor.withOpacity(0.8),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: entry.isHidden && !isRevealed ? null : onDeleteTap,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 16,
                            tooltip: 'Delete message',
                            icon: const Icon(Icons.delete_outline),
                            color: secondaryTextColor.withOpacity(0.8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildMoodBadge(context, entry.mood),
        ],
      ),
    );
  }

  Color _getTextColor(BuildContext context, String mood) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return Colors.white;
    }

    switch (mood) {
      case 'chaotic':
      case 'blue':
      case 'stressed':
        return Colors.white;
      case 'hype':
        return const Color(0xFF78350F); // amber.shade900
      case 'chill':
        return const Color(0xFF3B0764); // purple.shade900
      case 'grateful':
        return const Color(0xFF831843); // pink.shade900
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  Color _getSecondaryTextColor(BuildContext context, String mood) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return Colors.white70;
    }

    switch (mood) {
      case 'chaotic':
      case 'blue':
      case 'stressed':
        return Colors.white70;
      case 'hype':
        return const Color(0xFF92400E);
      case 'chill':
        return const Color(0xFF5B21B6);
      case 'grateful':
        return const Color(0xFF9D174D);
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  Widget _buildLocationChip(BuildContext context, String mood) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSpecialMood = mood != 'none';

    final chipBgColor = isSpecialMood
        ? (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06))
        : null;
    final chipTextColor = _getTextColor(context, mood);

    return ActionChip(
      avatar: Icon(
        Icons.location_on_outlined,
        size: 14,
        color: chipTextColor.withOpacity(0.9),
      ),
      label: Text(entry.locationName!),
      labelStyle: TextStyle(
        color: chipTextColor, 
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      backgroundColor: chipBgColor,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      onPressed: () => _launchLocation(entry.locationName, entry.latitude, entry.longitude),
    );
  }

  Widget _buildTagChip(BuildContext context, String tag, String mood) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSpecialMood = mood != 'none';

    final chipBgColor = isSpecialMood
        ? (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06))
        : null;
    final chipTextColor = _getTextColor(context, mood);

    return ActionChip(
      label: Text('#$tag'),
      labelStyle: TextStyle(
        color: chipTextColor, 
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      backgroundColor: chipBgColor,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      onPressed: () => onTagTap(tag),
    );
  }

  Widget _buildMoodBadge(BuildContext context, String mood) {
    if (mood == 'none') {
      return const SizedBox.shrink();
    }

    final vibe = vibesList.firstWhere((v) => v.id == mood, orElse: () => vibesList[0]);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: -8,
      right: 8, // Place inside the bubble boundaries a bit better
      child: Tooltip(
        message: 'Feeling ${vibe.label}',
        preferBelow: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2825).withOpacity(0.9) : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: vibe.color.withOpacity(isDark ? 0.6 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: vibe.color.withOpacity(0.2),
                blurRadius: 6,
                spreadRadius: 0.5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vibe.emoji,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(width: 4),
              Text(
                vibe.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : vibe.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _getBubbleDecoration(BuildContext context, String mood) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Organic asymmetrical chat bubble border radius
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(24),
      bottomRight: const Radius.circular(24),
      bottomLeft: Radius.circular(mood == 'none' ? 24 : 6), // chat bubble notch
    );

    if (mood == 'none') {
      return BoxDecoration(
        color: isDark ? const Color(0xFF1E1A17) : colorScheme.surface,
        borderRadius: bubbleRadius,
        border: Border.all(
          color: isDark ? const Color(0xFF2C2825) : colorScheme.outlineVariant.withOpacity(0.6), 
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      );
    }

    List<Color> gradientColors;
    Border? border;
    List<BoxShadow>? boxShadows;

    switch (mood) {
      case 'hype':
        gradientColors = isDark
            ? [const Color(0xFF78350F).withOpacity(0.85), const Color(0xFF92400E).withOpacity(0.85)]
            : [Colors.amber.shade200, Colors.orange.shade200];
        boxShadows = [
          BoxShadow(
            color: Colors.amber.withOpacity(isDark ? 0.25 : 0.15),
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: const Offset(0, 2),
          )
        ];
        break;
      case 'chill':
        gradientColors = isDark
            ? [const Color(0xFF3B0764).withOpacity(0.85), const Color(0xFF5B21B6).withOpacity(0.85)]
            : [const Color(0xFFE8EDFF), const Color(0xFFF3E8FF)];
        boxShadows = [
          BoxShadow(
            color: Colors.purple.withOpacity(isDark ? 0.25 : 0.15),
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: const Offset(0, 2),
          )
        ];
        break;
      case 'chaotic':
        gradientColors = isDark
            ? [const Color(0xFF1E1C1A), const Color(0xFF121110)]
            : [const Color(0xFF1E1E1E), const Color(0xFF121212)];
        border = Border.all(
          color: isDark ? const Color(0xFF84CC16).withOpacity(0.8) : Colors.lightGreen.shade400, 
          width: 2,
        );
        boxShadows = [
          BoxShadow(
            color: const Color(0xFF84CC16).withOpacity(isDark ? 0.3 : 0.2),
            blurRadius: 12,
            spreadRadius: 0.5,
            offset: const Offset(0, 2),
          )
        ];
        break;
      case 'blue':
        gradientColors = isDark
            ? [const Color(0xFF1E3A8A).withOpacity(0.85), const Color(0xFF172554).withOpacity(0.85)]
            : [Colors.blueGrey.shade700, Colors.indigo.shade900];
        boxShadows = [
          BoxShadow(
            color: Colors.indigo.withOpacity(isDark ? 0.25 : 0.15),
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: const Offset(0, 2),
          )
        ];
        break;
      case 'stressed':
        gradientColors = isDark
            ? [const Color(0xFF7F1D1D).withOpacity(0.85), const Color(0xFF991B1B).withOpacity(0.85)]
            : [Colors.red.shade900.withOpacity(0.85), Colors.orange.shade900.withOpacity(0.85)];
        boxShadows = [
          BoxShadow(
            color: Colors.red.withOpacity(isDark ? 0.25 : 0.15),
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: const Offset(0, 2),
          )
        ];
        break;
      case 'grateful':
        gradientColors = isDark
            ? [const Color(0xFF831843).withOpacity(0.85), const Color(0xFF9D174D).withOpacity(0.85)]
            : [const Color(0xFFFCE7F3), const Color(0xFFFFEDD5)];
        boxShadows = [
          BoxShadow(
            color: Colors.pink.withOpacity(isDark ? 0.25 : 0.15),
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: const Offset(0, 2),
          )
        ];
        break;
      default:
        gradientColors = [colorScheme.surfaceContainerLow, colorScheme.surfaceContainerLow];
    }

    return BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: bubbleRadius,
      border: border ?? Border.all(color: Colors.transparent, width: 0),
      boxShadow: boxShadows,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';

    return '${timestamp.day}/${timestamp.month}/${timestamp.year} '
        '$hour:$minute $period';
  }

  Future<void> _launchLocation(String? name, double? lat, double? lon) async {
    Uri url;
    if (lat != null && lon != null) {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    } else if (name != null && name.isNotEmpty) {
      url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}');
    } else {
      return;
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Ignore map launching errors
    }
  }
}

class _HiddenMessagePlaceholder extends StatelessWidget {
  const _HiddenMessagePlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF221F1D).withOpacity(0.6) : colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2C2825) : colorScheme.outlineVariant,
            width: 1.2,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.visibility_off_outlined,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Message deleted',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.lock_open_rounded,
              color: colorScheme.primary.withOpacity(0.7),
              size: 16,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: exists
            ? InkWell(
                onTap: () => onTap(file),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C2825) : Colors.black.withOpacity(0.05),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      file,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const _MissingMediaPlaceholder();
                      },
                    ),
                  ),
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
