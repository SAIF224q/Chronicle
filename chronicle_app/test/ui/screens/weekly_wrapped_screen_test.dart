import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chronicle_app/src/application/services/timeline_service.dart';
import 'package:chronicle_app/src/ui/screens/weekly_wrapped_screen.dart';

void main() {
  group('WeeklyWrappedScreen Widget Tests', () {
    late TimelineEntry mockWrappedEntry;

    setUp(() {
      // Setup mock weekly wrapped data
      final payload = {
        'week_label': 'June 22 – June 28',
        'start_timestamp': 1782259200,
        'end_timestamp': 1782863999,
        'total_entries': 8,
        'voice_minutes': 3.5,
        'dominant_mood': 'chill',
        'mood_percentages': {
          'chill': 60,
          'hype': 40,
        },
        'top_keywords': ['music', 'study', '#coffee', 'morning', 'walk'],
        'peak_hour': 23,
        'streak': 5,
        'viewed': false,
      };

      mockWrappedEntry = TimelineEntry(
        entryId: 500,
        type: 'weekly_wrapped',
        content: json.encode(payload),
        mediaPath: null,
        mediaFile: null,
        createdAt: DateTime.now(),
        isHidden: false,
        tags: const [],
        mood: 'chill',
      );
    });

    testWidgets('Renders story slide 1 Cover and Aura', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WeeklyWrappedScreen(
            entry: mockWrappedEntry,
            onViewCompleted: () {},
          ),
        ),
      );

      // Verify progress indicators are shown
      expect(find.byType(WeeklyWrappedScreen), findsOneWidget);
      
      // Verify Slide 1 text contents
      expect(find.text('WEEKLY AURA'), findsOneWidget);
      expect(find.text('This week was a total'), findsOneWidget);
      expect(find.text('Chill Vibe.'), findsOneWidget);
    });

    testWidgets('Tapping right advances slides sequentially through spectrum, keywords, peak hour, and summary infographic', (WidgetTester tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: WeeklyWrappedScreen(
            entry: mockWrappedEntry,
            onViewCompleted: () {
              completed = true;
            },
          ),
        ),
      );

      final screenWidth = tester.getSize(find.byType(WeeklyWrappedScreen)).width;

      // 1. Advance to Slide 2: Mood Spectrum
      await tester.tapAt(Offset(screenWidth * 0.8, 300));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Your Mood Spectrum'), findsOneWidget);
      expect(find.text('Chill'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);

      // 2. Advance to Slide 3: Keywords
      await tester.tapAt(Offset(screenWidth * 0.8, 300));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Living Rent-Free...'), findsOneWidget);
      expect(find.text('music'), findsOneWidget);
      expect(find.text('#coffee'), findsOneWidget);

      // 3. Advance to Slide 4: Peak Hour
      await tester.tapAt(Offset(screenWidth * 0.8, 300));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Hour of Reflection'), findsOneWidget);
      expect(find.text('11:00 PM'), findsOneWidget); // peakHour = 23 -> 11:00 PM
      expect(find.text('5 Day Streak'), findsOneWidget);

      // 4. Advance to Slide 5: Summary Infographic
      await tester.tapAt(Offset(screenWidth * 0.8, 300));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('CHRONICLE WRAPPED'), findsOneWidget);
      expect(find.text('June 22 – June 28'), findsOneWidget);
      expect(find.text('Total Entries'), findsOneWidget);
      expect(find.text('Best Streak'), findsOneWidget);
      expect(find.text('Save to Gallery'), findsOneWidget);

      // 5. Tap Done button to exit
      await tester.tap(find.text('Done'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(completed, true);
    });
  });
}
