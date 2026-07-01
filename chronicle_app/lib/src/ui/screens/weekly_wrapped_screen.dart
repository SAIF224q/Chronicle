import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../../application/services/timeline_service.dart';

class WeeklyWrappedScreen extends StatefulWidget {
  const WeeklyWrappedScreen({
    super.key,
    required this.entry,
    required this.onViewCompleted,
  });

  final TimelineEntry entry;
  final VoidCallback onViewCompleted;

  @override
  State<WeeklyWrappedScreen> createState() => _WeeklyWrappedScreenState();
}

class _WeeklyWrappedScreenState extends State<WeeklyWrappedScreen> with SingleTickerProviderStateMixin {
  late final Map<String, dynamic> _data;
  int _currentSlide = 0;
  static const int _totalSlides = 5;

  late final AnimationController _progressController;
  bool _isPaused = false;
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // Mood colors map
  static const Map<String, Color> _moodColors = {
    'hype': Color(0xFFFFB000),      // Glowing Amber
    'chill': Color(0xFF8B5CF6),     // Glowing Purple
    'chaotic': Color(0xFF84CC16),   // Glowing Lime
    'blue': Color(0xFF3B82F6),      // Glowing Blue
    'stressed': Color(0xFFEF4444),  // Glowing Red
    'grateful': Color(0xFFEC4899),  // Glowing Pink
    'none': Color(0xFF6B7280),      // Glowing Slate
  };

  static const Map<String, String> _moodEmojis = {
    'hype': '🌟',
    'chill': '☁️',
    'chaotic': '⚡',
    'blue': '🌧️',
    'stressed': '🌪️',
    'grateful': '🌸',
    'none': '💬',
  };

  @override
  void initState() {
    super.initState();
    _data = json.decode(widget.entry.content) as Map<String, dynamic>;

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextSlide();
      }
    });

    _startPlay();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startPlay() {
    _progressController.reset();
    _progressController.forward();
  }

  void _nextSlide() {
    if (_currentSlide < _totalSlides - 1) {
      setState(() {
        _currentSlide++;
      });
      _startPlay();
    } else {
      // Finished all slides
      widget.onViewCompleted();
      Navigator.of(context).pop();
    }
  }

  void _prevSlide() {
    if (_currentSlide > 0) {
      setState(() {
        _currentSlide--;
      });
      _startPlay();
    }
  }

  void _pause() {
    if (!_isPaused) {
      _progressController.stop();
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _resume() {
    if (_isPaused) {
      _progressController.forward();
      setState(() {
        _isPaused = false;
      });
    }
  }

  Future<void> _saveInfographicToGallery() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final picturesDir = Directory('${directory.path}/Chronicle_Wrapped');
      if (!await picturesDir.exists()) {
        await picturesDir.create(recursive: true);
      }

      final filename = 'Weekly_Wrapped_${_data['week_label']?.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${picturesDir.path}/$filename');
      await file.writeAsBytes(pngBytes);

      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to gallery! 📸 (Documents/Chronicle_Wrapped/$filename)'),
          backgroundColor: const Color(0xFF8B5CF6),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to export Wrapped image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 12) {
          // Swipe down dismiss
          widget.onViewCompleted();
          Navigator.of(context).pop();
        }
      },
      onTapDown: (_) => _pause(),
      onTapUp: (details) {
        _resume();
        final screenWidth = MediaQuery.of(context).size.width;
        final x = details.globalPosition.dx;
        if (x < screenWidth * 0.3) {
          _prevSlide();
        } else if (x > screenWidth * 0.7) {
          _nextSlide();
        }
      },
      onLongPressStart: (_) => _pause(),
      onLongPressEnd: (_) => _resume(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0512), // Vaporwave midnight black
        body: SafeArea(
          child: Column(
            children: [
              // Progress indicators
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: List.generate(_totalSlides, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            double fillWidth = 0.0;
                            if (index < _currentSlide) {
                              fillWidth = constraints.maxWidth;
                            } else if (index == _currentSlide) {
                              return AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: constraints.maxWidth * _progressController.value,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: fillWidth,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Main Slide Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _buildSlideContent(_currentSlide),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideContent(int slideIndex) {
    switch (slideIndex) {
      case 0:
        return _buildAuraSlide();
      case 1:
        return _buildSpectrumSlide();
      case 2:
        return _buildKeywordsSlide();
      case 3:
        return _buildPeakHourSlide();
      case 4:
        return _buildSummarySlide();
      default:
        return const SizedBox.shrink();
    }
  }

  // Slide 1: Cover & Aura
  Widget _buildAuraSlide() {
    final dominantMood = _data['dominant_mood'] as String? ?? 'none';
    final moodPercentages = _data['mood_percentages'] as Map<String, dynamic>? ?? {};

    // Get top 2 moods for Aura color blend
    final sortedMoods = moodPercentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final color1 = _moodColors[dominantMood] ?? _moodColors['none']!;
    final color2 = sortedMoods.length > 1
        ? (_moodColors[sortedMoods[1].key] ?? color1)
        : color1;

    return Stack(
      key: const ValueKey(0),
      children: [
        // Fluid blended aura orb background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  color1.withOpacity(0.25),
                  color2.withOpacity(0.1),
                  Colors.transparent,
                ],
                radius: 1.2,
                center: Alignment.center,
              ),
            ),
          ),
        ),

        // Glowing center orb (animated)
        Center(
          child: _PulsingAuraOrb(color1: color1, color2: color2),
        ),

        // Story Texts
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'WEEKLY AURA',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: color1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This week was a total',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
              Text(
                '${dominantMood[0].toUpperCase()}${dominantMood.substring(1)} Vibe.',
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: color1,
                  letterSpacing: -1.0,
                  shadows: [
                    Shadow(color: color1.withOpacity(0.6), blurRadius: 20),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your emotional spectrum was dominated by cozy energies and self-discovery. Slide through to see the blueprint of your mind.',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Slide 2: Mood Spectrum
  Widget _buildSpectrumSlide() {
    final moodPercentages = _data['mood_percentages'] as Map<String, dynamic>? ?? {};
    final dominantMood = _data['dominant_mood'] as String? ?? 'none';
    final primaryColor = _moodColors[dominantMood] ?? _moodColors['none']!;

    return Padding(
      key: const ValueKey(1),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Text(
            'Your Mood Spectrum',
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here is how you distributed your energy over the past 7 days.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.white38,
            ),
          ),
          const Spacer(),
          Column(
            children: moodPercentages.entries.map((entry) {
              final mood = entry.key;
              final percentage = entry.value as int;
              final color = _moodColors[mood] ?? Colors.grey;
              final emoji = _moodEmojis[mood] ?? '💬';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              mood[0].toUpperCase() + mood.substring(1),
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$percentage%',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100.0,
                        color: color,
                        backgroundColor: Colors.white.withOpacity(0.06),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // Slide 3: Word Vibe Check (Top Keywords)
  Widget _buildKeywordsSlide() {
    final keywords = List<String>.from(_data['top_keywords'] ?? []);
    final dominantMood = _data['dominant_mood'] as String? ?? 'none';
    final accentColor = _moodColors[dominantMood] ?? _moodColors['none']!;

    return Padding(
      key: const ValueKey(2),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Text(
            'Living Rent-Free...',
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '...in your mind this week. These tags and topics dominated your entries.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.white38,
            ),
          ),
          const Expanded(
            child: SizedBox(),
          ),
          Center(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: List.generate(keywords.length, (index) {
                final word = keywords[index];
                // Scale text size based on index (higher frequency = larger)
                final size = 32.0 - (index * 2.2).clamp(0.0, 16.0);
                final opacity = 1.0 - (index * 0.08).clamp(0.0, 0.6);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.05 * opacity),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accentColor.withOpacity(0.2 * opacity),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    word,
                    style: GoogleFonts.outfit(
                      fontSize: size,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(opacity),
                      shadows: index == 0
                          ? [Shadow(color: accentColor.withOpacity(0.4), blurRadius: 10)]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),
          const Expanded(
            child: SizedBox(),
          ),
        ],
      ),
    );
  }

  // Slide 4: Peak Vibe Hour & Streak
  Widget _buildPeakHourSlide() {
    final peakHour = _data['peak_hour'] as int? ?? 20;
    final streak = _data['streak'] as int? ?? 0;
    final dominantMood = _data['dominant_mood'] as String? ?? 'none';
    final accentColor = _moodColors[dominantMood] ?? _moodColors['none']!;

    // Clock formatting
    final displayHour = peakHour == 0 ? 12 : (peakHour > 12 ? peakHour - 12 : peakHour);
    final ampm = peakHour >= 12 ? 'PM' : 'AM';

    return Padding(
      key: const ValueKey(3),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Text(
            'Hour of Reflection',
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your peak writing hour and streaks compiled.',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.white38,
            ),
          ),
          const Spacer(),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Custom Paint Clock Face
                CustomPaint(
                  size: const Size(120, 120),
                  painter: _ClockSlicePainter(
                    peakHour: peakHour,
                    accentColor: accentColor,
                  ),
                ),
                const SizedBox(width: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peak Hour',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white38,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '$displayHour:00 $ampm',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consistency',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white38,
                              ),
                            ),
                            Text(
                              '$streak Day Streak',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // Slide 5: Recap Infographic
  Widget _buildSummarySlide() {
    final dominantMood = _data['dominant_mood'] as String? ?? 'none';
    final primaryColor = _moodColors[dominantMood] ?? _moodColors['none']!;
    final emoji = _moodEmojis[dominantMood] ?? '💬';
    final weekLabel = _data['week_label'] as String? ?? '';
    final totalEntries = _data['total_entries'] as int? ?? 0;
    final voiceMinutes = _data['voice_minutes'] as double? ?? 0.0;
    final streak = _data['streak'] as int? ?? 0;
    final keywords = List<String>.from(_data['top_keywords'] ?? []);

    return Padding(
      key: const ValueKey(4),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: RepaintBoundary(
                key: _repaintBoundaryKey,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0A1A), // Infographic dark theme background
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.12),
                        blurRadius: 30,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CHRONICLE WRAPPED',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            '✨',
                            style: TextStyle(fontSize: 16, color: primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        weekLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dominant Vibe',
                                style: GoogleFonts.outfit(fontSize: 11, color: Colors.white38),
                              ),
                              Text(
                                dominantMood[0].toUpperCase() + dominantMood.substring(1),
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatBox('Total Entries', '$totalEntries', Icons.edit_note_rounded, primaryColor),
                          _buildStatBox('Voice Recs', '${voiceMinutes.toStringAsFixed(1)}m', Icons.keyboard_voice_rounded, primaryColor),
                          _buildStatBox('Best Streak', '$streak days', Icons.local_fire_department_rounded, primaryColor),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'TOP TOPICS',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white38,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: keywords.take(5).map((word) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              word,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveInfographicToGallery,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor.withOpacity(0.4), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: Text(
                    'Save to Gallery',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onViewCompleted();
                    Navigator.of(context).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: Colors.white38,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingAuraOrb extends StatefulWidget {
  const _PulsingAuraOrb({required this.color1, required this.color2});

  final Color color1;
  final Color color2;

  @override
  State<_PulsingAuraOrb> createState() => _PulsingAuraOrbState();
}

class _PulsingAuraOrbState extends State<_PulsingAuraOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _pulsController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(parent: _pulsController, curve: Curves.easeInOutSine),
    );

    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _pulsController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulsController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.color1,
                    widget.color2.withOpacity(0.8),
                    widget.color1.withOpacity(0.0),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color1.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClockSlicePainter extends CustomPainter {
  final int peakHour;
  final Color accentColor;

  _ClockSlicePainter({required this.peakHour, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintOutline = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw clock face circle
    canvas.drawCircle(center, radius, paintOutline);

    // Draw 12 clock ticks
    final paintTick = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.5;
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * pi / 180;
      final inner = center + Offset(cos(angle) * (radius - 6), sin(angle) * (radius - 6));
      final outer = center + Offset(cos(angle) * radius, sin(angle) * radius);
      canvas.drawLine(inner, outer, paintTick);
    }

    // Draw peak hour slice (from peakHour - 1 hour to peakHour + 1 hour)
    // 12 o'clock is at -90 degrees (-pi/2)
    // 1 hour is 30 degrees (pi/6)
    final peakAngle = (peakHour * 15 - 90) * pi / 180; // peakHour * 15 is because 24 hours in a circle -> 15 degrees per hour
    final startAngle = peakAngle - (pi / 12); // -1 hour wedge width
    final sweepAngle = pi / 6; // 2 hours total wedge width

    final paintSlice = Paint()
      ..shader = RadialGradient(
        colors: [accentColor.withOpacity(0.5), accentColor.withOpacity(0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      paintSlice,
    );

    // Slice outline
    final paintSliceOutline = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      paintSliceOutline,
    );
  }

  @override
  bool shouldRepaint(covariant _ClockSlicePainter oldDelegate) =>
      oldDelegate.peakHour != peakHour || oldDelegate.accentColor != accentColor;
}
