# Feature Specification: Weekly Vibe Wrapped Recaps

## Goal
Reflection is a powerful tool for mental health, but many users struggle to notice long-term emotional patterns or celebrate consistency. Inspired by Spotify Wrapped, Duolingo Year in Review, and social media recaps, the **Weekly Vibe Wrapped Recaps** feature automates self-reflection by generating a highly aesthetic, interactive weekly summary of the user's journaling activity, mood distributions, top keywords, and active streaks.

Every Sunday evening (or when triggered manually), the app inserts a beautiful, interactive "Weekly Wrapped" card directly into the chat feed. Tapping it opens a full-screen, immersive stories-style presentation that visualizes their week’s emotions, highlights their peak journaling times, highlights their top tags/words, and provides a shareable summary card. This makes looking back fun, effortless, and extremely rewarding, driving long-term retention.

---

## User Interface (UI) Specs

### 1. Timeline Card Integration
- **Wrapped Card Bubble**:
  - Appears in the chat feed as a specialized system entry (e.g., `📊 Weekly Vibe Wrapped`).
  - **Styling**:
    - Frosted glassmorphism design with a dark background and a subtle flowing neon gradient border.
    - Large icon indicator on the left/top: `📊` or `✨`.
    - Headline: `Weekly Vibe Wrapped` styled in bold, uppercase neon typography.
    - Subtitle: `Week of June 24 – June 30` (or appropriate date range).
    - Footer action chip: `Tap to Play ➡️` styled with a pulsating glow effect.
  - **Behavior**: Tapping anywhere on the card triggers a full-screen modal or pushes a screen displaying the story flow.

### 2. Full-Screen Wrapped Story Screen (`WeeklyWrappedScreen`)
The screen adopts a stories-style UI popular on Instagram and Snapchat:
- **Layout**:
  - **Progress Segment Indicators**: A row of thin horizontal progress bars at the top of the screen. The active bar fills over 5 seconds. When full, the app auto-navigates to the next slide.
  - **Slide Area**: The central portion displays high-fidelity visual cards.
  - **Navigation Gestures**:
    - Tap on the right 30% of the screen: Skip to the next slide immediately.
    - Tap on the left 30% of the screen: Go back to the previous slide immediately.
    - Tap-and-hold anywhere: Pause the story playback (freezes the timer/progress bar) to read or examine details.
    - Swipe down: Dismiss the screen with a smooth page-slide transition and return to the chat timeline.
- **Story Slides (5 slides total)**:
  - **Slide 1: Cover & Weekly Mood Aura**:
    - Background: A fluid, slow-moving animated gradient (using `MeshGradient` or blended `LinearGradient`s) composed of the colors of the user's top two moods for the week (e.g., if Hype and Chill dominated, a vibrant yellow-to-teal glow).
    - Typography: Large bold letters reading: *"Alex, this week was a total Vibe."* or *"Here is your weekly aura."*
    - Visual: A floating glowing aura orb in the center that matches the dominant moods.
  - **Slide 2: Mood Spectrum**:
    - Visual: A beautiful animated circular doughnut chart or horizontal stacked progress bars showing the breakdown of the user's logged moods (e.g. `Hype 🌟: 35%`, `Chill ☁️: 45%`, `Chaotic ⚡: 20%`).
    - Title: *"Your Mood Spectrum"*
    - Subtitle/Insight text: *"A calm week with a touch of chaos."*
  - **Slide 3: Word Vibe Check (Top Tags & Keywords)**:
    - Visual: A stylized word/tag cloud. Keywords are scaled in size and opacity based on their frequency in `entry_tags` or in message text logs.
    - Title: *"Living Rent-Free in Your Mind"*
    - Subtitle: *"Your top topics and tags this week."*
  - **Slide 4: Peak Vibe Hour & Consistency**:
    - Visual: An interactive clock outline showing a highlighted neon slice representing their peak journaling hour, alongside a glowing streak flame indicator (`🔥`).
    - Title: *"Night Owl or Early Riser?"*
    - Text description: *"You recorded most entries around 11:30 PM. You kept your streak burning at 🔥 5 days!"*
  - **Slide 5: Weekly Wrapped Recap Summary**:
    - Visual: A single, beautifully balanced infographic-style card summarizing: dominant vibe, streak count, total entries, voice minutes, and key words.
    - Action Buttons:
      - **"Save to Gallery" Button**: Taps into native device storage to export the summary slide as a high-resolution PNG image.
      - **"Close" Button**: Returns to the timeline.

### 3. Share Sheet / Image Export Preview
- A stylized image generator widget is run off-screen (using `RepaintBoundary`) to produce a clean aspect-ratio card layout optimal for mobile devices.

---

## Data Specs

### 1. Database Schema
No database schema migrations are necessary, but we will introduce a new system-generated `entry_index` type to store wrapped summaries in the timeline:
- **`TimelineEntry` Type**: We use the value `weekly_wrapped` in the `type` column of the `entry_index` table.
- **Metadata Storage**: The JSON payload of the recap metrics is stored inside the `content` field.
  - Structure of `content` JSON:
    ```json
    {
      "week_label": "June 24 - June 30",
      "start_timestamp": 1782259200,
      "end_timestamp": 1782863999,
      "total_entries": 12,
      "voice_minutes": 4.2,
      "dominant_mood": "chill",
      "mood_percentages": {
        "chill": 50,
        "hype": 30,
        "chaotic": 20
      },
      "top_keywords": ["study", "coffee", "music"],
      "peak_hour": 23,
      "streak": 5,
      "viewed": false
    }
    ```
- To prevent duplicate generation:
  - Add a key to `app_settings`: Key: `'last_weekly_wrapped_date'`, Value: `'2026-W26'` (saves the year and week number of the last successfully created recap card).

### 2. Models & Queries
To construct this card, a calculation service `WeeklyWrappedService` is created.
- **Weekly Query Scope**:
  - `TimelineQueryService` will support fetching entries between `week_start` and `week_end`.
  - Extract tags from `entry_tags` for entries within the date range.
  - Count frequency of unique `mood` values for entries in the date range.
  - Sum the duration or size of voice message media attachments.
  - Group entries by hour of the day (`created_at`) to find the mode (peak hour).

---

## UX/Flow Details

1. **System Trigger (Sunday Night)**:
   - At 8:00 PM on Sunday (or when the user first opens the app after Sunday 8:00 PM), the app runs a checks routine.
   - It verifies that the user has at least 3 journal entries logged in the past 7 days (to ensure there is enough data for a meaningful wrapped).
   - It checks `app_settings` to see if a wrapped entry for the current week has already been generated.
   - If not generated, the `WeeklyWrappedService` calculates the statistics from the SQLite database.
   - A new timeline entry is inserted:
     - `type = 'weekly_wrapped'`
     - `content` = (JSON-serialized recap metrics)
     - `created_at` = (Current timestamp)
   - A local push notification is sent: *"Your Weekly Vibe Wrapped is ready! Tap to see how you vibed this week. 📊"*

2. **Opening the Recap**:
   - The user opens the app and sees the glowing glassmorphism `Weekly Vibe Wrapped` card at the top of their chat timeline.
   - The user taps the card.
   - The app opens `WeeklyWrappedScreen` with a smooth hero transition or full-screen overlay.

3. **Watching the Story**:
   - The story starts playing. Slide 1 (Aura) fades in with fluid gradient animations.
   - The user taps right to advance to Slide 2 (Mood Spectrum) and Slide 3 (Word Cloud).
   - They hold down on Slide 3 to read the word list carefully. Upon release, playback resumes.
   - Slide 4 shows their late-night peak journaling time with an animated clock hand.
   - Slide 5 displays the summary card.

4. **Saving and Sharing**:
   - The user taps "Save to Gallery".
   - The app renders the summary card widget to an image, saves it to the gallery, and plays a subtle haptic feedback and displays a custom floating message: *"Saved to gallery! 📸 Ready to share."*
   - The user taps the "Close" button or swipes down.
   - The screen is dismissed. The timeline card's status updates to `viewed: true` in the JSON metadata, changing its glow from pulsing neon to a static, elegant frosted border.
