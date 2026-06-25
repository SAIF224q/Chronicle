import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'audio_player_widget.dart';
import 'vibe_selector_strip.dart';

class VoiceTranscriptBubble extends StatefulWidget {
  const VoiceTranscriptBubble({
    super.key,
    required this.audioFile,
    this.transcript,
    required this.mood,
    required this.onTagTap,
  });

  final File audioFile;
  final String? transcript;
  final String mood;
  final ValueChanged<String> onTagTap;

  @override
  State<VoiceTranscriptBubble> createState() => _VoiceTranscriptBubbleState();
}

class _VoiceTranscriptBubbleState extends State<VoiceTranscriptBubble>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _clearRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clearRecognizers();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleTranscript() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Widget _buildTranscriptContent(BuildContext context, String text) {
    _clearRecognizers();

    final mood = widget.mood;
    final isDarkBubble = mood == 'chaotic' || mood == 'blue' || mood == 'stressed';
    
    Color textColor;
    Color tagColor;

    if (mood == 'none') {
      textColor = Theme.of(context).colorScheme.onSurface;
      tagColor = Theme.of(context).colorScheme.primary;
    } else {
      final vibe = vibesList.firstWhere(
        (v) => v.id == mood,
        orElse: () => vibesList[0],
      );
      if (isDarkBubble) {
        textColor = Colors.white;
        tagColor = mood == 'chaotic' 
            ? Colors.lightGreen.shade300 
            : (mood == 'stressed' ? Colors.orange.shade200 : Colors.amber.shade200);
      } else {
        textColor = vibe.textColor;
        tagColor = vibe.textColor;
      }
    }

    final RegExp hashtagRegex = RegExp(r'(?<!\S)#([A-Za-z0-9_]+)');
    final matches = hashtagRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: textColor.withOpacity(0.85),
          fontSize: 14,
          height: 1.4,
        ),
      );
    }

    final List<InlineSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: textColor.withOpacity(0.85),
          ),
        ));
      }

      final tagText = match.group(0)!;
      final tagWord = match.group(1)!;

      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onTagTap(tagWord);
      _recognizers.add(recognizer);

      spans.add(TextSpan(
        text: tagText,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: tagColor,
          fontStyle: FontStyle.normal,
        ),
        recognizer: recognizer,
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: textColor.withOpacity(0.85),
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: textColor,
        ),
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mood = widget.mood;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkBubble = mood == 'chaotic' || mood == 'blue' || mood == 'stressed';
    final hasTranscript = widget.transcript != null && widget.transcript!.trim().isNotEmpty;

    Color buttonBgColor;
    Color buttonTextColor;

    if (mood == 'none') {
      buttonBgColor = colorScheme.primary.withOpacity(0.08);
      buttonTextColor = colorScheme.primary;
    } else {
      final vibe = vibesList.firstWhere(
        (v) => v.id == mood,
        orElse: () => vibesList[0],
      );

      if (isDarkBubble) {
        buttonBgColor = Colors.white.withOpacity(0.12);
        buttonTextColor = mood == 'chaotic' ? Colors.lightGreen.shade300 : Colors.white;
      } else {
        buttonBgColor = vibe.color.withOpacity(0.15);
        buttonTextColor = vibe.textColor;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AudioPlayerWidget(audioFile: widget.audioFile),
        if (hasTranscript) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: _toggleTranscript,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: buttonBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isExpanded ? Icons.subtitles : Icons.subtitles_outlined,
                    size: 16,
                    color: buttonTextColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isExpanded ? 'Hide Transcript' : 'Read Transcript',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: buttonTextColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: buttonTextColor,
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            axisAlignment: -1.0,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkBubble
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDarkBubble
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    width: 1,
                  ),
                ),
                width: double.infinity,
                child: _buildTranscriptContent(context, widget.transcript!),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
