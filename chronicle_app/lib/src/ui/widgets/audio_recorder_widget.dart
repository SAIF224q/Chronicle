import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioRecorderWidget extends StatefulWidget {
  const AudioRecorderWidget({super.key, required this.onAudioRecorded});

  final ValueChanged<File?> onAudioRecorded;

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

enum RecorderState { idle, recording, preview }

class _AudioRecorderWidgetState extends State<AudioRecorderWidget>
    with SingleTickerProviderStateMixin {
  late final AudioRecorder _audioRecorder;
  AudioPlayer? _previewPlayer;
  RecorderState _state = RecorderState.idle;

  Timer? _timer;
  int _recordSeconds = 0;
  String? _recordedFilePath;
  bool _isPlayingPreview = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _previewPlayer?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = p.join(
          tempDir.path,
          'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );

        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);

        _pulseController.repeat();

        setState(() {
          _state = RecorderState.recording;
          _recordSeconds = 0;
          _recordedFilePath = path;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordSeconds++;
          });
        });
      } else {
        _showErrorSnackBar('Microphone permission is required to record voice notes.');
      }
    } catch (e) {
      _showErrorSnackBar('Could not start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _state = RecorderState.preview;
          _recordedFilePath = path;
        });
        widget.onAudioRecorded(File(path));
      }
    } catch (e) {
      _showErrorSnackBar('Could not stop recording: $e');
    }
  }

  Future<void> _cancelRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    await _audioRecorder.stop();
    if (_recordedFilePath != null) {
      final file = File(_recordedFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    setState(() {
      _state = RecorderState.idle;
      _recordedFilePath = null;
      _recordSeconds = 0;
    });
    widget.onAudioRecorded(null);
  }

  Future<void> _togglePreview() async {
    if (_recordedFilePath == null) return;

    if (_previewPlayer == null) {
      _previewPlayer = AudioPlayer();
      _previewPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlayingPreview = state == PlayerState.playing;
          });
        }
      });
    }

    if (_isPlayingPreview) {
      await _previewPlayer!.pause();
    } else {
      await _previewPlayer!.play(DeviceFileSource(_recordedFilePath!));
    }
  }

  Future<void> _deleteRecordedPreview() async {
    if (_previewPlayer != null) {
      await _previewPlayer!.stop();
    }
    if (_recordedFilePath != null) {
      final file = File(_recordedFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    setState(() {
      _state = RecorderState.idle;
      _recordedFilePath = null;
      _isPlayingPreview = false;
    });
    widget.onAudioRecorded(null);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (_state) {
      case RecorderState.idle:
        return OutlinedButton.icon(
          onPressed: _startRecording,
          icon: const Icon(Icons.mic_rounded, size: 20),
          label: const Text('Record Voice Note'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            side: BorderSide(
              color: isDark ? const Color(0xFF2C2825) : colorScheme.outlineVariant,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );

      case RecorderState.recording:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1A17) : colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Waveform pulsing animation
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (index) {
                  final offset = index * (math.pi / 4);
                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final angle = (_pulseController.value * 2 * math.pi) + offset;
                      final scale = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(angle));
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 3.5,
                        height: 18 * scale,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.4 + 0.6 * scale),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(width: 14),
              Text(
                _formatDuration(_recordSeconds),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.delete_outline_rounded, size: 22),
                color: Colors.red.shade400,
                tooltip: 'Discard',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _stopRecording,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop_rounded, size: 18),
                    SizedBox(width: 4),
                    Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );

      case RecorderState.preview:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1A17) : colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2825) : colorScheme.outlineVariant.withOpacity(0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _togglePreview,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _isPlayingPreview ? colorScheme.primary.withOpacity(0.15) : colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _isPlayingPreview ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _isPlayingPreview 
                        ? colorScheme.primary 
                        : (isDark ? Colors.black : Colors.white),
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Voice Note Attached',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _recordedFilePath != null ? p.basename(_recordedFilePath!) : '',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _deleteRecordedPreview,
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 22),
                tooltip: 'Discard',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        );
    }
  }
}
