import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../../application/services/entry_service.dart';
import '../../application/services/settings_service.dart';
import '../../application/services/timeline_service.dart';

class ScrapbookBoardScreen extends StatefulWidget {
  const ScrapbookBoardScreen({
    super.key,
    required this.timelineService,
    required this.settingsService,
  });

  final TimelineService timelineService;
  final SettingsService settingsService;

  @override
  State<ScrapbookBoardScreen> createState() => _ScrapbookBoardScreenState();
}

class _ScrapbookBoardScreenState extends State<ScrapbookBoardScreen> with SingleTickerProviderStateMixin {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  late AnimationController _auraController;

  List<TimelineEntry> _entries = [];
  Map<int, Map<String, double>> _positions = {};
  bool _isLoading = true;
  bool _isDragging = false;
  int? _activeDragEntryId;

  String _boardTheme = 'corkboard'; // corkboard, pastel_aura, graph_paper, midnight_neon
  String _washiStyle = 'grid'; // grid, checkers, glitter, neon, push_pin

  static const Map<String, Color> _moodColors = {
    'hype': Color(0xFFFBBF24),
    'happy': Color(0xFFEC4899),
    'sad': Color(0xFF6366F1),
    'angry': Color(0xFFEF4444),
    'chill': Color(0xFF10B981),
    'none': Color(0xFF8B5CF6),
  };

  static const Map<String, String> _moodEmojis = {
    'hype': '🌟',
    'happy': '☀️',
    'sad': '🌧️',
    'angry': '🔥',
    'chill': '☁️',
    'none': '💬',
  };

  @override
  void initState() {
    super.initState();
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    );
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _auraController.repeat();
    }
    _loadScrapbookData();
  }

  @override
  void dispose() {
    _auraController.dispose();
    super.dispose();
  }

  Future<void> _loadScrapbookData() async {
    try {
      final theme = await widget.settingsService.getScrapbookBoardTheme();
      final style = await widget.settingsService.getScrapbookWashiStyle();
      final savedPositions = await widget.settingsService.getScrapbookLayoutPositions();
      final allEntries = await widget.timelineService.loadTimelineEntries();

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      // Fetch 30 most recent unlocked, unhidden entries, excluding bot bubbles or wrapped recaps
      final filtered = allEntries.where((entry) =>
          !entry.isHidden &&
          (entry.unlockAt == null || entry.unlockAt! <= nowMs) &&
          !entry.isBot &&
          entry.type != 'weekly_wrapped').take(30).toList();

      setState(() {
        _boardTheme = theme;
        _washiStyle = style;
        _positions = savedPositions;
        _entries = filtered;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeDefaultPositions(double canvasWidth) {
    final random = Random(88);
    bool changed = false;
    for (int i = 0; i < _entries.length; i++) {
      final entryId = _entries[i].entryId;
      if (!_positions.containsKey(entryId)) {
        final isLeft = i % 2 == 0;
        final x = isLeft
            ? 24.0 + random.nextDouble() * 20.0
            : canvasWidth - 184.0 - random.nextDouble() * 20.0;
        final row = i ~/ 2;
        final y = 80.0 + row * 230.0 + random.nextDouble() * 30.0;
        final rotation = -5.0 + random.nextDouble() * 10.0;

        _positions[entryId] = {
          'x': x,
          'y': y,
          'rotation': rotation,
        };
        changed = true;
      }
    }
    if (changed) {
      widget.settingsService.setScrapbookLayoutPositions(_positions);
    }
  }

  Future<void> _changeTheme(String newTheme) async {
    await widget.settingsService.setScrapbookBoardTheme(newTheme);
    setState(() {
      _boardTheme = newTheme;
    });
  }

  Future<void> _changeWashiStyle(String newStyle) async {
    await widget.settingsService.setScrapbookWashiStyle(newStyle);
    setState(() {
      _washiStyle = newStyle;
    });
  }

  Future<void> _organizeGrid(double canvasWidth) async {
    final random = Random(42);
    final newPositions = <int, Map<String, double>>{};
    for (int i = 0; i < _entries.length; i++) {
      final entryId = _entries[i].entryId;
      final isLeft = i % 2 == 0;
      final x = isLeft ? 24.0 : canvasWidth - 184.0;
      final row = i ~/ 2;
      final y = 80.0 + row * 220.0;
      final rotation = -2.0 + random.nextDouble() * 4.0;

      newPositions[entryId] = {
        'x': x,
        'y': y,
        'rotation': rotation,
      };
    }
    await widget.settingsService.setScrapbookLayoutPositions(newPositions);
    setState(() {
      _positions = newPositions;
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _exportCanvas() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final picturesDir = Directory('${directory.path}/Chronicle_Scrapbook');
      if (!await picturesDir.exists()) {
        await picturesDir.create(recursive: true);
      }

      final filename = 'Scrapbook_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${picturesDir.path}/$filename');
      await file.writeAsBytes(pngBytes);

      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Collage saved! 🎨 (Documents/Chronicle_Scrapbook/$filename)'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to export scrapbook board.')),
      );
    }
  }

  void _bringToFront(int entryId) {
    setState(() {
      final index = _entries.indexWhere((e) => e.entryId == entryId);
      if (index != -1) {
        final entry = _entries.removeAt(index);
        _entries.add(entry);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0E17),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final canvasWidth = screenWidth > 400 ? screenWidth : 400.0;
    const canvasHeight = 2400.0;

    _initializeDefaultPositions(canvasWidth);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Memory Scrapbook',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _boardTheme == 'midnight_neon' ? const Color(0xFF0F0E17) : Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _exportCanvas,
            tooltip: 'Export Scrapbook',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Repaint boundary wraps the scrollable canvas content
          Positioned.fill(
            child: SingleChildScrollView(
              physics: _isDragging ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
              child: RepaintBoundary(
                key: _repaintBoundaryKey,
                child: Container(
                  width: canvasWidth,
                  height: canvasHeight,
                  child: Stack(
                    children: [
                      // Backdrop Layer
                      Positioned.fill(
                        child: _buildBackdrop(canvasWidth, canvasHeight),
                      ),
                      // Collage Cards Layer
                      ..._entries.map((entry) => _buildDraggableCard(entry, canvasWidth, canvasHeight)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Customization Panel at bottom
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: SafeArea(
              child: Center(
                child: _buildControlPanel(canvasWidth),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackdrop(double width, double height) {
    if (_boardTheme == 'pastel_aura') {
      return AnimatedBuilder(
        animation: _auraController,
        builder: (context, _) {
          return CustomPaint(
            painter: _PastelAuraPainter(_auraController.value),
          );
        },
      );
    } else if (_boardTheme == 'graph_paper') {
      return Container(
        color: const Color(0xFFFAF9F5),
        child: CustomPaint(
          painter: _GraphPaperPainter(),
        ),
      );
    } else if (_boardTheme == 'midnight_neon') {
      return AnimatedBuilder(
        animation: _auraController,
        builder: (context, _) {
          return CustomPaint(
            painter: _MidnightNeonPainter(_auraController.value),
          );
        },
      );
    } else {
      // Warm Corkboard (default)
      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF8B5A2B), Color(0xFF5C4033)],
            radius: 1.2,
          ),
        ),
        child: CustomPaint(
          painter: _CorkboardPainter(),
        ),
      );
    }
  }

  Widget _buildDraggableCard(TimelineEntry entry, double canvasWidth, double canvasHeight) {
    final pos = _positions[entry.entryId] ?? {'x': 20.0, 'y': 80.0, 'rotation': 0.0};
    final x = pos['x']!;
    final y = pos['y']!;
    final rotation = pos['rotation']! * pi / 180;
    final isDraggingThis = _activeDragEntryId == entry.entryId;

    final cardWidth = entry.mediaPath != null ? 160.0 : 150.0;
    final cardHeight = entry.mediaPath != null ? 210.0 : 160.0;

    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: isDraggingThis ? 0.0 : rotation,
        child: GestureDetector(
          onPanStart: (_) {
            _bringToFront(entry.entryId);
            setState(() {
              _isDragging = true;
              _activeDragEntryId = entry.entryId;
            });
            HapticFeedback.selectionClick();
          },
          onPanUpdate: (details) {
            setState(() {
              final current = _positions[entry.entryId]!;
              double newX = current['x']! + details.delta.dx;
              double newY = current['y']! + details.delta.dy;

              // Constrain drag to canvas limits
              newX = newX.clamp(0.0, canvasWidth - cardWidth);
              newY = newY.clamp(0.0, canvasHeight - cardHeight);

              current['x'] = newX;
              current['y'] = newY;
            });
          },
          onPanEnd: (_) {
            widget.settingsService.setScrapbookLayoutPositions(_positions);
            setState(() {
              _isDragging = false;
              _activeDragEntryId = null;
            });
            HapticFeedback.lightImpact();
          },
          child: AnimatedScale(
            scale: isDraggingThis ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Inner Card structure
                _buildCardBody(entry, isDraggingThis),
                // Washi Tape or Pin overlay
                Positioned(
                  top: -8,
                  child: _buildPinOrTape(entry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBody(TimelineEntry entry, bool isDragging) {
    final primaryColor = _moodColors[entry.mood] ?? _moodColors['none']!;
    final emoji = _moodEmojis[entry.mood] ?? '💬';
    final dateStr = _formatShortDate(entry.createdAt);

    final shadows = [
      BoxShadow(
        color: Colors.black.withOpacity(isDragging ? 0.35 : 0.18),
        blurRadius: isDragging ? 16 : 8,
        spreadRadius: isDragging ? 2 : 0,
        offset: isDragging ? const Offset(0, 10) : const Offset(0, 3),
      ),
    ];

    if (entry.mediaPath != null && entry.mediaFile != null) {
      // Polaroid Snapshot Card
      return Container(
        width: 160,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9FB), // off-white polaroid frame
          borderRadius: BorderRadius.circular(2),
          boxShadow: shadows,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(1),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.file(
                  entry.mediaFile!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              dateStr,
              style: GoogleFonts.caveat(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.locationName ?? '$emoji Mood',
                    style: GoogleFonts.caveat(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: entry.locationName != null ? Colors.blueGrey[800] : primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(emoji, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      );
    } else {
      // Sticky Note Card (Text Only)
      final textBg = primaryColor.withOpacity(0.22);
      final borderSide = BorderSide(color: primaryColor.withOpacity(0.35), width: 1);

      return ClipPath(
        clipper: TornEdgeClipper(seed: entry.entryId),
        child: Container(
          width: 150,
          height: 160,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: textBg.withAlpha(240),
            border: Border(
              left: borderSide,
              right: borderSide,
              top: borderSide,
            ),
            boxShadow: shadows,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dateStr,
                      style: GoogleFonts.caveat(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(emoji, style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  entry.content,
                  style: GoogleFonts.caveat(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                    height: 1.2,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildPinOrTape(TimelineEntry entry) {
    final color = _moodColors[entry.mood] ?? _moodColors['none']!;

    if (_washiStyle == 'push_pin') {
      return PushPinWidget(color: color);
    }

    // Default washi tape
    return Transform.rotate(
      angle: -0.04 + Random(entry.entryId).nextDouble() * 0.08,
      child: WashiTapeWidget(
        style: _washiStyle,
        color: color,
      ),
    );
  }

  Widget _buildControlPanel(double canvasWidth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.palette_outlined, color: Colors.white),
            onPressed: () => _showThemeSelector(context),
            tooltip: 'Board Backdrop',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.style_outlined, color: Colors.white),
            onPressed: () => _showWashiStyleSelector(context),
            tooltip: 'Washi Tape Style',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.grid_view, color: Colors.white),
            onPressed: () => _organizeGrid(canvasWidth),
            tooltip: 'Organize Grid',
          ),
        ],
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16151D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Backdrop Theme',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildThemeOption('corkboard', '🪵', 'Corkboard'),
                  _buildThemeOption('pastel_aura', '🌸', 'Pastel Aura'),
                  _buildThemeOption('graph_paper', '📝', 'Graph Paper'),
                  _buildThemeOption('midnight_neon', '🌌', 'Midnight'),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(String id, String icon, String name) {
    final isSelected = _boardTheme == id;
    return GestureDetector(
      onTap: () {
        _changeTheme(id);
        Navigator.pop(context);
        HapticFeedback.selectionClick();
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showWashiStyleSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16151D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize Pin Style',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWashiOption('grid', '🏁', 'Grid Tape'),
                  _buildWashiOption('checkers', '⬜', 'Checkers'),
                  _buildWashiOption('glitter', '✨', 'Glitter'),
                  _buildWashiOption('neon', '🌈', 'Neon tape'),
                  _buildWashiOption('push_pin', '📌', 'Pushpin'),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWashiOption(String id, String icon, String name) {
    final isSelected = _washiStyle == id;
    return GestureDetector(
      onTap: () {
        _changeWashiStyle(id);
        Navigator.pop(context);
        HapticFeedback.selectionClick();
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final yearShort = date.year % 100;
    return '${months[date.month - 1]} ${date.day}, \'$yearShort';
  }
}

class TornEdgeClipper extends CustomClipper<Path> {
  TornEdgeClipper({this.seed = 42});
  final int seed;

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 12);

    final random = Random(seed);
    const step = 8.0;
    bool up = true;
    for (double x = 0; x < size.width; x += step) {
      final variance = random.nextDouble() * 3.0;
      final y = size.height - (up ? 12.0 + variance : 2.0 + variance);
      path.lineTo(x, y);
      up = !up;
    }

    path.lineTo(size.width, size.height - 12);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class WashiTapeWidget extends StatelessWidget {
  const WashiTapeWidget({super.key, required this.style, required this.color});

  final String style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    Decoration decoration;
    Widget? patternChild;

    if (style == 'checkers') {
      decoration = BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      );
      patternChild = CustomPaint(
        painter: _CheckersPainter(),
      );
    } else if (style == 'glitter') {
      decoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      );
      patternChild = CustomPaint(
        painter: _GlitterPainter(),
      );
    } else if (style == 'neon') {
      decoration = BoxDecoration(
        color: color.withOpacity(0.75),
        borderRadius: BorderRadius.circular(1),
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      );
    } else {
      // Default: grid washi tape
      decoration = BoxDecoration(
        color: const Color(0xFFF0F4F8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      );
      patternChild = CustomPaint(
        painter: _GridWashiPainter(),
      );
    }

    return Container(
      width: 60,
      height: 16,
      decoration: decoration,
      child: patternChild,
    );
  }
}

class _CheckersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black87;
    const squareSize = 4.0;
    for (double x = 0; x < size.width; x += squareSize) {
      for (double y = 0; y < size.height; y += squareSize) {
        if (((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, squareSize, squareSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridWashiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF90CAF9)
      ..strokeWidth = 0.6;
    const step = 5.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlitterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint()..color = Colors.white.withOpacity(0.85);
    for (int i = 0; i < 12; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 0.8 + random.nextDouble() * 1.2;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PushPinWidget extends StatelessWidget {
  const PushPinWidget({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 2,
            top: 2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [color.withRed(255), color, color.withOpacity(0.7)],
                center: const Alignment(-0.25, -0.25),
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
          ),
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: Colors.white70,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CorkboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(88);
    final paint = Paint();

    for (int i = 0; i < 800; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1.0 + random.nextDouble() * 2.0;
      paint.color = random.nextBool()
          ? Colors.black.withOpacity(0.07)
          : Colors.white.withOpacity(0.04);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GraphPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final marginPaint = Paint()
      ..color = const Color(0xFFFECACA)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(40, 0), Offset(40, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PastelAuraPainter extends CustomPainter {
  _PastelAuraPainter(this.animationValue);
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final angle = animationValue * 2 * pi;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEDF7ED),
    );

    final pinkCenter = Offset(
      size.width * 0.35 + 40 * cos(angle),
      size.height * 0.45 + 40 * sin(angle),
    );
    canvas.drawCircle(
      pinkCenter,
      size.width * 0.75,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFCE4EC).withOpacity(0.8),
            const Color(0xFFFCE4EC).withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: pinkCenter, radius: size.width * 0.75)),
    );

    final lavenderCenter = Offset(
      size.width * 0.65 + 50 * sin(angle),
      size.height * 0.55 + 50 * cos(angle),
    );
    canvas.drawCircle(
      lavenderCenter,
      size.width * 0.85,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF3E5F5).withOpacity(0.8),
            const Color(0xFFF3E5F5).withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: lavenderCenter, radius: size.width * 0.85)),
    );
  }

  @override
  bool shouldRepaint(covariant _PastelAuraPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _MidnightNeonPainter extends CustomPainter {
  _MidnightNeonPainter(this.animationValue);
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final angle = animationValue * 2 * pi;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0F0E17),
    );

    final purpleCenter = Offset(
      size.width * 0.25 + 40 * sin(angle),
      size.height * 0.75 + 40 * cos(angle),
    );
    canvas.drawCircle(
      purpleCenter,
      size.width * 0.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF9D4EDD).withOpacity(0.18),
            const Color(0xFF9D4EDD).withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: purpleCenter, radius: size.width * 0.6)),
    );

    final cyanCenter = Offset(
      size.width * 0.75 + 40 * cos(angle),
      size.height * 0.25 + 40 * sin(angle),
    );
    canvas.drawCircle(
      cyanCenter,
      size.width * 0.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF00B4D8).withOpacity(0.18),
            const Color(0xFF00B4D8).withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(center: cyanCenter, radius: size.width * 0.6)),
    );
  }

  @override
  bool shouldRepaint(covariant _MidnightNeonPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
