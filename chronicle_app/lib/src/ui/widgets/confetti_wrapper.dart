import 'dart:math' as math;
import 'package:flutter/material.dart';

class ConfettiWrapper extends StatefulWidget {
  const ConfettiWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<ConfettiWrapper> createState() => _ConfettiWrapperState();
}

class _ConfettiWrapperState extends State<ConfettiWrapper> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    final rand = math.Random();
    final colors = [
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.blueAccent,
      Colors.yellowAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
    ];
    for (int i = 0; i < 30; i++) {
      _particles.add(_ConfettiParticle(
        color: colors[rand.nextInt(colors.length)],
        angle: rand.nextDouble() * 2 * math.pi,
        speed: 80.0 + rand.nextDouble() * 120.0,
        size: 6.0 + rand.nextDouble() * 8.0,
        rotationSpeed: rand.nextDouble() * 4 * math.pi,
        shape: rand.nextInt(3),
      ));
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (_controller.isCompleted) {
              return const SizedBox.shrink();
            }
            final t = _controller.value;
            final opacity = (1.0 - t).clamp(0.0, 1.0);

            return Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: t,
                    opacity: opacity,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.color,
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.shape,
  });

  final Color color;
  final double angle;
  final double speed;
  final double size;
  final double rotationSpeed;
  final int shape; // 0: circle, 1: square, 2: triangle
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.opacity,
  });

  final List<_ConfettiParticle> particles;
  final double progress;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      final double distance = p.speed * progress;
      final double gravity = 200.0 * progress * progress;
      
      final double dx = distance * math.cos(p.angle);
      final double dy = distance * math.sin(p.angle) + gravity;
      
      final particleOffset = center + Offset(dx, dy);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(particleOffset.dx, particleOffset.dy);
      canvas.rotate(p.rotationSpeed * progress);

      if (p.shape == 0) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else if (p.shape == 1) {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size), paint);
      } else {
        final path = Path()
          ..moveTo(0, -p.size / 2)
          ..lineTo(p.size / 2, p.size / 2)
          ..lineTo(-p.size / 2, p.size / 2)
          ..close();
        canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.opacity != opacity;
  }
}
