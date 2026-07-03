# Feature Specification: Aesthetic Soundtrack Attachment & Spinning Vinyl Player

## Goal
Music is the ultimate translator of Gen Z's emotions, memories, and personal aesthetics. Traditional text journals lack the sensory richness that music brings to a moment. By introducing the **Aesthetic Soundtrack Attachment & Spinning Vinyl Player** feature, users can pin a "Song of the Day" or a mood-matching track to any chat journal entry. 

This feature turns entries into multi-sensory experiences:
- It displays an interactive, spinning vinyl record player widget within the chat bubble.
- The chat bubble's visual theme dynamically adjusts its gradient colors to match the song's album art palette.
- Tapping the vinyl plays a 30-second audio preview, bridging sound and memory in a highly stylized local-first interface.

---

## User Interface (UI) Specs

### 1. Chat Composer Integration
- **Soundtrack Button**: A circular button with a spinning disc or music note icon (`Icons.music_note` or `Icons.album_outlined`) placed in the bottom entry composer utility bar (next to media attachments).
- **Music Active Badge**: When a song is selected, the composer displays a small glowing capsule badge at the top of the input field: `🎵 "Softcore" - The Neighbourhood (Cancel [x])`.

### 2. Aesthetic Music Search Bottom Sheet (`MusicSearchBottomSheet`)
Tapping the Soundtrack button opens a bottom sheet with a modern dark glassmorphism design:
- **Search Input**: A sleek dark search bar with a glowing search icon: `Search Spotify tracks... 🔍`
- **Vibe Presets Strip**: Horizontal scrollable list of glowing vibe capsule buttons:
  - `✨ Chill Lo-Fi`
  - `❤️ Sad Boy Hours`
  - `⚡ Hype Phonk`
  - `🌌 Late Night Drive`
  - `🍀 Focus Ambient`
- **Results List**: List of matching songs containing:
  - Mini album art thumbnail with rounded corners (`6px`).
  - Song Title in bold, Artist Name in a lighter grey.
  - A small play icon to preview, and a '+' icon to attach.
- **Manual Entry Option**: A fallback row for offline/custom tracks: `"Can't find your song? Enter manually ⚙️"`. Tapping this opens fields for `Title`, `Artist`, and a color wheel to customize the vinyl center sticker.

### 3. Timeline (Chat Feed) Entry Widget
When a journal entry has a soundtrack attached, the chat bubble is rendered with premium visual effects:

#### A. Dynamic Theme Skin (Album Art Palette Extraction)
- The app extracts colors from the album cover image (using `palette_generator`).
- The chat bubble background morphs from a standard solid color to a smooth, slow-moving diagonal gradient using the primary and secondary colors of the album art (e.g., deep maroon and muted indigo for a moody theme).
- The text color automatically shifts to either high-contrast white or deep obsidian depending on the luminance of the gradient to maintain perfect readability.

#### B. The Vinyl Record Player Widget (`VinylPlayerWidget`)
An interactive player sits embedded inside the chat bubble (aligned left for incoming-style bubbles):
- **Vinyl Disk**: A realistic black vinyl record icon with grooves, centered with a circular sticker of the album artwork.
- **Stylus Needle Arm**: A custom-drawn metallic player arm. When paused, the arm sits off the record. When playing, the arm smoothly swivels (`RotationTransition`) onto the edge of the record.
- **Spinning Animation**: While playing, the vinyl record rotates continuously at `33 RPM` (`RotationTransition` looping every `1.8 seconds`).
- **Progress Glow Ring**: A thin, glowing circular ring wraps around the edge of the vinyl, filling up clockwise to indicate track progress.
- **Vibe Waves**: A micro-particle animation of tiny music notes or floating stars gently rises from the vinyl player while audio is active.

---

## Data Specs

### 1. Database Schema
- **Target Table**: `entry_index`
- **New Columns**:
  - `track_id TEXT` (The unique Spotify/music service ID)
  - `track_title TEXT` (Title of the song)
  - `track_artist TEXT` (Name of the artist/band)
  - `track_artwork_url TEXT` (URL to the album cover image)
  - `spotify_url TEXT` (Web link to open the track in Spotify)
  - `audio_preview_url TEXT` (URL to the 30-second mp3 audio preview)
- **Migration**:
  - Update `ChronicleSchema.databaseVersion` to `9`.
  - In `DatabaseService._upgradeDatabase`, implement migration:
    ```dart
    if (oldVersion < 9) {
      await database.execute(
        'ALTER TABLE ${ChronicleSchema.entryIndexTable} '
        'ADD COLUMN track_id TEXT',
      );
      await database.execute(
        'ALTER TABLE ${ChronicleSchema.entryIndexTable} '
        'ADD COLUMN track_title TEXT',
      );
      await database.execute(
        'ALTER TABLE ${ChronicleSchema.entryIndexTable} '
        'ADD COLUMN track_artist TEXT',
      );
      await database.execute(
        'ALTER TABLE ${ChronicleSchema.entryIndexTable} '
        'ADD COLUMN track_artwork_url TEXT',
      );
      await database.execute(
        'ALTER TABLE ${ChronicleSchema.entryIndexTable} '
        'ADD COLUMN spotify_url TEXT',
      );
      await database.execute(
        'ALTER TABLE ${ChronicleSchema.entryIndexTable} '
        'ADD COLUMN audio_preview_url TEXT',
      );
    }
    ```

### 2. Events & Payloads
- **Event Types**: Included inside the payload of standard `create_entry` or `update_entry` events.
- **Payload Schema**:
  - Add the `track_*` parameters as optional values under the entry payload.
  - Example payload:
    ```json
    {
      "content": "Walking in the rain today. This song hits different. 🌧️",
      "mood": "nostalgic",
      "media_path": null,
      "location_name": "Seattle, WA",
      "track_id": "75JFxk2mR6bxUHIxTEUi5C",
      "track_title": "Sweater Weather",
      "track_artist": "The Neighbourhood",
      "track_artwork_url": "https://i.scdn.co/image/ab67616d0000b27382b601dd8926915151590",
      "spotify_url": "https://open.spotify.com/track/75JFxk2mR6bxUHIxTEUi5C",
      "audio_preview_url": "https://p.scdn.co/mp3-preview/a912bbbc..."
    }
    ```

### 3. Models & Queries
- **`TimelineEntry` / `TimelineEntryRow`**:
  - Add fields:
    ```dart
    final String? trackId;
    final String? trackTitle;
    final String? trackArtist;
    final String? trackArtworkUrl;
    final String? spotifyUrl;
    final String? audioPreviewUrl;
    ```
  - Add helper properties:
    ```dart
    bool get hasSoundtrack => trackTitle != null && trackTitle!.isNotEmpty;
    ```
- **`TimelineQueryService`**:
  - Update mapping in select/insert queries to include the new track fields.
  - Ensure local search ignores music URLs/IDs but includes `track_title` and `track_artist` so users can search their timeline by song title or artist name (e.g. searching "Neighbourhood" returns all entries marked with their tracks).

---

## UX/Flow Details

### 1. Attaching a Song
1. The user opens the chat keyboard and taps the `🎵` (Soundtrack) icon in the toolbar.
2. The `MusicSearchBottomSheet` slides up smoothly.
3. The user either taps a vibe shortcut (e.g. `Sad Boy Hours ❤️`) or types `"Sweater Weather"` into the search bar.
4. The search triggers an asynchronous search against the local/mock cache or Spotify API.
5. In the results list, the user can press the play icon to hear a brief 30s preview.
6. The user taps the `+` button on `"Sweater Weather"`.
7. The bottom sheet slides down, and the input field now displays a glowing music tag: `🎵 "Sweater Weather" - The Neighbourhood`.

### 2. Viewing the Timeline Bubble
1. The user taps "Send". The entry is inserted into the local SQLite database.
2. The new message card renders in the timeline chat feed.
3. The card shows a diagonal gradient of muted purple and blue, extracted from the cover art of "Sweater Weather".
4. On the left side of the text, a rotating vinyl record displays the album cover sticker in its center.
5. The player stylus needle is rotated off the vinyl in a static, ready state.

### 3. Playing/Interacting with the Vinyl Player
1. The user taps the vinyl player widget inside the chat bubble.
2. The stylus needle arm swivels onto the vinyl record.
3. The vinyl begins rotating.
4. The audio player plays the 30-second preview track.
5. A circular glowing ring around the vinyl advances.
6. The user taps it again to pause; the needle arm lifts off, and the vinyl stops spinning.
7. Long-pressing the vinyl displays a menu:
   - `Open on Spotify 🚀` (Launches the Spotify URL in the browser or native app)
   - `Remove Soundtrack 🗑️` (Edits the entry and deletes the music columns)
