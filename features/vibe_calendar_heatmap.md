# Feature Specification: Vibe Calendar Heatmap

## Goal
Journaling is not just about writing; it is also about visualizing patterns in our mental health and celebrating consistency. Traditional journaling apps use sterile graphs or high-pressure "streaks" that can make users feel guilty or stressed for missing a day. 

The **Vibe Calendar Heatmap** (also known as the "Vibe Grid") is a visually stunning, low-pressure mood tracker designed for Gen Z. It aggregates the user's daily journal entries and colors each calendar tile with the dominant emotional vibe of that day (e.g. Happy 🌟, Chill ☁️, Chaotic ⚡, Blue 🌧️, Stressed 🌪️, Grateful 🌸). 

By integrating a playful "Vibe Streak" (represented by a custom, glowing flame emoji) and an interactive monthly grid, users get a retro, gamified overview of their emotional landscape. Tapping on any day in the grid filters the main chat feed, making it effortless to re-read and reflect on past states.

---

## User Interface (UI) Specs

### 1. Main Timeline Integration
- **Calendar Entry Button**: A custom-styled glassmorphic calendar icon button (`Icons.calendar_month_outlined`) positioned in the top-right corner of the timeline screen's app bar.
- **Micro-Streak Badge**: If the user has an active streak (>= 2 days), a tiny glowing flame emoji badge (e.g., `🔥 5`) is overlaid on the calendar button.

### 2. Vibe Calendar Screen
Tapping the calendar icon navigates to a new full-screen route styled with a dark, vaporwave-inspired aesthetic:
- **Header Section**:
  - Title: `My Vibe Calendar 🗓️` styled in a bold modern sans-serif font (e.g., Outfit) with a soft violet text shadow.
  - Subtitle: A dynamic message based on the current month's dominant mood (e.g. *"Mostly feeling Chill this month ☁️"*).
  - Back Button: Custom chevron icon that slides back to the main timeline.
- **Streak Card**:
  - A glassmorphic banner displaying: `🔥 Current Vibe Streak: X Days` and `✨ Longest Streak: Y Days`.
  - Decorated with a soft pulsing neon glow that changes color based on the dominant mood of the current week.
- **Calendar Grid**:
  - Shows a grid of days for the selected month (7 columns for days of the week, 4-6 rows).
  - Header showing days of the week (`M`, `T`, `W`, `T`, `F`, `S`, `S`) styled in semi-transparent white.
  - **Tile Styling**:
    - Each tile is a rounded rectangle (`BorderRadius.circular(8.0)`).
    - If a day has no entries, the tile is styled with a subtle, dark-gray dashed border and translucent center (opacity 0.15).
    - If a day has entries, the tile is filled with the color corresponding to the dominant mood of that day:
      - `hype` (🌟): Radiant gold gradient.
      - `chill` (☁️): Lavender-purple-blue gradient.
      - `chaotic` (⚡): Charcoal with neon lime-green outline.
      - `blue` (🌧️): Deep misty blue-grey/indigo gradient.
      - `stressed` (🌪️): Deep warning crimson-orange gradient.
      - `grateful` (🌸): Soft rose-pink to peach gradient.
      - `none` (Default): Translucent silver-grey.
    - Active/Today tile features a pulsing neon white border.
- **Month Selector**:
  - Top navigation bar containing previous `<` and next `>` chevrons flanking the current month and year (e.g., `June 2026`).
- **Mood Legend**:
  - A horizontal wrap of color-coded pills at the bottom of the screen displaying each mood type and its corresponding emoji badge for quick reference.

### 3. Tap Interaction & Filtered Timeline
- Tapping any active calendar tile opens a modal bottom sheet displaying a filtered preview of that day's entries.
- The bottom sheet has a header showing the date (e.g., `June 28, 2026`) and an action button: `View in Timeline 💬`.
- Tapping `View in Timeline` dismisses the sheet, pops the Vibe Calendar, and applies a date filter to the timeline feed, showing only the entries created on that specific day with a clear visual filter badge: `Filter: June 28, 2026 (Clear [x])`.

---

## Data Specs

### 1. Database Schema
No database schema changes are strictly required, as the existing `entry_index` table (database version 7) already contains the necessary columns:
- `created_at`: Creation timestamp (Unix epoch in milliseconds).
- `mood`: Emotion/vibe text (e.g. `'hype'`, `'chill'`, `'none'`).
- `archived`: Archival status (0 = false, 1 = true).

However, to support storing Vibe Calendar display settings, we can add key-value entries in the `app_settings` table:
- Key: `'vibe_calendar_start_day_of_week'`, Value: `'1'` (Monday) or `'7'` (Sunday).
- Key: `'vibe_calendar_show_streaks'`, Value: `'true'` or `'false'`.

### 2. Models & Queries
To retrieve calendar data efficiently, we introduce the following methods and queries in the application layer.

#### A. Daily Dominant Mood Query
Query to retrieve the dominant mood for each day in a given date range. The dominant mood is defined as the mood that occurs most frequently among non-archived entries on that day.

```sql
SELECT 
  DATE(created_at / 1000, 'unixepoch', 'localtime') as entry_date,
  mood,
  COUNT(mood) as mood_count
FROM entry_index
WHERE archived = 0 
  AND created_at >= ? 
  AND created_at <= ?
GROUP BY entry_date, mood
ORDER BY entry_date, mood_count DESC
```
In Dart, the repository layer will post-process these results to select the highest-scoring mood for each date key.

#### B. Journaling Streak Calculation
A helper service will analyze entries chronologically to calculate:
1. **Current Streak**: The number of consecutive days (up to and including today or yesterday) with at least one non-archived entry.
2. **Longest Streak**: The historical maximum number of consecutive journaling days.

```dart
class VibeStreakInfo {
  final int currentStreak;
  final int longestStreak;

  VibeStreakInfo({
    required this.currentStreak,
    required this.longestStreak,
  });
}
```

---

## UX/Flow Details

1. **Accessing the Vibe Grid**:
   - The user opens the Chronicle app and is greeted by their chat timeline.
   - They notice a glowing `🔥 3` badge next to a calendar icon in the top right.
   - They tap the calendar icon to view their patterns.

2. **Reflecting on the Month**:
   - The app navigates to the **Vibe Calendar Screen** with a smooth hero transition.
   - The screen shows a grid of blocks for the current month. The blocks form a beautiful, colorful mosaic reflecting their moods over the last few weeks.
   - The user sees that their current streak is `3 days` and their longest streak was `12 days`.
   - The header subtitle reads: *"Mostly feeling Grateful this month 🌸"*.

3. **Filtering by Date**:
   - The user notices a dark blue block on `June 15, 2026` (indicating a `blue` mood day) and wants to remember why they felt that way.
   - They tap the tile for June 15. A bottom sheet slides up showing a text snippet: *"Felt super overwhelmed with finals prep today..."*.
   - The user taps the `View in Timeline 💬` button.
   - The screen pops back to the timeline, which is now filtered to show only entries from June 15. A glowing purple filter banner is displayed at the top.
   - The user reviews the details, adds a follow-up comment if desired, and taps the `[x]` on the banner to clear the filter and return to the live timeline.
