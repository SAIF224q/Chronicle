import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chronicle_app/src/ui/widgets/vinyl_player_widget.dart';

void main() {
  group('VinylPlayerWidget Tests', () {
    testWidgets('renders vinyl player details (title, artist, vinyl player)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VinylPlayerWidget(
              trackId: 'track123',
              trackTitle: 'Softcore',
              trackArtist: 'The Neighbourhood',
              trackArtworkUrl: 'https://images.unsplash.com/photo-1614613535308',
              spotifyUrl: 'https://open.spotify.com/track/123',
              audioPreviewUrl: 'https://www.soundhelix.com/song1.mp3',
              primaryColor: Colors.deepPurple,
              secondaryColor: Colors.indigo,
              onSoundtrackRemoved: () {},
            ),
          ),
        ),
      );

      // Verify song metadata renders
      expect(find.text('Softcore'), findsOneWidget);
      expect(find.text('The Neighbourhood'), findsOneWidget);

      // Verify vinyl disk container exists
      expect(find.byType(VinylPlayerWidget), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders custom solid color vinyl sticker correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VinylPlayerWidget(
              trackId: 'track456',
              trackTitle: 'My Indie Vibe',
              trackArtist: 'Self Made',
              trackArtworkUrl: 'custom_color:#FF5722', // Deep orange hex
              spotifyUrl: 'https://open.spotify.com',
              audioPreviewUrl: 'https://www.soundhelix.com/song2.mp3',
              primaryColor: Colors.orange,
              secondaryColor: Colors.black,
              onSoundtrackRemoved: () {},
            ),
          ),
        ),
      );

      // Verify metadata
      expect(find.text('My Indie Vibe'), findsOneWidget);

      // Verify music icon for manual entries
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });
  });
}
