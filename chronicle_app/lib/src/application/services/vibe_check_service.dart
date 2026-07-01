import 'dart:math';

class VibeCheckService {
  static const Map<String, List<String>> moodPrompts = {
    'hype': [
      "Love that energy! 🌟 What went super well today? Drop the highlight!",
      "Celebrate that win! 🥂 Who else was part of this vibe today?",
      "Keep that momentum! 🚀 What are you excited to tackle next?"
    ],
    'chill': [
      "Cozy vibes ☁️. What was a small moment of peace or relaxation today?",
      "Low key days are the best. What did you spend your downtime doing?",
      "Chill mode activated. Rate your comfort level today from 1 to 10!"
    ],
    'chaotic': [
      "Sounds wild ⚡! What made today feel so hectic or unpredictable?",
      "A bit of chaos keeps life interesting. How did you handle the spins?",
      "Breathe in... breathe out. What was the most unexpected thing that happened?"
    ],
    'blue': [
      "Sending a gentle hug 🌧️. What's sitting heavy on your heart today?",
      "It's okay not to be okay. What is one thing that could make you feel 1% cozier?",
      "Let it out. Want to write down or record what's causing this blue mood?"
    ],
    'stressed': [
      "Take a deep breath 🌪️. What is the biggest thing draining your energy right now?",
      "Pressure is temporary. What is one small task you can delegate or ignore today?",
      "Let's untangle this. List 3 things you can control, and let go of the rest."
    ],
    'grateful': [
      "Beautiful attitude 🌸. Who or what are you most thankful for right now?",
      "Gratitude grows joy. Share one simple thing that made you smile today.",
      "What's a warm memory from today that you want to remember forever?"
    ],
    'none': [
      "Hey! Just a quick check-in. How has your day been shaping up so far?",
      "Time for a quick pause. What's the main theme of your day?",
      "What's on your mind right now? Share anything, big or small!"
    ]
  };

  final Random _random;

  VibeCheckService({Random? random}) : _random = random ?? Random();

  String getFollowUpPrompt(String mood) {
    final prompts = moodPrompts[mood] ?? moodPrompts['none']!;
    final index = _random.nextInt(prompts.length);
    return prompts[index];
  }

  String getFinalSupportResponse(String mood) {
    switch (mood) {
      case 'hype':
      case 'grateful':
        return "Got it! Love to see you winning. Keep that positive energy going! ✨";
      case 'chill':
        return "Nice. Enjoy your peace and have a relaxing rest of your day! ☁️";
      case 'chaotic':
        return "Whew, what a ride. Take care of yourself and stay grounded! 🌀";
      case 'blue':
      case 'stressed':
        return "Got it. Sending you calm vibes and a gentle virtual hug. Take it easy! 🤍";
      default:
        return "Thanks for checking in! Keep doing you. 🤖";
    }
  }
}
