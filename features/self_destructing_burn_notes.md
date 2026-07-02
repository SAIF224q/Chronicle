# Feature Specification: Self-Destructing Burn Notes

## Goal
Gen Z users frequently experience fleeting, intense emotions, anxiety spikes, or raw impulses that they need to "vent" immediately. However, they are often hesitant to write these unfiltered thoughts in a permanent journal for two main reasons:
1. **Privacy Concerns**: They worry that someone might unlock their phone and read their most vulnerable, raw notes.
2. **Timeline Clutter**: They do not want temporary negative mood spirals or venting sessions to permanently occupy their reflective journal feed.

The **Self-Destructing Burn Notes** feature solves this by introducing an ephemeral "Vent Mode" to Chronicle. When active, entries are styled as glowing coal-ash bubbles with a ticking countdown. Once the timer expires (e.g., after 5 minutes, 1 hour, or upon exiting the app session), the entry disintegrates with a visually striking ash-dissolve particle animation, and its content is completely purged from the local SQLite database. This provides a safe, cathartic release without leaving any digital footprint.

---

## User Interface (UI) Specs

### 1. Chat Composer Vent Mode Toggle
- **Toggle Button**: A small flame/fire icon (`Icons.local_fire_department` or `Icons.whatshot`) sits on the far-left of the text entry composer, adjacent to the attachment button.
- **Visual Feedback**:
  - **Inactive state**: A sleek, outline-style gray icon.
  - **Active state**: The flame fills with a neon orange/crimson gradient and gains a soft glow (`BoxShadow`). A brief, light haptic feedback buzz is triggered.
- **Vibe Mode Overlay**: When Vent Mode is enabled, the border of the text input composer transitions into a slowly pulsating deep-red gradient. The placeholder text changes from "Send a message..." to "Spill the tea / Vent it out... 🌋 (Ephemeral)".

### 2. Combustion Timer Quick-Selector Bar
- Upon activating Vent Mode, a horizontal pill-shaped selector bar slides up directly above the text composer.
- It displays quick-select timer options:
  - `5 mins` (Default choice, suited for quick emotional discharge)
  - `1 hour` (For processing short-term stress)
  - `24 hours` (To let a vent sit overnight)
  - `On Exit` (Burns as soon as the user closes the app or navigates away from the timeline screen)
- Tapping a timer option scales it up slightly (1.05x) and changes its background to a glowing dark-amber.

### 3. Timeline Burn Bubbles
- **Bubble Design**:
  - Vent bubbles feature a custom dark charcoal background gradient (`[Colors.grey.shade900, Colors.red.shade950]`).
  - The bubble has a thin, glowing crimson or amber border (`BoxShadow` with a blur radius of `8.0`).
  - Floating Embers: A lightweight particle animation (`CustomPainter`) renders subtle, soft orange embers drifting slowly upward within the bubble background.
- **Countdown Widget**:
  - A tiny timer icon (`Icons.timer`) and countdown clock (e.g., `04:59` remaining) are displayed in the bottom-right corner of the bubble, next to the timestamp.
  - If "On Exit" is selected, it displays a small wind/cloud emoji `💨` and the text `"Session only"`.
- **Manual Combustion Button**:
  - Long-pressing a burn note pops up a context menu with a "Combust Now 🔥" option to let users destroy the note instantly if they feel immediate relief.

### 4. Destruction Animation (The "Burn" Effect)
- When the countdown reaches `00:00` (or "Combust Now" is pressed), the text bubble's contents fade out first.
- The bubble container cracks with glowing red lines (using a custom shader or overlay mask).
- The container then dissolves into rising ash/smoke particles (`Opacity` transition coupled with a scale-down effect) and disappears from the chat list.

---

## Data Specs

### 1. Database Schema
- **Target Table**: `entry_index`
- **New Columns**:
  - `is_vent INTEGER NOT NULL DEFAULT 0 CHECK (is_vent IN (0, 1))` (flag indicating if it's a self-destructing note)
  - `burn_at INTEGER` (Unix epoch timestamp in milliseconds when the entry should be deleted, or `NULL` for "On Exit" entries)
- **Migration**:
  - Update `ChronicleSchema.databaseVersion` to `8`.
  - In `DatabaseService._upgradeDatabase`, implement migration logic:
    ```dart
    if (oldVersion < 8) {
      await database.execute(
        'ALTER TABLE ${ChronicleSchema.entryIndexTable} '
        'ADD COLUMN is_vent INTEGER NOT NULL DEFAULT 0 CHECK (is_vent IN (0, 1))',
      );
      await database.execute(
        'ALTER TABLE ${ChronicleSchema.entryIndexTable} '
        'ADD COLUMN burn_at INTEGER',
      );
    }
    ```

### 2. Data Purge Services
- **Automatic Background Purge**:
  - On app launch, and then periodically (every 60 seconds) during active sessions, a background query runs to permanently delete expired entries and their corresponding event logs:
    ```dart
    Future<void> purgeExpiredVents(Database db) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.transaction((txn) async {
        // 1. Find all entry IDs that need to be deleted
        final List<Map<String, Object?>> expired = await txn.rawQuery(
          'SELECT entry_id FROM ${ChronicleSchema.entryIndexTable} '
          'WHERE is_vent = 1 AND burn_at IS NOT NULL AND burn_at <= ?',
          [now],
        );
        
        if (expired.isEmpty) return;
        final expiredIds = expired.map((row) => row['entry_id'] as int).toList();
        
        // 2. Delete from entry_index, events, and entry_tags
        final idsPlaceholder = expiredIds.map((_) => '?').join(',');
        await txn.execute(
          'DELETE FROM ${ChronicleSchema.entryIndexTable} '
          'WHERE entry_id IN ($idsPlaceholder)',
          expiredIds,
        );
        await txn.execute(
          'DELETE FROM ${ChronicleSchema.eventsTable} '
          'WHERE entry_id IN ($idsPlaceholder)',
          expiredIds,
        );
        await txn.execute(
          'DELETE FROM ${ChronicleSchema.entryTagsTable} '
          'WHERE entry_id IN ($idsPlaceholder)',
          expiredIds,
        );
      });
    }
    ```
- **Session Exit Purge**:
  - On app shutdown, backgrounding, or when the user navigates away from the main chat feed, entries with `is_vent = 1` and `burn_at IS NULL` ("On Exit") are purged:
    ```dart
    Future<void> purgeSessionVents(Database db) async {
      await db.transaction((txn) async {
        final List<Map<String, Object?>> sessionVents = await txn.rawQuery(
          'SELECT entry_id FROM ${ChronicleSchema.entryIndexTable} '
          'WHERE is_vent = 1 AND burn_at IS NULL',
        );
        
        if (sessionVents.isEmpty) return;
        final ventIds = sessionVents.map((row) => row['entry_id'] as int).toList();
        final idsPlaceholder = ventIds.map((_) => '?').join(',');
        
        await txn.execute('DELETE FROM ${ChronicleSchema.entryIndexTable} WHERE entry_id IN ($idsPlaceholder)', ventIds);
        await txn.execute('DELETE FROM ${ChronicleSchema.eventsTable} WHERE entry_id IN ($idsPlaceholder)', ventIds);
        await txn.execute('DELETE FROM ${ChronicleSchema.entryTagsTable} WHERE entry_id IN ($idsPlaceholder)', ventIds);
      });
    }
    ```

### 3. Models & Payload
- **`TimelineEntry`**:
  - Add fields: `final bool isVent;` and `final int? burnAt;`
- **Events Serialization**:
  - Vent metadata is included in the event payload:
    ```json
    {
      "content": "Just venting out some frustration...",
      "is_vent": 1,
      "burn_at": 1783000000000
    }
    ```

---

## UX/Flow Details

1. **Activation**:
   - The user opens their private journal feed feeling stressed. They tap the `whatshot` (flame) icon in the chat composer.
   - The composer borders transition to a glowing deep red/orange, and the input field placeholder shifts to "Spill the tea / Vent it out... 🌋 (Ephemeral)".
   - The timer selection bar appears, defaulting to `5 mins`. The user selects `5 mins` or changes it to `1 hour` or `On Exit`.
2. **Writing & Posting**:
   - The user types: *"Work is so exhausting today, I feel like quitting..."* and hits Send.
   - A new event is written to the database with `is_vent = 1` and `burn_at = currentTime + 5 minutes`.
   - The message bubble is rendered in the feed with a dark charcoal background, a pulsating crimson outline, and a countdown timer showing `05:00` ticking down.
3. **The Countdown & Action**:
   - The user watches the countdown tick. If they wish, they can tap the countdown to change the expiration time or tap "Combust Now" to delete it instantly.
4. **Combustion**:
   - When the timer reaches `00:00`, the bubble is marked as expired.
   - The UI plays a cracking-red visual effect followed by an ash-dissolve fade-out animation.
   - The database service deletes the entry and all its events, freeing up space and ensuring absolute privacy.
5. **App Exit**:
   - If the user had posted a vent with the "On Exit" duration, that entry is completely deleted from the database as soon as the app process is closed or backgrounded.
