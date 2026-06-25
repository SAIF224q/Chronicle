import 'dart:io';
import 'dart:math';

class SpeechToTextService {
  const SpeechToTextService();

  Future<String> transcribe(File audioFile) async {
    // Simulate on-device transcription latency of 1500ms
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    final phrases = [
      "just finished watching the sunset and feeling so peaceful right now #chill",
      "omg had the most chaotic day today but we survived #chaotic",
      "feeling so hyped about the new project launch today #hype",
      "went for a long walk in the rain and feeling a bit blue #blue",
      "so stressed about the upcoming deadline, need to lock in #stressed",
      "so grateful for the beautiful weather today #grateful",
    ];

    final random = Random();
    return phrases[random.nextInt(phrases.length)];
  }
}
