import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

class VinylPlayerWidget extends StatefulWidget {
  const VinylPlayerWidget({
    super.key,
    required this.trackId,
    required this.trackTitle,
    required this.trackArtist,
    required this.trackArtworkUrl,
    required this.spotifyUrl,
    required this.audioPreviewUrl,
    this.primaryColor,
    this.secondaryColor,
    required this.onSoundtrackRemoved,
  });

  final String trackId;
  final String trackTitle;
  final String trackArtist;
  final String trackArtworkUrl;
  final String spotifyUrl;
  final String audioPreviewUrl;
  final Color? primaryColor;
  final Color? secondaryColor;
  final VoidCallback onSoundtrackRemoved;

  @override
  State<VinylPlayerWidget> createState() => _VinylPlayerWidgetState();
}

// Global player coordinator to ensure only one vinyl plays at a time
AudioPlayer? _currentGlobalPlayer;
VoidCallback? _onGlobalStop;

class _VinylPlayerWidgetState extends State<VinylPlayerWidget> with TickerProviderStateMixin {
  late final AudioPlayer _audioPlayer;
  late final AnimationController _rotationController;
  late final AnimationController _armController;

  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = const Duration(seconds: 30);
  Duration _position = Duration.zero;

  // Stream Subscriptions
  StreamSubscription? _stateSub;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _compSub;

  // Particle notes
  final List<_FloatingParticle> _particles = [];
  Timer? _particleTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800), // 33 RPM (approx 1.8 seconds per turn)
    );

    _armController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _initAudioListeners();
  }

  void _initAudioListeners() {
    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        if (_isPlaying) {
          if (!Platform.environment.containsKey('FLUTTER_TEST')) {
            _rotationController.repeat();
          }
          _armController.forward();
          _startParticleTimer();
        } else {
          _rotationController.stop();
          _armController.reverse();
          _stopParticleTimer();
        }
      });
    });

    _posSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (!mounted) return;
      setState(() {
        _position = pos;
      });
    });

    _durSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (!mounted) return;
      setState(() {
        _duration = dur;
      });
    });

    _compSub = _audioPlayer.onPlayerComplete.listen((event) {
      if (!mounted) return;
      setState(() {
        _position = Duration.zero;
        _isPlaying = false;
        _rotationController.stop();
        _armController.reverse();
        _stopParticleTimer();
      });
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _compSub?.cancel();
    _stopParticleTimer();

    // If this was the active global player, clean up references
    if (_currentGlobalPlayer == _audioPlayer) {
      _currentGlobalPlayer = null;
      _onGlobalStop = null;
    }

    _audioPlayer.dispose();
    _rotationController.dispose();
    _armController.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isLoading) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      // Coordinate global single-play behavior
      if (_currentGlobalPlayer != null && _currentGlobalPlayer != _audioPlayer) {
        await _currentGlobalPlayer!.stop();
        _onGlobalStop?.call();
      }

      _currentGlobalPlayer = _audioPlayer;
      _onGlobalStop = () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _rotationController.stop();
            _armController.reverse();
            _stopParticleTimer();
          });
        }
      };

      setState(() {
        _isLoading = true;
      });

      try {
        await _audioPlayer.setSource(UrlSource(widget.audioPreviewUrl));
        await _audioPlayer.resume();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load audio preview')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _startParticleTimer() {
    _particleTimer?.cancel();
    _particleTimer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (!mounted) return;
      setState(() {
        _particles.add(_FloatingParticle(
          x: 25.0 + math.Random().nextDouble() * 20.0,
          y: 60.0,
          icon: math.Random().nextBool() ? Icons.music_note : Icons.music_video_outlined,
          color: widget.primaryColor ?? Colors.tealAccent,
        ));
      });
    });

    // Particle animator loop
    _rotationController.addListener(_updateParticles);
  }

  void _stopParticleTimer() {
    _particleTimer?.cancel();
    _rotationController.removeListener(_updateParticles);
    _particles.clear();
  }

  void _updateParticles() {
    if (!mounted || _particles.isEmpty) return;
    setState(() {
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.y -= 1.8;
        p.x += math.sin(p.y * 0.05) * 0.8;
        p.opacity -= 0.02;
        if (p.y < 0 || p.opacity <= 0) {
          _particles.removeAt(i);
        }
      }
    });
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E0E15),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.rocket_launch, color: Colors.tealAccent),
                title: const Text('Open on Spotify 🚀', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse(widget.spotifyUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Remove Soundtrack 🗑️', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onSoundtrackRemoved();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sticker background
    final isCustomColor = widget.trackArtworkUrl.startsWith('custom_color:');
    Color stickerColor = Colors.teal;
    if (isCustomColor) {
      final hexStr = widget.trackArtworkUrl.split(':').last;
      stickerColor = Color(int.parse('0xFF${hexStr.replaceFirst('#', '')}'));
    }

    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        width: 240,
        child: Row(
          children: [
            // Left side: Vinyl Player and particles
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Floating particles
                ..._particles.map((p) {
                  return Positioned(
                    left: p.x,
                    top: p.y,
                    child: Opacity(
                      opacity: p.opacity.clamp(0.0, 1.0),
                      child: Icon(
                        p.icon,
                        color: p.color.withOpacity(0.8),
                        size: 14 * p.opacity,
                      ),
                    ),
                  );
                }),

                // Progress Glow Ring & Vinyl Stack
                GestureDetector(
                  onTap: _togglePlay,
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress ring
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 2,
                            backgroundColor: Colors.grey.shade900,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.primaryColor?.withOpacity(0.8) ?? Colors.tealAccent,
                            ),
                          ),
                        ),

                        // Vinyl Disk grooves
                        RotationTransition(
                          turns: _rotationController,
                          child: Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF09090B),
                              border: Border.all(color: Colors.grey.shade900, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.6),
                                  blurRadius: 4,
                                  offset: const Offset(1, 2),
                                )
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Grooves circles
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                                  ),
                                ),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                                  ),
                                ),
                                // Sticker
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    color: stickerColor,
                                    child: isCustomColor
                                        ? const Center(
                                            child: Icon(Icons.music_note, size: 10, color: Colors.white),
                                          )
                                        : Image.network(
                                            widget.trackArtworkUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, o, s) => Container(
                                              color: Colors.grey.shade800,
                                              child: const Icon(Icons.music_note, size: 10, color: Colors.white),
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Play/Pause center overlay indicator
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.tealAccent),
                          ),
                      ],
                    ),
                  ),
                ),

                // Swiveling Needle Arm pivoting from top right
                Positioned(
                  right: -4,
                  top: -8,
                  child: RotationTransition(
                    turns: Tween<double>(begin: -0.12, end: 0.0).animate(_armController),
                    alignment: Alignment.topRight,
                    child: SizedBox(
                      width: 24,
                      height: 42,
                      child: CustomPaint(
                        painter: _NeedleArmPainter(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Right side: Track Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.trackTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.trackArtist,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Progress time text
                  Text(
                    '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final sec = d.inSeconds % 60;
    final min = d.inMinutes;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}

class _FloatingParticle {
  _FloatingParticle({
    required this.x,
    required this.y,
    required this.icon,
    required this.color,
  });

  double x;
  double y;
  double opacity = 1.0;
  final IconData icon;
  final Color color;
}

class _NeedleArmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final metalPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final darkPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;

    // Draw arm pivot base at top right (18, 4)
    canvas.drawCircle(Offset(size.width - 6, 6), 4, darkPaint);
    canvas.drawCircle(Offset(size.width - 6, 6), 4, metalPaint);

    // Draw arm path down and left to the vinyl
    final path = Path()
      ..moveTo(size.width - 6, 6)
      ..lineTo(size.width - 8, 20)
      ..lineTo(6, 32);

    canvas.drawPath(path, metalPaint);

    // Draw stylus/needle head at end of path (6, 32)
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(6, 32), width: 5, height: 8),
      darkPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(6, 32), width: 5, height: 8),
      Paint()
        ..color = Colors.tealAccent
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
