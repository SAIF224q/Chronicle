import 'dart:async';
import 'dart:io';

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
      duration: const Duration(seconds: 1),
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

        _pulseController.repeat(reverse: true);

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

    switch (_state) {
      case RecorderState.idle:
        return OutlinedButton.icon(
          onPressed: _startRecording,
          icon: const Icon(Icons.mic_none_outlined),
          label: const Text('Record Voice Note'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );

      case RecorderState.recording:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.primary.withAlpha(50)),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3 + 0.7 * _pulseController.value),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                'Recording... ${_formatDuration(_recordSeconds)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                tooltip: 'Discard',
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _stopRecording,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop, size: 18),
                    SizedBox(width: 4),
                    Text('Done'),
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
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: _togglePreview,
                icon: Icon(
                  _isPlayingPreview ? Icons.pause : Icons.play_arrow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Note Attached',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _recordedFilePath != null ? p.basename(_recordedFilePath!) : '',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _deleteRecordedPreview,
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                tooltip: 'Discard',
              ),
            ],
          ),
        );
    }
  }
}
