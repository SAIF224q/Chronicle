import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronicle_app/src/application/services/timeline_service.dart';
import 'package:chronicle_app/src/ui/widgets/bot_typing_indicator.dart';
import 'package:chronicle_app/src/ui/widgets/timeline_item.dart';

void main() {
  group('Bot Widgets & Chat Integrations', () {
    testWidgets('BotTypingIndicator renders and displays robot emoji', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BotTypingIndicator(),
          ),
        ),
      );

      // Verify the typing indicator is visible
      expect(find.byType(BotTypingIndicator), findsOneWidget);
      expect(find.text('🤖'), findsOneWidget);
    });

    testWidgets('TimelineItem renders quick-reply choice chips for unanswered bot prompts', (WidgetTester tester) async {
      final botPromptEntry = TimelineEntry(
        entryId: 99,
        type: 'bot_prompt',
        content: 'How has your day been shaping up so far? 🤖',
        mediaPath: null,
        mediaFile: null,
        createdAt: DateTime.now(),
        isHidden: false,
        tags: const [],
        mood: 'none',
      );

      String? selectedMood;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimelineItem(
              entry: botPromptEntry,
              isRevealed: false,
              onTagTap: (_) {},
              onEditTap: () {},
              onDeleteTap: () {},
              onHiddenPlaceholderTap: () {},
              onImageTap: (_) {},
              isLastBotPrompt: true,
              onChoiceSelected: (mood) {
                selectedMood = mood;
              },
            ),
          ),
        ),
      );

      // Verify prompt content and quick-reply chips are visible
      expect(find.text('How has your day been shaping up so far? 🤖'), findsOneWidget);
      expect(find.text('Vibe Check-In'), findsOneWidget);
      expect(find.text('🌟 Hype'), findsOneWidget);
      expect(find.text('☁️ Chill'), findsOneWidget);
      expect(find.text('🌪️ Stressed'), findsOneWidget);

      // Tap on a choice chip
      await tester.tap(find.text('🌟 Hype'));
      await tester.pump();

      // Verify callback triggers
      expect(selectedMood, 'hype');
    });
  });
}
