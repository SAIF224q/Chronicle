import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MockTrack {
  const MockTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.spotifyUrl,
    required this.audioPreviewUrl,
    required this.vibe,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final String spotifyUrl;
  final String audioPreviewUrl;
  final String vibe;
  final Color primaryColor;
  final Color secondaryColor;
}

final List<MockTrack> mockTracks = [
  const MockTrack(
    id: 'track1',
    title: 'Softcore',
    artist: 'The Neighbourhood',
    artworkUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=200&auto=format&fit=crop',
    spotifyUrl: 'https://open.spotify.com/track/75JFxk2mR6bxUHIxTEUi5C',
    audioPreviewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    vibe: 'Sad Boy Hours',
    primaryColor: Color(0xFF352235),
    secondaryColor: Color(0xFF1A2238),
  ),
  const MockTrack(
    id: 'track2',
    title: 'Lo-Fi Chill Study Beats',
    artist: 'Lofi Girl',
    artworkUrl: 'https://images.unsplash.com/photo-1518173946687-a4c8a383392e?q=80&w=200&auto=format&fit=crop',
    spotifyUrl: 'https://open.spotify.com/playlist/37i9dQZF1DWWQRwui0EXPn',
    audioPreviewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    vibe: 'Chill Lo-Fi',
    primaryColor: Color(0xFF1E352F),
    secondaryColor: Color(0xFF38291F),
  ),
  const MockTrack(
    id: 'track3',
    title: 'Metamorphosis',
    artist: 'Interworld',
    artworkUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=200&auto=format&fit=crop',
    spotifyUrl: 'https://open.spotify.com/track/2ksOAxtIkCH9qi5ndm18Xi',
    audioPreviewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    vibe: 'Hype Phonk',
    primaryColor: Color(0xFF2C163F),
    secondaryColor: Color(0xFF0D0A1C),
  ),
  const MockTrack(
    id: 'track4',
    title: 'Late Night Drive',
    artist: 'Kavinsky',
    artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=200&auto=format&fit=crop',
    spotifyUrl: 'https://open.spotify.com/track/0U01R45b8o7n82U2a8N74R',
    audioPreviewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    vibe: 'Late Night Drive',
    primaryColor: Color(0xFF1C2C42),
    secondaryColor: Color(0xFF3A1C28),
  ),
  const MockTrack(
    id: 'track5',
    title: 'Focus Ambient Echoes',
    artist: 'Brian Eno',
    artworkUrl: 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?q=80&w=200&auto=format&fit=crop',
    spotifyUrl: 'https://open.spotify.com/track/4pi6Gk9L9N7k5b1A55o6uY',
    audioPreviewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    vibe: 'Focus Ambient',
    primaryColor: Color(0xFF102A43),
    secondaryColor: Color(0xFF486581),
  ),
  const MockTrack(
    id: 'track6',
    title: 'Sweater Weather',
    artist: 'The Neighbourhood',
    artworkUrl: 'https://images.unsplash.com/photo-1475924156734-496f6cac6ec1?q=80&w=200&auto=format&fit=crop',
    spotifyUrl: 'https://open.spotify.com/track/2TpxZ7JUBn3uw4666756Zg',
    audioPreviewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    vibe: 'Sad Boy Hours',
    primaryColor: Color(0xFF463A39),
    secondaryColor: Color(0xFF22313F),
  ),
  const MockTrack(
    id: 'track7',
    title: 'Rainy Night In Tokyo',
    artist: 'Lofi Dreams',
    artworkUrl: 'https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?q=80&w=200&auto=format&fit=crop',
    spotifyUrl: 'https://open.spotify.com/track/3t9uW8p5o7N0A2k5gUf6vX',
    audioPreviewUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    vibe: 'Chill Lo-Fi',
    primaryColor: Color(0xFF1A1F2C),
    secondaryColor: Color(0xFF2C253B),
  ),
];

class MusicSearchBottomSheet extends StatefulWidget {
  const MusicSearchBottomSheet({super.key});

  @override
  State<MusicSearchBottomSheet> createState() => _MusicSearchBottomSheetState();
}

class _MusicSearchBottomSheetState extends State<MusicSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  String _selectedVibe = '';
  String _searchQuery = '';
  String? _currentlyPlayingTrackId;
  bool _isPlaying = false;

  // Manual Entry Fields
  bool _showManualEntry = false;
  final TextEditingController _manualTitleController = TextEditingController();
  final TextEditingController _manualArtistController = TextEditingController();
  Color _selectedStickerColor = Colors.teal;

  final List<Color> _stickerColors = [
    Colors.teal,
    Colors.deepOrange,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.amber,
    Colors.lightGreen,
    Colors.redAccent,
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingTrackId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualTitleController.dispose();
    _manualArtistController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(MockTrack track) async {
    try {
      if (_currentlyPlayingTrackId == track.id) {
        if (_isPlaying) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.resume();
        }
      } else {
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingTrackId = track.id;
          _isPlaying = false;
        });
        await _audioPlayer.setSource(UrlSource(track.audioPreviewUrl));
        await _audioPlayer.resume();
      }
    } catch (_) {
      // Handle player load errors
    }
  }

  List<MockTrack> _filteredTracks() {
    return mockTracks.where((track) {
      final matchesVibe = _selectedVibe.isEmpty || track.vibe == _selectedVibe;
      final matchesSearch = _searchQuery.isEmpty ||
          track.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          track.artist.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesVibe && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTracks();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: Colors.black.withOpacity(0.85),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade800.withOpacity(0.3)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search vibe soundtracks... 🔍',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty || _selectedVibe.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _selectedVibe = '';
                            });
                          },
                          child: const Text('Clear', style: TextStyle(color: Colors.grey)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Vibe Presets Strip
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _vibePreset('✨ Chill Lo-Fi', 'Chill Lo-Fi'),
                      _vibePreset('❤️ Sad Boy Hours', 'Sad Boy Hours'),
                      _vibePreset('⚡ Hype Phonk', 'Hype Phonk'),
                      _vibePreset('🌌 Late Night Drive', 'Late Night Drive'),
                      _vibePreset('🍀 Focus Ambient', 'Focus Ambient'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!_showManualEntry) ...[
                  // Tracks List
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No tracks found. Enter manually below!',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemBuilder: (context, index) {
                              final track = filtered[index];
                              final isCurrent = _currentlyPlayingTrackId == track.id;
                              final isPlayingThis = isCurrent && _isPlaying;

                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    track.artworkUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, o, s) => Container(
                                      color: Colors.grey.shade800,
                                      width: 44,
                                      height: 44,
                                      child: const Icon(Icons.music_note, color: Colors.white),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  track.title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  track.artist,
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isPlayingThis ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                        color: isPlayingThis ? Colors.tealAccent : Colors.grey.shade300,
                                        size: 28,
                                      ),
                                      onPressed: () => _togglePreview(track),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle, color: Colors.tealAccent, size: 28),
                                      onPressed: () {
                                        Navigator.pop(context, {
                                          'track_id': track.id,
                                          'track_title': track.title,
                                          'track_artist': track.artist,
                                          'track_artwork_url': track.artworkUrl,
                                          'spotify_url': track.spotifyUrl,
                                          'audio_preview_url': track.audioPreviewUrl,
                                          'primary_color': track.primaryColor,
                                          'secondary_color': track.secondaryColor,
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ] else ...[
                  // Manual entry form
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manual Track Entry',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        _manualTextField(_manualTitleController, 'Song Title (e.g. Sweater Weather)'),
                        const SizedBox(height: 8),
                        _manualTextField(_manualArtistController, 'Artist / Band (e.g. The Neighbourhood)'),
                        const SizedBox(height: 12),
                        const Text(
                          'Vinyl Center Color Sticker',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _stickerColors.length,
                            itemBuilder: (c, idx) {
                              final color = _stickerColors[idx];
                              final isSelected = _selectedStickerColor == color;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedStickerColor = color;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showManualEntry = false;
                                  });
                                },
                                child: const Text('Back to search', style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.tealAccent,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  final title = _manualTitleController.text.trim();
                                  final artist = _manualArtistController.text.trim();
                                  if (title.isEmpty) return;

                                  // Convert selected sticker color to hex code
                                  final hexColor = '#${_selectedStickerColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';

                                  Navigator.pop(context, {
                                    'track_id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
                                    'track_title': title,
                                    'track_artist': artist.isEmpty ? 'Unknown Artist' : artist,
                                    'track_artwork_url': 'custom_color:$hexColor',
                                    'spotify_url': 'https://open.spotify.com',
                                    'audio_preview_url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', // default preview
                                    'primary_color': _selectedStickerColor.withOpacity(0.8),
                                    'secondary_color': const Color(0xFF0E0E15),
                                  });
                                },
                                child: const Text('Attach', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(color: Colors.grey, height: 24),
                if (!_showManualEntry)
                  ListTile(
                    onTap: () {
                      setState(() {
                        _showManualEntry = true;
                      });
                    },
                    leading: const Icon(Icons.settings, color: Colors.grey),
                    title: const Text(
                      "Can't find your song? Enter manually ⚙️",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _vibePreset(String label, String vibe) {
    final isSelected = _selectedVibe == vibe;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVibe = isSelected ? '' : vibe;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.tealAccent.withOpacity(0.2) : Colors.grey.shade900.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.tealAccent : Colors.grey.shade800,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.tealAccent : Colors.grey.shade300,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _manualTextField(TextEditingController controller, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}
