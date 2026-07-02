import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

class EmberParticlesWidget extends StatefulWidget {
  const EmberParticlesWidget({super.key});

  @override
  State<EmberParticlesWidget> createState() => _EmberParticlesWidgetState();
}

class _EmberParticlesWidgetState extends State<EmberParticlesWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_EmberParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _controller.repeat();
    }

    // Initialize particles
    for (int i = 0; i < 12; i++) {
      _particles.add(_EmberParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.1 + 0.05,
        opacity: _random.nextDouble() * 0.6 + 0.2,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update particles position
        for (final particle in _particles) {
          particle.y -= particle.speed * 0.015;
          if (particle.y < 0) {
            particle.y = 1.0;
            particle.x = _random.nextDouble();
          }
        }
        return CustomPaint(
          painter: _EmberPainter(_particles),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _EmberParticle {
  _EmberParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });

  double x; // 0.0 to 1.0
  double y; // 0.0 to 1.0
  final double size;
  final double speed;
  final double opacity;
}

class _EmberPainter extends CustomPainter {
  _EmberPainter(this.particles);

  final List<_EmberParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      final px = particle.x * size.width;
      final py = particle.y * size.height;
      
      paint.color = const Color(0xFFF97316).withOpacity(particle.opacity); // Tailwind Orange 500
      
      // Draw small soft glowing circles
      canvas.drawCircle(Offset(px, py), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter oldDelegate) => true;
}
