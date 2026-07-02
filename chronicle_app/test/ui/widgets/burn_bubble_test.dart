import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle_app/src/application/services/timeline_service.dart';
import 'package:chronicle_app/src/ui/widgets/burn_bubble_wrapper.dart';

void main() {
  group('BurnBubbleWrapper Widget Tests', () {
    late TimelineEntry mockVentEntry;
    late TimelineEntry mockSessionVentEntry;

    setUp(() {
      mockVentEntry = TimelineEntry(
        entryId: 10,
        type: 'text',
        content: 'Raw venting emotions...',
        mediaPath: null,
        mediaFile: null,
        createdAt: DateTime.now(),
        isHidden: false,
        tags: const [],
        mood: 'angry',
        isVent: true,
        burnAt: DateTime.now().millisecondsSinceEpoch + 5 * 60 * 1000, // 5 mins in future
      );

      mockSessionVentEntry = TimelineEntry(
        entryId: 11,
        type: 'text',
        content: 'Fleeting stress session...',
        mediaPath: null,
        mediaFile: null,
        createdAt: DateTime.now(),
        isHidden: false,
        tags: const [],
        mood: 'stressed',
        isVent: true,
        burnAt: null, // On Exit
      );
    });

    testWidgets('renders burn bubble with timer and ember background', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BurnBubbleWrapper(
              entry: mockVentEntry,
              onCombustionComplete: () {},
              child: Text(mockVentEntry.content),
            ),
          ),
        ),
      );

      // Verify content is rendered
      expect(find.text('Raw venting emotions...'), findsOneWidget);

      // Verify timer icon and timer text is present
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Text && (w.data?.startsWith('04:') == true || w.data?.startsWith('05:') == true)),
        findsOneWidget,
      );
    });

    testWidgets('renders session only vent bubble correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BurnBubbleWrapper(
              entry: mockSessionVentEntry,
              onCombustionComplete: () {},
              child: Text(mockSessionVentEntry.content),
            ),
          ),
        ),
      );

      // Verify content is rendered
      expect(find.text('Fleeting stress session...'), findsOneWidget);

      // Verify air icon and "Session only" text
      expect(find.byIcon(Icons.air), findsOneWidget);
      expect(find.text('Session only'), findsOneWidget);
    });

    testWidgets('combusts when countdown timer expires', (WidgetTester tester) async {
      bool completed = false;

      // Create a vent that expires in 1 second
      final fastVent = TimelineEntry(
        entryId: 12,
        type: 'text',
        content: 'Almost burnt note',
        mediaPath: null,
        mediaFile: null,
        createdAt: DateTime.now(),
        isHidden: false,
        tags: const [],
        mood: 'stressed',
        isVent: true,
        burnAt: DateTime.now().millisecondsSinceEpoch + 1000, // 1s
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BurnBubbleWrapper(
              entry: fastVent,
              onCombustionComplete: () {
                completed = true;
              },
              child: Text(fastVent.content),
            ),
          ),
        ),
      );

      expect(completed, false);

      // Pump 1 second to trigger countdown tick and combustion start
      await tester.pump(const Duration(seconds: 1));
      // Pump to let the 1200ms animation finish
      await tester.pumpAndSettle();

      expect(completed, true);
    });
  });
}
