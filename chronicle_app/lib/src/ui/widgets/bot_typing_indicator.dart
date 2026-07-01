import 'dart:ui';
import 'package:flutter/material.dart';

class BotTypingIndicator extends StatefulWidget {
  const BotTypingIndicator({super.key});

  @override
  State<BotTypingIndicator> createState() => _BotTypingIndicatorState();
}

class _BotTypingIndicatorState extends State<BotTypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Offset each dot's animation phase
        final delay = index * 0.2;
        double progress = (_controller.value - delay) % 1.0;
        if (progress < 0) progress += 1.0;

        // Pulse scale & opacity
        double scale = 1.0;
        double opacity = 0.3;
        if (progress < 0.4) {
          final t = progress / 0.4;
          scale = 1.0 + 0.35 * t;
          opacity = 0.3 + 0.7 * t;
        } else if (progress < 0.8) {
          final t = (progress - 0.4) / 0.4;
          scale = 1.35 - 0.35 * t;
          opacity = 1.0 - 0.7 * t;
        }

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF06B6D4), // Cyan
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
            bottomLeft: Radius.circular(6),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  bottomLeft: Radius.circular(6),
                ),
                border: Border.all(
                  color: const Color(0xFF06B6D4).withOpacity(0.3), // Cyan accent border
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  _buildDot(0),
                  const SizedBox(width: 6),
                  _buildDot(1),
                  const SizedBox(width: 6),
                  _buildDot(2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
