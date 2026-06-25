# Feature Specification: Voice-to-Text Transcript Previews

## Goal
Voice journaling is highly popular among Gen Z because it is fast, low-friction, and captures raw emotional tone. However, playing audio back in public spaces, when listening to music, or when trying to quickly find a past memory can be frustrating. 

The **Voice-to-Text Transcript Previews** feature automatically transcribes recorded voice entries on-device. The transcript is displayed as a clean, expandable text preview directly beneath the audio player widget in the chat bubble. Tapping it lets the user read their spoken words instantly, copy the text, or search through the transcript using the timeline search bar, keeping the journal fully accessible and searchable without sacrificing the ease of voice recordings.

---

## User Interface (UI) Specs

### 1. Create Entry Screen
- **Processing Overlay**: While saving a voice note, a soft glassmorphic spinner overlay appears with the text `"Transcribing your voice... 🎙️"` to indicate on-device speech-to-text extraction is in progress.
- **Preview Sheet**: Alternatively, a collapsable text preview panel appears under the voice recorder widget once recording stops, allowing the user to review the transcribed text and make quick corrections before saving.

### 2. Timeline Screen
- **Transcript Toggle Button**:
  - Placed at the bottom of the `AudioPlayerWidget` inside the voice bubble.
  - Features a speech-bubble icon (e.g., `Icons.translate` or `Icons.subtitles_outlined`) and a label (e.g., `"Read Transcript"` / `"Hide Transcript"`).
  - Styled with a translucent background and text color matching the active mood theme (`hype`, `chill`, etc.).
- **Expandable Transcript Box**:
  - Appears below the player with a smooth slide-and-fade transition (`SizeTransition` and `FadeTransition`).
  - Text is formatted with an italicized, slightly translucent style (e.g., `fontStyle: FontStyle.italic`, opacity `0.85`).
  - Background is a frosted-glass bubble (`BoxDecoration` with a subtle white/black tint and border radius matching the parent message bubble).
- **Interactive Keywords & Hashtags**:
  - Any hashtags spoken and transcribed (e.g., `#hype`, `#blue`) are automatically parsed and styled as clickable tags. Tapping them triggers the timeline search/filter.

### 3. Edit Entry Screen
- When editing a voice entry, a dedicated `"Edit Transcript"` text field is provided. This allows users to manually correct any speech-to-text inaccuracies.

---

## Data Specs

### 1. Database Schema
- **Target Table**: `entry_index`
- **New Column**: `transcript TEXT`
- **Migration**:
  - Update `ChronicleSchema.databaseVersion` to `6`.
  - In `DatabaseService._upgradeDatabase`, implement migration logic:
    ```dart
    if (oldVersion < 6) {
      await database.execute(
        'ALTER TABLE ${ChronicleSchema.entryIndexTable} '
        'ADD COLUMN transcript TEXT',
      );
    }
    ```

### 2. Events & Payloads
- **Create Entry Event / Update Entry Event**:
  - The payload in the `events` table includes a `"transcript"` key when the entry contains a voice note.
  - Example Create Entry Payload:
    ```json
    {
      "content": "",
      "mood": "chill",
      "media_path": "app_data/media/audio_1719315280.m4a",
      "location_name": null,
      "transcript": "just finished watching the sunset and feeling so peaceful right now #chill"
    }
    ```

### 3. Models & Queries
- **`TimelineEntry` / `TimelineEntryRow`**:
  - Add `final String? transcript;` to the model classes.
  - Default constructor value `transcript = null`.
- **`TimelineQueryService`**:
  - Include `transcript` in the SQL `SELECT` statement in `fetchTimelineEntries`.
  - Instantiate `TimelineEntryRow` using `row['transcript'] as String?`.
- **Search System**:
  - Update search queries to look inside `transcript` as well:
    ```sql
    SELECT * FROM entry_index 
    WHERE content LIKE ? OR transcript LIKE ?
    ```

---

## UX/Flow Details

1. **Recording & Auto-Transcription**:
   - The user opens the composer, taps the microphone icon, and talks about their day: *"I am feeling so hyped about today #hype"*.
   - When they tap the save button, the application invokes the on-device transcription service (`SpeechToTextService`).
   - The transcription runs locally, outputting: *"I am feeling so hyped about today #hype"*.
2. **Database Persistence**:
   - The app serializes the entry event with `media_path` (audio file), `type: "voice"`, and `transcript: "I am feeling so hyped about today #hype"`.
   - The database projection inserts/updates the `entry_index` row with the transcript text.
   - The hashtag parser extracts `#hype` and adds a row to the `entry_tags` table automatically.
3. **Timeline Presentation**:
   - The user returns to the timeline.
   - The chat bubble renders with the audio player. A badge at the bottom of the bubble says `Read Transcript 📝`.
   - The user taps the button. The bubble expands downward to show: *"I am feeling so hyped about today #hype"*, where `#hype` is highlighted in gold and is clickable.
4. **Offline Searchability**:
   - Later, the user searches their timeline for the word *"hyped"*.
   - The local search query matches the `transcript` column, displaying the voice entry in the search results even though the main text content was empty.
