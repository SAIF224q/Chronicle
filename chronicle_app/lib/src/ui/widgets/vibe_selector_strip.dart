import 'package:flutter/material.dart';

class VibeInfo {
  final String id;
  final String emoji;
  final String label;
  final Color color;
  final Color textColor;

  const VibeInfo({
    required this.id,
    required this.emoji,
    required this.label,
    required this.color,
    required this.textColor,
  });
}

const List<VibeInfo> vibesList = [
  VibeInfo(
    id: 'hype',
    emoji: '🌟',
    label: 'Hype',
    color: Colors.amber,
    textColor: Color(0xFFB45309), // amber.shade800
  ),
  VibeInfo(
    id: 'chill',
    emoji: '☁️',
    label: 'Chill',
    color: Colors.purple,
    textColor: Color(0xFF6B21A8), // purple.shade800
  ),
  VibeInfo(
    id: 'chaotic',
    emoji: '⚡',
    label: 'Chaotic',
    color: Colors.lightGreen,
    textColor: Color(0xFF3F6212), // lime/green.shade800
  ),
  VibeInfo(
    id: 'blue',
    emoji: '🌧️',
    label: 'Blue',
    color: Colors.blue,
    textColor: Color(0xFF1E40AF), // blue.shade800
  ),
  VibeInfo(
    id: 'stressed',
    emoji: '🌪️',
    label: 'Stressed',
    color: Colors.red,
    textColor: Color(0xFF991B1B), // red.shade800
  ),
  VibeInfo(
    id: 'grateful',
    emoji: '🌸',
    label: 'Grateful',
    color: Colors.pink,
    textColor: Color(0xFF9D174D), // pink.shade800
  ),
];

class VibeSelectorStrip extends StatelessWidget {
  const VibeSelectorStrip({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  final String selectedMood;
  final ValueChanged<String> onMoodSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Select Vibe',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: vibesList.length,
            itemBuilder: (context, index) {
              final vibe = vibesList[index];
              final isSelected = selectedMood == vibe.id;

              return Padding(
                padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                child: AnimatedScale(
                  scale: isSelected ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? vibe.color.withOpacity(isDark ? 0.22 : 0.12)
                          : (isDark ? const Color(0xFF1E1A17) : colorScheme.surfaceContainerLow),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? vibe.color 
                            : (isDark ? const Color(0xFF2C2825) : colorScheme.outlineVariant),
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: vibe.color.withOpacity(isDark ? 0.25 : 0.15),
                                blurRadius: 8,
                                spreadRadius: 0.5,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        if (isSelected) {
                          onMoodSelected('none');
                        } else {
                          onMoodSelected(vibe.id);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              vibe.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              vibe.label,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 13,
                                color: isSelected
                                    ? (isDark ? vibe.color : vibe.textColor)
                                    : colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
