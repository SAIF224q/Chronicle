import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../application/services/timeline_service.dart';
import 'ember_particle_painter.dart';

class BurnBubbleWrapper extends StatefulWidget {
  const BurnBubbleWrapper({
    super.key,
    required this.entry,
    required this.child,
    required this.onCombustionComplete,
  });

  final TimelineEntry entry;
  final Widget child;
  final VoidCallback onCombustionComplete;

  @override
  State<BurnBubbleWrapper> createState() => BurnBubbleWrapperState();
}

class BurnBubbleWrapperState extends State<BurnBubbleWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _burnController;
  late Animation<double> _textOpacity;
  late Animation<double> _crackProgress;
  late Animation<double> _bubbleScale;
  late Animation<double> _bubbleOpacity;

  Timer? _countdownTimer;
  int _secondsRemaining = 0;
  bool _isBurning = false;

  @override
  void initState() {
    super.initState();
    _burnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _textOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _burnController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _crackProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _burnController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeInOut),
      ),
    );

    _bubbleScale = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _burnController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInBack),
      ),
    );

    _bubbleOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _burnController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _burnController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCombustionComplete();
      }
    });

    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _burnController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    if (widget.entry.burnAt == null) return;

    _updateRemainingTime();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    if (widget.entry.burnAt == null || _isBurning) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = (widget.entry.burnAt! - now) ~/ 1000;

    if (diff <= 0) {
      _secondsRemaining = 0;
      _countdownTimer?.cancel();
      triggerCombustion();
    } else {
      setState(() {
        _secondsRemaining = diff;
      });
    }
  }

  Future<void> triggerCombustion() async {
    if (_isBurning) return;
    _countdownTimer?.cancel();
    setState(() {
      _isBurning = true;
    });
    await _burnController.forward();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minsStr = minutes.toString().padLeft(2, '0');
    final secsStr = seconds.toString().padLeft(2, '0');
    return '$minsStr:$secsStr';
  }

  @override
  Widget build(BuildContext context) {
    final hasTimer = widget.entry.burnAt != null;
    final timerText = hasTimer ? _formatDuration(_secondsRemaining) : 'Session only';
    final timerIcon = hasTimer ? Icons.timer : Icons.air;

    return AnimatedBuilder(
      animation: _burnController,
      builder: (context, child) {
        return Transform.scale(
          scale: _bubbleScale.value,
          child: Opacity(
            opacity: _bubbleOpacity.value,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                gradient: LinearGradient(
                  colors: [Colors.grey.shade900, const Color(0xFF3B0712)], // deep red
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.35), // glowing red
                    blurRadius: 8.0,
                    spreadRadius: 1.0,
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFF87171).withOpacity(0.4), // crimson border
                  width: 1.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Ember particles drifting in the background
                  const Positioned.fill(
                    child: EmberParticlesWidget(),
                  ),
                  // Content area
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0, bottom: 32.0),
                    child: Opacity(
                      opacity: _textOpacity.value,
                      child: widget.child,
                    ),
                  ),
                  // Crack lines painted overlay
                  if (_crackProgress.value > 0.0)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CracksPainter(_crackProgress.value),
                      ),
                    ),
                  // Bottom timer countdown & session info overlay
                  Positioned(
                    bottom: 8.0,
                    right: 12.0,
                    child: Opacity(
                      opacity: _textOpacity.value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            timerIcon,
                            size: 13.0,
                            color: const Color(0xFFFCA5A5), // light red
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            timerText,
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFCA5A5),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _CracksPainter extends CustomPainter {
  _CracksPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEF4444).withOpacity(0.9 * (1.0 - progress)) // fades out as it completes
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 + 3.0 * progress
      ..strokeCap = StrokeCap.round;

    final rand = Random(42); // Seeded so cracks look the same
    final path = Path();

    // Draw 3-4 jagged lines starting from center radiating outwards
    final center = Offset(size.width / 2, size.height / 2);
    final crackCount = 4;

    for (int i = 0; i < crackCount; i++) {
      final angle = (i * 2 * pi / crackCount) + rand.nextDouble() * 0.5;
      var current = center;
      path.moveTo(current.dx, current.dy);
      
      final segmentCount = 4;
      final maxRadius = max(size.width, size.height) * 0.6 * progress;
      final segmentLen = maxRadius / segmentCount;

      for (int j = 0; j < segmentCount; j++) {
        final nextAngle = angle + (rand.nextDouble() - 0.5) * 0.4;
        current = current + Offset(cos(nextAngle) * segmentLen, sin(nextAngle) * segmentLen);
        path.lineTo(current.dx, current.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CracksPainter oldDelegate) => oldDelegate.progress != progress;
}
