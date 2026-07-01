import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/services/timeline_service.dart';
import 'audio_player_widget.dart';
import 'confetti_wrapper.dart';
import 'dashed_border_painter.dart';
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
    this.isLastBotPrompt = false,
    this.onChoiceSelected,
    this.onWeeklyWrappedTap,
  });

  final TimelineEntry entry;
  final bool isRevealed;
  final ValueChanged<String> onTagTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onHiddenPlaceholderTap;
  final ValueChanged<File> onImageTap;
  final bool isLastBotPrompt;
  final ValueChanged<String>? onChoiceSelected;
  final ValueChanged<TimelineEntry>? onWeeklyWrappedTap;

  @override
  Widget build(BuildContext context) {
    if (entry.type == 'weekly_wrapped') {
      return _buildWeeklyWrappedCard(context);
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUnlockedTimeCapsule = entry.unlockAt != null && !entry.isLocked;
    final textColor = isUnlockedTimeCapsule ? Colors.white : _getTextColor(context, entry.mood);
    final secondaryTextColor = isUnlockedTimeCapsule ? Colors.white70 : _getSecondaryTextColor(context, entry.mood);
    final showBadge = entry.mood != 'none' && !entry.isLocked && !entry.isBot;

    Widget bubbleContent = Container(
      constraints: const BoxConstraints(maxWidth: 500),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: _getBubbleDecoration(context, entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (entry.isHidden && !isRevealed) ...<Widget>[
              _HiddenMessagePlaceholder(onTap: onHiddenPlaceholderTap),
            ] else if (entry.isLocked) ...<Widget>[
              _LockedTimeCapsulePlaceholder(
                entry: entry,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
              ),
            ] else ...<Widget>[
              if (entry.isBot) ...<Widget>[
                Row(
                  children: [
                    const Text('🤖', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'Vibe Check-In',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF06B6D4), // Cyan neon color
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              if (isUnlockedTimeCapsule) ...<Widget>[
                Row(
                  children: [
                    Icon(Icons.lock_open, color: textColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Unlocked Time Capsule',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Sent ${_formatCapsuleDate(entry.createdAt)} (${_getTimeAgo(entry.createdAt)})',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (entry.content.isNotEmpty) ...<Widget>[
                Text(
                  entry.content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: entry.isBot ? FontWeight.w600 : FontWeight.w500,
                    fontStyle: entry.isBot ? FontStyle.italic : FontStyle.normal,
                    fontFamily: entry.isBot ? GoogleFonts.outfit().fontFamily : null,
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
                _buildLocationChip(context),
              ],
              if (entry.tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.tags
                      .map((tag) => _buildTagChip(context, tag))
                      .toList(growable: false),
                ),
              ],
            ],
            if (isLastBotPrompt && onChoiceSelected != null) ...<Widget>[
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChoiceChip(context, 'hype', '🌟 Hype', const Color(0xFFFFB000)),
                    const SizedBox(width: 8),
                    _buildChoiceChip(context, 'chill', '☁️ Chill', const Color(0xFF8B5CF6)),
                    const SizedBox(width: 8),
                    _buildChoiceChip(context, 'chaotic', '⚡ Chaotic', const Color(0xFF84CC16)),
                    const SizedBox(width: 8),
                    _buildChoiceChip(context, 'blue', '🌧️ Blue', const Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    _buildChoiceChip(context, 'stressed', '🌪️ Stressed', const Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    _buildChoiceChip(context, 'grateful', '🌸 Grateful', const Color(0xFFEC4899)),
                  ],
                ),
              ),
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
                if (!entry.isBot)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: (entry.isHidden && !isRevealed) || entry.isLocked ? null : onEditTap,
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
                        onPressed: (entry.isHidden && !isRevealed) || entry.isLocked ? null : onDeleteTap,
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
    );

    if (isUnlockedTimeCapsule) {
      bubbleContent = ConfettiWrapper(child: bubbleContent);
    }

    if (entry.isBot) {
      final bubbleRadius = BorderRadius.only(
        topLeft: const Radius.circular(24),
        topRight: const Radius.circular(24),
        bottomRight: const Radius.circular(24),
        bottomLeft: Radius.circular(entry.mood == 'none' ? 24 : 6),
      );
      bubbleContent = ClipRRect(
        borderRadius: bubbleRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: CustomPaint(
            painter: _GradientBorderPainter(
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)], // Cyan to Purple
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              strokeWidth: 1.5,
              radius: bubbleRadius,
            ),
            child: bubbleContent,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          bubbleContent,
          if (showBadge) _buildMoodBadge(context, entry.mood),
        ],
      ),
    );
  }

  Color _getTextColor(BuildContext context, String mood) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (entry.isBot) {
      return isDark ? Colors.white : Colors.black87;
    }
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
    if (entry.isBot) {
      return isDark ? Colors.white60 : Colors.black54;
    }
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

  Widget _buildLocationChip(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSpecialMood = entry.mood != 'none';
    final isUnlockedTimeCapsule = entry.unlockAt != null && !entry.isLocked;

    final chipBgColor = (isSpecialMood || isUnlockedTimeCapsule)
        ? (isDark || isUnlockedTimeCapsule ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06))
        : null;
    final chipTextColor = isUnlockedTimeCapsule ? Colors.white : _getTextColor(context, entry.mood);

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

  Widget _buildTagChip(BuildContext context, String tag) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSpecialMood = entry.mood != 'none';
    final isUnlockedTimeCapsule = entry.unlockAt != null && !entry.isLocked;

    final chipBgColor = (isSpecialMood || isUnlockedTimeCapsule)
        ? (isDark || isUnlockedTimeCapsule ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06))
        : null;
    final chipTextColor = isUnlockedTimeCapsule ? Colors.white : _getTextColor(context, entry.mood);

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

  BoxDecoration _getBubbleDecoration(BuildContext context, TimelineEntry entry) {
    final mood = entry.mood;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Organic asymmetrical chat bubble border radius
    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(24),
      bottomRight: const Radius.circular(24),
      bottomLeft: Radius.circular(mood == 'none' ? 24 : 6), // chat bubble notch
    );

    if (entry.isLocked) {
      return BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: bubbleRadius,
      );
    }

    if (entry.isBot) {
      return BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: bubbleRadius,
      );
    }

    final isTimeCapsule = entry.unlockAt != null;
    final isUnlocked = isTimeCapsule && !entry.isLocked;

    if (isUnlocked) {
      return BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CF6),
            Colors.deepPurple,
            Colors.pinkAccent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: bubbleRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(isDark ? 0.35 : 0.2),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          )
        ],
      );
    }

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

  String _formatCapsuleDate(DateTime timestamp) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year}';
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 365) {
      final years = diff.inDays ~/ 365;
      return '$years ${years == 1 ? "year" : "years"} ago';
    } else if (diff.inDays >= 30) {
      final months = diff.inDays ~/ 30;
      return '$months ${months == 1 ? "month" : "months"} ago';
    } else if (diff.inDays >= 7) {
      final weeks = diff.inDays ~/ 7;
      return '$weeks ${weeks == 1 ? "week" : "weeks"} ago';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays} ${diff.inDays == 1 ? "day" : "days"} ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} ${diff.inMinutes == 1 ? "minute" : "minutes"} ago';
    } else {
      return 'just now';
    }
  }

  static final Map<String, Color> _lightModeTextColors = {
    'hype': Colors.orange.shade900,
    'chill': Colors.purple.shade900,
    'chaotic': Colors.green.shade900,
    'blue': Colors.blue.shade900,
    'stressed': Colors.red.shade900,
    'grateful': Colors.pink.shade900,
  };

  Widget _buildChoiceChip(BuildContext context, String mood, String label, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textCol = isDark ? accentColor : (_lightModeTextColors[mood] ?? Colors.black87);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChoiceSelected!(mood);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? accentColor.withOpacity(0.12) : accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withOpacity(0.4),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textCol,
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyWrappedCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Map<String, dynamic> data;
    try {
      data = json.decode(entry.content) as Map<String, dynamic>;
    } catch (_) {
      data = {};
    }

    final viewed = data['viewed'] as bool? ?? false;
    final weekLabel = data['week_label'] as String? ?? 'Weekly Vibe';
    final dominantMood = data['dominant_mood'] as String? ?? 'none';

    const moodColors = {
      'hype': Color(0xFFFFB000),
      'chill': Color(0xFF8B5CF6),
      'chaotic': Color(0xFF84CC16),
      'blue': Color(0xFF3B82F6),
      'stressed': Color(0xFFEF4444),
      'grateful': Color(0xFFEC4899),
      'none': Color(0xFF6B7280),
    };

    final accentColor = moodColors[dominantMood] ?? moodColors['none']!;
    final bubbleRadius = BorderRadius.circular(24);

    Widget cardContent = Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 500),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0A1A).withOpacity(0.7) : Colors.white.withOpacity(0.85),
        borderRadius: bubbleRadius,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: bubbleRadius,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onWeeklyWrappedTap?.call(entry);
          },
          borderRadius: bubbleRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '📊',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'WEEKLY VIBE WRAPPED',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Week of $weekLabel',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!viewed)
                        _PulsingPlayBadge(accentColor: accentColor)
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: Text(
                            'Review Recap ➡️',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    cardContent = ClipRRect(
      borderRadius: bubbleRadius,
      child: CustomPaint(
        painter: _GradientBorderPainter(
          gradient: LinearGradient(
            colors: !viewed
                ? [accentColor, accentColor.withOpacity(0.1), const Color(0xFF8B5CF6)]
                : [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          strokeWidth: !viewed ? 2.0 : 1.2,
          radius: bubbleRadius,
        ),
        child: cardContent,
      ),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: cardContent,
    );
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

class _LockedTimeCapsulePlaceholder extends StatefulWidget {
  const _LockedTimeCapsulePlaceholder({
    required this.entry,
    required this.textColor,
    required this.secondaryTextColor,
  });

  final TimelineEntry entry;
  final Color textColor;
  final Color secondaryTextColor;

  @override
  State<_LockedTimeCapsulePlaceholder> createState() => _LockedTimeCapsulePlaceholderState();
}

class _LockedTimeCapsulePlaceholderState extends State<_LockedTimeCapsulePlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onTap() {
    _shakeController.forward(from: 0.0);
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Text('🤫 ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                'No peeking! Patience is a vibe',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.purple.shade900.withOpacity(0.9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final unlockDate = DateTime.fromMillisecondsSinceEpoch(widget.entry.unlockAt!);
    final diff = unlockDate.difference(DateTime.now());
    String countdownStr = '';
    if (diff.inDays >= 1) {
      countdownStr = 'in ${diff.inDays} ${diff.inDays == 1 ? "day" : "days"}';
    } else if (diff.inHours >= 1) {
      countdownStr = 'in ${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"}';
    } else if (diff.inMinutes >= 1) {
      countdownStr = 'in ${diff.inMinutes} ${diff.inMinutes == 1 ? "minute" : "minutes"}';
    } else {
      countdownStr = 'in a few seconds';
    }

    final monthsText = _formatCapsuleDate(unlockDate);

    return RotationTransition(
      turns: _shakeAnimation,
      child: GestureDetector(
        onTap: _onTap,
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: const Color(0xFFC084FC),
            strokeWidth: 2.0,
            dashPattern: const [6, 4],
            radius: 24,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC084FC).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFFC084FC),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '🔒 Sealed Time Capsule',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlocks on $monthsText ($countdownStr)',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCapsuleDate(DateTime timestamp) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year}';
  }
}

class _GradientBorderPainter extends CustomPainter {
  _GradientBorderPainter({
    required this.gradient,
    required this.strokeWidth,
    required this.radius,
  });

  final Gradient gradient;
  final double strokeWidth;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..shader = gradient.createShader(rect);

    final path = Path()
      ..addRRect(RRect.fromRectAndCorners(
        rect,
        topLeft: radius.topLeft,
        topRight: radius.topRight,
        bottomRight: radius.bottomRight,
        bottomLeft: radius.bottomLeft,
      ));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) => false;
}

class _PulsingPlayBadge extends StatefulWidget {
  const _PulsingPlayBadge({required this.accentColor});
  final Color accentColor;

  @override
  State<_PulsingPlayBadge> createState() => _PulsingPlayBadgeState();
}

class _PulsingPlayBadgeState extends State<_PulsingPlayBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.accentColor.withOpacity(0.6),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tap to Play ➡️',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.accentColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
