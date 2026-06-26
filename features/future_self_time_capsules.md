# Feature Specification: Future Self Time Capsules

## Goal
Journaling is not just about recording the past; it is also about communicating with your future self. Gen Z users love features centered on self-reflection, manifestation, and personal growth milestones. The **Future Self Time Capsules** feature allows users to write messages, record voice notes, or upload media that are scheduled to unlock only on a specific future date. 

By creating anticipation and a sense of reflection, it turns the private chat feed into a time-traveling conversation with oneself.

---

## User Interface (UI) Specs

### 1. Chat Composer Integration
- **Time Capsule Button**: A circular button with an hourglass or lock icon (`Icons.hourglass_empty` or `Icons.lock`) placed in the bottom entry composer utility bar (next to media attachments).
- **Time Capsule Active Badge**: When a capsule release date is set, the composer displays a small glowing badge at the top of the input field: `⏳ Sealed until 2026-07-26 (Cancel [x])`.

### 2. Time Capsule Picker Bottom Sheet
Tapping the Time Capsule button opens a bottom sheet with a modern dark glassmorphism design:
- **Header**: `Seal a Time Capsule ⏳`
- **Presets Strip**: Horizontal scrollable list of glowing capsule-style buttons:
  - `1 Week ⏳`
  - `1 Month 🗓️`
  - `6 Months 🚀`
  - `1 Year 🎂`
  - `Custom Date ⚙️`
- **Custom Date Picker**: If "Custom Date" is tapped, a smooth scroll wheel or calendar widget is displayed.
- **Vibe Warning Footer**: A soft warning message: *"Once sealed, you won't be able to read or edit this entry until the unlock date. Choose wisely!"*
- **Action Button**: A high-fidelity primary action button: `Seal Capsule & Close`.

### 3. Timeline (Chat Feed) States

#### A. Locked State (Current Time < `unlock_at`)
- **Visuals**:
  - A frosted-glass backdrop overlay (`BackdropFilter` with blur effect) applied over the message content.
  - A dashed neon purple/lavender border outline around the message bubble.
  - A central icon of a padlocked safe or floating key (`Icons.lock_outline` or `Icons.vpn_key_outlined`).
- **Text Labels**:
  - Header: `🔒 Sealed Time Capsule`
  - Subtitle: `Unlocks on July 26, 2026 (in 30 days)`
- **Interaction**:
  - Tapping or double-tapping the locked bubble plays a playful "shake" physics animation (e.g., rotating +/- 3 degrees rapidly for 300ms) with a gentle haptic buzz.
  - Shows a micro-snack/tooltip: *"No peeking! Patience is a vibe 🤫"*
  - The actual message content, audio player, or images are completely hidden from the widget tree to prevent accidental exposure.

#### B. Unlocked State (Current Time >= `unlock_at`)
- **Visuals**:
  - The bubble automatically switches to the unlocked state.
  - Uses a special shimmering premium gradient background (e.g., `[Colors.violet, Colors.deepPurple, Colors.pinkAccent]`) to represent an "unwrapped gift".
  - Displays a tiny confetti or glowing particle effect around the bubble when first scrolled into view.
- **Text Labels**:
  - Header: `🔓 Unlocked Time Capsule`
  - Subtitle: `Sent June 26, 2026 (1 month ago)`
- **Interaction**:
  - Displays the fully revealed text, audio player, or images.
  - Standard editing or deleting of the message is enabled.

---

## Data Specs

### 1. Database Schema
- **Target Table**: `entry_index`
- **New Column**: `unlock_at INTEGER` (Timestamp in milliseconds since epoch. Null or 0 means immediately available).
- **Migration**:
  - Update `ChronicleSchema.databaseVersion` to `7`.
  - In `DatabaseService._upgradeDatabase`, implement migration:
    ```dart
    if (oldVersion < 7) {
      await database.execute(
        'ALTER TABLE ${ChronicleSchema.entryIndexTable} '
        'ADD COLUMN unlock_at INTEGER',
      );
    }
    ```

### 2. Events & Payloads
- **Event Types**: Fits within existing `create_entry` or `update_entry` events.
- **Payload Schema**:
  - Add `"unlock_at"` to the JSON payload.
  - Example payload:
    ```json
    {
      "content": "Hey future self, did you finally finish that project you were stressed about? 🚀",
      "mood": "none",
      "media_path": null,
      "location_name": "San Francisco, CA",
      "unlock_at": 1782398400000
    }
    ```

### 3. Models & Queries
- **`TimelineEntry` / `TimelineEntryRow`**:
  - Add `final int? unlockAt;` to both classes.
  - Expose helper properties:
    ```dart
    bool get isLocked => unlockAt != null && unlockAt! > DateTime.now().millisecondsSinceEpoch;
    ```
- **`TimelineQueryService`**:
  - Update select statements to retrieve `unlock_at`.
  - Ensure full-text search query excludes or masks contents of entries where `unlock_at > current_time` to prevent users from searching and seeing preview text of locked capsules.

---

## UX/Flow Details

1. **Creating the Capsule**:
   - The user opens the chat feed and taps the text entry box.
   - They write a message reflecting on their current state and aspirations.
   - Tapping the `⏳` (Hourglass) icon next to the send button opens the bottom sheet.
   - The user selects `1 Year 🎂` as the duration. The screen shows `Sealing until June 26, 2027`.
   - The user taps the Send button.

2. **The Sealed Period**:
   - The message bubble is appended to the bottom of the chat timeline immediately.
   - The bubble is styled as a locked violet card with a dashed border.
   - If the user taps the card, it wiggles playfully and shows a countdown.
   - If the user types a search query matching words in the locked capsule, the search does not reveal the entry content.

3. **The Unlocking Moment**:
   - On June 26, 2027, the user opens the application.
   - The app detects that the system time has passed `unlock_at`.
   - In the feed, the card updates: the lock icon changes to an open padlock, and the card's background turns into a shimmering gradient.
   - When the user scrolls to the message, a light confetti animation plays, and they can finally read their past self's message.
