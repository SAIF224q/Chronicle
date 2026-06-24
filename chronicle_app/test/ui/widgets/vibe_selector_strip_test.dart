import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronicle_app/src/ui/widgets/vibe_selector_strip.dart';

void main() {
  testWidgets('VibeSelectorStrip renders all vibe options', (WidgetTester tester) async {
    String selectedMood = 'none';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VibeSelectorStrip(
            selectedMood: selectedMood,
            onMoodSelected: (mood) {
              selectedMood = mood;
            },
          ),
        ),
      ),
    );

    // Verify Title
    expect(find.text('Select Vibe'), findsOneWidget);

    // Verify all vibes list emojis and labels
    expect(find.text('🌟'), findsOneWidget);
    expect(find.text('Hype'), findsOneWidget);
    expect(find.text('☁️'), findsOneWidget);
    expect(find.text('Chill'), findsOneWidget);
    expect(find.text('⚡'), findsOneWidget);
    expect(find.text('Chaotic'), findsOneWidget);
    expect(find.text('🌧️'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
    expect(find.text('🌪️'), findsOneWidget);
    expect(find.text('Stressed'), findsOneWidget);
    expect(find.text('🌸'), findsOneWidget);
    expect(find.text('Grateful'), findsOneWidget);
  });

  testWidgets('VibeSelectorStrip triggers callback on tap and handles deselection', (WidgetTester tester) async {
    String selectedMood = 'none';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return VibeSelectorStrip(
                selectedMood: selectedMood,
                onMoodSelected: (mood) {
                  setState(() {
                    selectedMood = mood;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    // Tap Chill Vibe
    await tester.tap(find.text('Chill'));
    await tester.pumpAndSettle();

    expect(selectedMood, 'chill');

    // Tap Chill Vibe again to deselect
    await tester.tap(find.text('Chill'));
    await tester.pumpAndSettle();

    expect(selectedMood, 'none');

    // Tap Chaotic Vibe
    await tester.tap(find.text('Chaotic'));
    await tester.pumpAndSettle();

    expect(selectedMood, 'chaotic');
  });
}
