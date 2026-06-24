# Feature Specification: Custom Mood Theme Selector

## Goal
Journaling is inherently emotional. For Gen Z users, standard monochrome or solid-color chat bubbles do not capture the emotional nuances of a private journal entry. The **Custom Mood Theme Selector** allows users to tag each entry with a distinct emotional vibe (e.g., Happy 🌟, Chill ☁️, Chaotic ⚡, Blue 🌧️, Stressed 🌪️, Grateful 🌸) using a playful, interactive selector. 

Once selected, the timeline (chat feed) styles the corresponding message bubble with a custom gradient background, a colored border glow, and a small emoji badge. This makes the journal highly personalized, visually rich, and provides instant emotional color-coding for their timeline.

---

## User Interface (UI) Specs

### 1. Create Entry Screen
- **Vibe Selector Strip**: A horizontal scrollable strip of capsule buttons positioned immediately above the bottom utility bar (where the save and attach buttons reside).
- **Vibe Capsules**:
  - Each capsule contains the corresponding emoji and the label (e.g. `🌟 Hype`, `☁️ Chill`, `⚡ Chaotic`, `🌧️ Blue`, `🌪️ Stressed`, `🌸 Grateful`).
  - Active/selected state: The capsule scales up slightly (1.1x) and displays a soft, glowing colored border matching the vibe.
  - Unselected state: Gray border, slightly translucent background.
- **Animations**: Tap interactions scale-up and scale-down using an `AnimatedContainer` or `ScaleTransition` for a tactile, responsive feel.

### 2. Timeline Screen
- **Mood-Specific Bubble Styling**:
  - **`hype` (🌟)**: Golden-amber gradient background (`[Colors.amber.shade300, Colors.orange.shade300]`) or a bright golden border glow in dark mode.
  - **`chill` (☁️)**: Lavender-blue gradient background (`[Colors.purple.shade100, Colors.blue.shade100]` / in dark mode: `[Colors.purple.shade800.withOpacity(0.5), Colors.blue.shade800.withOpacity(0.5)]`).
  - **`chaotic` (⚡)**: High-contrast charcoal background with a neon lime-green border glow.
  - **`blue` (🌧️)**: Deep misty blue gradient background (`[Colors.blueGrey.shade700, Colors.indigo.shade900]`).
  - **`stressed` (🌪️)**: Soft warning crimson/orange gradient background (`[Colors.red.shade900.withOpacity(0.6), Colors.orange.shade900.withOpacity(0.6)]`).
  - **`grateful` (🌸)**: Soft rose/peach gradient background (`[Colors.pink.shade100, Colors.orange.shade100]`).
  - **`none` (Default)**: Normal message bubble styling (based on system/selected global theme).
- **Mood Indicator Badge**:
  - A small, circular badge containing the active mood emoji positioned at the top-right corner of the timeline chat bubble.
  - Tapping the badge pops up a micro-tooltip showing the mood name (e.g., "Feeling Chill").

### 3. Edit Entry Screen
- Integrates the same scrollable vibe selector strip at the bottom of the editing area, allowing users to modify or clear the vibe of an existing entry.

---

## Data Specs

### 1. Database Schema
- **Target Table**: `entry_index`
- **New Column**: `mood TEXT NOT NULL DEFAULT 'none'`
- **Migration**:
  - Update `ChronicleSchema.databaseVersion` to `5`.
  - In `DatabaseService._upgradeDatabase`, implement migration logic:
    ```dart
    if (oldVersion < 5) {
      await database.execute(
        'ALTER TABLE ${ChronicleSchema.entryIndexTable} '
        'ADD COLUMN mood TEXT NOT NULL DEFAULT \'none\'',
      );
    }
    ```

### 2. Events & Payloads
- **Create Entry Event / Update Entry Event**:
  - The payload in the `events` table must include a `"mood"` key.
  - Example Create Entry Payload:
    ```json
    {
      "content": "Had an amazing workout today!",
      "mood": "hype",
      "media_path": null,
      "location_name": null
    }
    ```

### 3. Models & Queries
- **`TimelineEntry` / `TimelineEntryRow`**:
  - Add `final String mood;` to the classes.
  - Default constructor value `mood = 'none'`.
- **`TimelineQueryService`**:
  - Include `mood` in the SQL `SELECT` statement in `fetchTimelineEntries`.
  - Instantiate `TimelineEntryRow` using `row['mood'] as String? ?? 'none'`.

---

## UX/Flow Details

1. **Vibe Input**:
   - The user opens the composer to write an entry.
   - Before writing, or after, they tap the `⚡ Chaotic` capsule in the vibe bar.
   - The capsule animates to show selection.
2. **Persistence**:
   - The user clicks the save button.
   - The app serializes the entry event with `mood: "chaotic"`.
   - The event database service stores the event, and the projector service updates the `entry_index` table.
3. **Timeline Render**:
   - The timeline page reloads.
   - The query service fetches the new row, reading `mood: 'chaotic'`.
   - The timeline builder maps `mood` to its specific gradient styling and renders the chat bubble with a neon lime-green outline, with a small `⚡` badge.
4. **Correction/Edit**:
   - The user decides they feel more `☁️ Chill` now.
   - They tap "Edit" on the entry, change the selector to `☁️ Chill`, and tap "Save".
   - The background instantly transitions to a soft lavender gradient.
