import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chronicle_app/src/ui/widgets/voice_transcript_bubble.dart';

void main() {
  testWidgets('VoiceTranscriptBubble does not render transcript button if transcript is null', (WidgetTester tester) async {
    final mockFile = File('mock_audio.m4a');
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceTranscriptBubble(
            audioFile: mockFile,
            transcript: null,
            mood: 'none',
            onTagTap: (tag) {},
          ),
        ),
      ),
    );

    expect(find.text('Read Transcript'), findsNothing);
  });

  testWidgets('VoiceTranscriptBubble renders transcript button and toggles expansion', (WidgetTester tester) async {
    final mockFile = File('mock_audio.m4a');
    String tappedTag = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VoiceTranscriptBubble(
            audioFile: mockFile,
            transcript: 'Hello guys this is a voice note #hype #vibes',
            mood: 'hype',
            onTagTap: (tag) {
              tappedTag = tag;
            },
          ),
        ),
      ),
    );

    // Verify button exists
    expect(find.text('Read Transcript'), findsOneWidget);
    expect(find.text('Hide Transcript'), findsNothing);

    // Tap Read Transcript
    await tester.tap(find.text('Read Transcript'));
    await tester.pumpAndSettle();

    expect(find.text('Hide Transcript'), findsOneWidget);
    expect(find.text('Read Transcript'), findsNothing);

    // Verify transcript is rendered
    expect(find.byType(RichText), findsWidgets);
  });
}
