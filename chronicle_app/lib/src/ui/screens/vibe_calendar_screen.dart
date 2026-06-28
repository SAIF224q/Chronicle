import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/services/settings_service.dart';
import '../../application/services/timeline_service.dart';
import '../widgets/dashed_border_painter.dart';

class VibeCalendarScreen extends StatefulWidget {
  const VibeCalendarScreen({
    super.key,
    required this.timelineService,
    required this.settingsService,
  });

  final TimelineService timelineService;
  final SettingsService settingsService;

  @override
  State<VibeCalendarScreen> createState() => _VibeCalendarScreenState();
}

class _VibeCalendarScreenState extends State<VibeCalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  VibeStreakInfo? _streakInfo;
  Map<String, String> _dailyMoods = {};
  bool _isLoading = true;
  int _startDayOfWeek = 1;
  bool _showStreaks = true;

  @override
  void initState() {
    super.initState();
    _loadAllCalendarData();
  }

  Future<void> _loadAllCalendarData() async {
    setState(() {
      _isLoading = true;
    });

    final startDay = await widget.settingsService.getVibeCalendarStartDayOfWeek();
    final showStreaks = await widget.settingsService.getVibeCalendarShowStreaks();

    // Fetch dominant moods for the focused month (and pad range slightly to cover visible grid edges)
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final startOfRange = DateTime(year, month - 1, 20); // Cover previous month padding
    final endOfRange = DateTime(year, month + 1, 10);   // Cover next month padding

    final dailyMoods = await widget.timelineService.getDailyDominantMoods(startOfRange, endOfRange);
    final streakInfo = await widget.timelineService.getVibeStreak();

    if (!mounted) return;

    setState(() {
      _startDayOfWeek = startDay;
      _showStreaks = showStreaks;
      _dailyMoods = dailyMoods;
      _streakInfo = streakInfo;
      _isLoading = false;
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
    _loadAllCalendarData();
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
    _loadAllCalendarData();
  }

  static const Map<String, String> _moodEmojis = {
    'hype': '🌟',
    'chill': '☁️',
    'chaotic': '⚡',
    'blue': '🌧️',
    'stressed': '🌪️',
    'grateful': '🌸',
    'none': '💬',
  };

  static const Map<String, String> _moodLabels = {
    'hype': 'Hype',
    'chill': 'Chill',
    'chaotic': 'Chaotic',
    'blue': 'Blue',
    'stressed': 'Stressed',
    'grateful': 'Grateful',
    'none': 'Neutral',
  };

  static const Map<String, Color> _weekMoodColors = {
    'hype': Colors.amberAccent,
    'chill': Colors.blueAccent,
    'chaotic': Colors.greenAccent,
    'blue': Colors.indigoAccent,
    'stressed': Colors.redAccent,
    'grateful': Colors.pinkAccent,
    'none': Color(0xFF8B5CF6),
  };

  BoxDecoration _getTileDecoration(String mood, bool isDark) {
    switch (mood) {
      case 'hype':
        return BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          gradient: const LinearGradient(
            colors: [Colors.amber, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'chill':
        return BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          gradient: LinearGradient(
            colors: [Colors.indigo.shade300, Colors.purple.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'chaotic':
        return BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: const Color(0xFF1E1E1E),
          border: Border.all(
            color: const Color(0xFF84CC16),
            width: 1.5,
          ),
        );
      case 'blue':
        return BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade600, Colors.indigo.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'stressed':
        return BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          gradient: LinearGradient(
            colors: [Colors.red.shade800, Colors.orange.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'grateful':
        return BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          gradient: LinearGradient(
            colors: [Colors.pink.shade300, Colors.orange.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 'none':
        return BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.grey.withOpacity(0.25),
        );
      default:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.transparent,
        );
    }
  }

  String _getMonthlyDominantMoodText() {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    
    final counts = <String, int>{};
    for (final entry in _dailyMoods.entries) {
      final dateParts = entry.key.split('-');
      if (dateParts.length == 3 &&
          int.parse(dateParts[0]) == year &&
          int.parse(dateParts[1]) == month) {
        final mood = entry.value;
        if (mood != 'none') {
          counts[mood] = (counts[mood] ?? 0) + 1;
        }
      }
    }
    if (counts.isEmpty) {
      return 'No entries recorded this month yet 📝';
    }
    
    var dominant = 'none';
    var maxCount = 0;
    counts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        dominant = mood;
      }
    });

    if (dominant == 'none') {
      return 'Feeling neutral this month 💬';
    }

    final emoji = _moodEmojis[dominant] ?? '';
    final label = _moodLabels[dominant] ?? '';
    return 'Mostly feeling $label this month $emoji';
  }

  String _getCurrentWeekDominantMood() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final counts = <String, int>{};
    
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final mood = _dailyMoods[dateKey];
      if (mood != null && mood != 'none') {
        counts[mood] = (counts[mood] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return 'none';
    var dominant = 'none';
    var maxCount = 0;
    counts.forEach((mood, count) {
      if (count > maxCount) {
        maxCount = count;
        dominant = mood;
      }
    });
    return dominant;
  }

  List<DateTime> _generateCalendarDays() {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    
    int paddingDays = (firstDayOfMonth.weekday - _startDayOfWeek) % 7;
    if (paddingDays < 0) {
      paddingDays += 7;
    }
    
    final firstVisibleDay = firstDayOfMonth.subtract(Duration(days: paddingDays));
    final totalTiles = ((paddingDays + daysInMonth) / 7).ceil() * 7;
    
    return List<DateTime>.generate(
      totalTiles,
      (index) => firstVisibleDay.add(Duration(days: index)),
    );
  }

  void _showDayPreview(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F081D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return _DayPreviewBottomSheet(
          date: date,
          dayStart: dayStart,
          dayEnd: dayEnd,
          timelineService: widget.timelineService,
        );
      },
    );
  }

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final calendarDays = _generateCalendarDays();
    final weekMood = _getCurrentWeekDominantMood();
    final streakGlowColor = _weekMoodColors[weekMood] ?? const Color(0xFF8B5CF6);

    // Weekday abbreviations based on startDayOfWeek setting
    final weekdayLabels = _startDayOfWeek == 1
        ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0512), // Midnight backdrop
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                children: [
                  // Header Title
                  Text(
                    'My Vibe Calendar 🗓️',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        const Shadow(
                          color: Color(0xFF8B5CF6),
                          blurRadius: 8.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Dynamic Subtitle
                  Text(
                    _getMonthlyDominantMoodText(),
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Streak Card (if enabled)
                  if (_showStreaks && _streakInfo != null) ...[
                    _PulsingNeonGlow(
                      glowColor: streakGlowColor,
                      child: Container(
                        padding: const EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '🔥 Current Streak',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white60,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_streakInfo!.currentStreak} Days',
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1.2, height: 40, color: Colors.white12),
                            Column(
                              children: [
                                Text(
                                  '✨ Longest Streak',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white60,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_streakInfo!.longestStreak} Days',
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Month Selector Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                        onPressed: _prevMonth,
                      ),
                      Text(
                        '${_months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 20),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Weekday Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: weekdayLabels.map((day) {
                      return SizedBox(
                        width: 40,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white38,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Calendar Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                    ),
                    itemCount: calendarDays.length,
                    itemBuilder: (context, index) {
                      final date = calendarDays[index];
                      final isCurrentMonth = date.month == _focusedMonth.month;
                      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      final mood = _dailyMoods[dateKey];
                      final today = DateTime.now();
                      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                      
                      Widget tileContent = Center(
                        child: Text(
                          '${date.day}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isCurrentMonth 
                                ? (mood != null ? Colors.white : Colors.white60)
                                : Colors.white24,
                          ),
                        ),
                      );

                      Widget tile;
                      if (mood == null) {
                        // Empty tile: Dashed border
                        tile = CustomPaint(
                          painter: DashedBorderPainter(
                            color: isCurrentMonth ? Colors.white24 : Colors.white12,
                            strokeWidth: 1.2,
                            dashPattern: const [4, 3],
                            radius: 8.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: tileContent,
                          ),
                        );
                      } else {
                        // Journaled active tile: Gradient filling
                        tile = GestureDetector(
                          onTap: () => _showDayPreview(date),
                          child: Container(
                            decoration: _getTileDecoration(mood, isDark),
                            child: tileContent,
                          ),
                        );
                      }

                      if (isToday) {
                        tile = _TodayTileBorder(child: tile);
                      }

                      return tile;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Legend
                  Text(
                    'Vibe Legend',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _moodLabels.entries.map((entry) {
                      final mood = entry.key;
                      final label = entry.value;
                      final emoji = _moodEmojis[mood] ?? '';
                      if (mood == 'none') return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _PulsingNeonGlow extends StatefulWidget {
  const _PulsingNeonGlow({
    required this.child,
    required this.glowColor,
  });

  final Widget child;
  final Color glowColor;

  @override
  State<_PulsingNeonGlow> createState() => _PulsingNeonGlowState();
}

class _PulsingNeonGlowState extends State<_PulsingNeonGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 4.0, end: 14.0).animate(
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
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.35),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _TodayTileBorder extends StatefulWidget {
  const _TodayTileBorder({required this.child});
  final Widget child;
  @override
  State<_TodayTileBorder> createState() => _TodayTileBorderState();
}

class _TodayTileBorderState extends State<_TodayTileBorder> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _borderGlow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _borderGlow = Tween<double>(begin: 1.0, end: 3.0).animate(
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
      animation: _borderGlow,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: _borderGlow.value,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.4),
                blurRadius: _borderGlow.value * 3,
                spreadRadius: 0.2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _DayPreviewBottomSheet extends StatefulWidget {
  const _DayPreviewBottomSheet({
    required this.date,
    required this.dayStart,
    required this.dayEnd,
    required this.timelineService,
  });

  final DateTime date;
  final DateTime dayStart;
  final DateTime dayEnd;
  final TimelineService timelineService;

  @override
  State<_DayPreviewBottomSheet> createState() => _DayPreviewBottomSheetState();
}

class _DayPreviewBottomSheetState extends State<_DayPreviewBottomSheet> {
  late Future<List<TimelineEntry>> _previewFuture;

  @override
  void initState() {
    super.initState();
    _previewFuture = widget.timelineService.loadTimelineEntries(
      startDate: widget.dayStart,
      endDate: widget.dayEnd,
    );
  }

  static const Map<String, String> _moodEmojis = {
    'hype': '🌟',
    'chill': '☁️',
    'chaotic': '⚡',
    'blue': '🌧️',
    'stressed': '🌪️',
    'grateful': '🌸',
    'none': ' Neutral 💬',
  };

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = '${_VibeCalendarScreenState._months[widget.date.month - 1]} ${widget.date.day}, ${widget.date.year}';

    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          
          // Header Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // pop bottom sheet
                  Navigator.of(context).pop(widget.date); // pop calendar screen, returning selected date
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('View in Timeline'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Entries Preview
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: FutureBuilder<List<TimelineEntry>>(
              future: _previewFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load entry previews', style: TextStyle(color: Colors.white70)));
                }

                final entries = snapshot.data ?? [];
                if (entries.isEmpty) {
                  return const Center(child: Text('No entries found for this day.', style: TextStyle(color: Colors.white70)));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final emoji = _moodEmojis[entry.mood] ?? '';
                    final time = _formatTime(entry.createdAt);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                time,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white38,
                                ),
                              ),
                              if (entry.mood != 'none')
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 14),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            entry.content.isNotEmpty 
                                ? entry.content 
                                : (entry.type == 'voice' ? '🎤 Voice note entry' : '📷 Image entry'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          if (entry.locationName != null && entry.locationName!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: Colors.white38, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  entry.locationName!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: Colors.white38,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
