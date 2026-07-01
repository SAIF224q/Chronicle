# Feature Specification: Conversational Vibe Check Bot

## Goal
Journaling can often feel intimidating, leading to "blank page anxiety." Many users, especially Gen Z, prefer casual, conversational interactions over formal writing prompts. 

The **Conversational Vibe Check Bot** introduces an interactive, local-first virtual buddy directly in the chat feed (e.g. `🤖 Vibe Check Bot`). The bot checks in on the user either automatically at a scheduled daily time or when manually triggered by the user. It initiates a playful chat sequence, asking the user to log their energy level via quick-reply buttons (choice chips) and then responding with custom, emotionally intelligent journaling prompts.

This turns mood tracking and journaling into a friendly texting conversation, making it low-friction, highly engaging, and completely private (running 100% locally).

---

## User Interface (UI) Specs

### 1. Main Timeline Integration
- **Manual Trigger Button**: A sparkle/robot icon button (`Icons.smart_toy_outlined` or `Icons.auto_awesome`) positioned next to the attachment icon in the chat composer bar. Tapping it starts an instant vibe check session.
- **Bot Bubble Layout**:
  - Rendered in the timeline with a distinct styling compared to standard user entries:
    - Frosted glassmorphism background with a gradient border (neon cyan to purple/indigo).
    - Avatar icon (`🤖`) placed to the left or top-left of the bubble.
    - Header: `🤖 Vibe Check-In` styled in a small, semi-transparent neon font.
    - Italicized/sleek typography for the message content.
    - Standard edit and delete actions are disabled/hidden for bot prompts to preserve conversational integrity, though users can archive or delete the conversation thread if desired.
- **Typing Indicator**:
  - When the bot is preparing a response, a typing bubble is displayed featuring three pulsing dots (`_BotTypingIndicator`) using a simple `AnimatedBuilder` loop.

### 2. Interactive Quick-Reply Chips
- When the bot asks the user to rate their day or energy, a horizontal, scrollable strip of choice chips is rendered inline inside the bot bubble:
  - `🌟 Hype`
  - `☁️ Chill`
  - `⚡ Chaotic`
  - `🌧️ Blue`
  - `🌪️ Stressed`
  - `🌸 Grateful`
- **Interaction**:
  - Tapping a chip highlights it briefly, plays a haptic click, and automatically generates a user chat entry corresponding to the choice (e.g., *"I'm feeling Stressed 🌪️"* with the mood tag set to `stressed`).
  - Once selected, the chip row disappears from the active bubble to prevent duplicate selections, and the bot shows the typing indicator before sending a follow-up prompt.

### 3. Settings Integration
- Under the `SettingsScreen`, a new category tile: `Vibe Check-In Bot Settings` is added:
  - **Toggle**: `Enable Daily Vibe Check Bot` (enable/disable automated checks).
  - **Time Picker**: `Scheduled Check-In Time` (opens a time picker, default is `8:00 PM` / `20:00`).
  - **Reset/Clear History Button**: Option to clear all bot messages from the timeline.

---

## Data Specs

### 1. Database Schema
No database migrations or new tables are required, as we can utilize the existing database design:
- **`entry_index` Table**:
  - We reuse the `type` column to identify bot messages: `type = 'bot_prompt'` or `type = 'bot_response'`.
  - The `content` column stores the bot's prompt text.
  - The `mood` column stores the related mood category if applicable.
- **`app_settings` Table**:
  - Store configuration parameters as key-value pairs:
    - Key: `'vibe_check_bot_enabled'`, Value: `'true'` or `'false'`.
    - Key: `'vibe_check_bot_time'`, Value: `'20:00'` (Hour:Minute format).
    - Key: `'vibe_check_last_trigger_date'`, Value: `'2026-06-29'` (Tracks the last date an automated check was created to prevent duplicates).

### 2. Models & Queries
To integrate with the existing database models, we introduce helpers in the codebase.

#### A. TimelineEntry Helper
We add an extension or helper getter to the `TimelineEntry` class:
```dart
bool get isBot => type == 'bot_prompt' || type == 'bot_response';
```

#### B. Prompt Engine Map
A local service `VibeCheckService` will map selected moods to specific journaling prompts to simulate conversational intelligence:
```dart
const Map<String, List<String>> moodPrompts = {
  'hype': [
    "Love that energy! 🌟 What went super well today? Drop the highlight!",
    "Celebrate that win! 🥂 Who else was part of this vibe today?",
    "Keep that momentum! 🚀 What are you excited to tackle next?"
  ],
  'chill': [
    "Cozy vibes ☁️. What was a small moment of peace or relaxation today?",
    "Low key days are the best. What did you spend your downtime doing?",
    "Chill mode activated. Rate your comfort level today from 1 to 10!"
  ],
  'chaotic': [
    "Sounds wild ⚡! What made today feel so hectic or unpredictable?",
    "A bit of chaos keeps life interesting. How did you handle the spins?",
    "Breathe in... breathe out. What was the most unexpected thing that happened?"
  ],
  'blue': [
    "Sending a gentle hug 🌧️. What's sitting heavy on your heart today?",
    "It's okay not to be okay. What is one thing that could make you feel 1% cozier?",
    "Let it out. Want to write down or record what's causing this blue mood?"
  ],
  'stressed': [
    "Take a deep breath 🌪️. What is the biggest thing draining your energy right now?",
    "Pressure is temporary. What is one small task you can delegate or ignore today?",
    "Let's untangle this. List 3 things you can control, and let go of the rest."
  ],
  'grateful': [
    "Beautiful attitude 🌸. Who or what are you most thankful for right now?",
    "Gratitude grows joy. Share one simple thing that made you smile today.",
    "What's a warm memory from today that you want to remember forever?"
  ],
  'none': [
    "Hey! Just a quick check-in. How has your day been shaping up so far?",
    "Time for a quick pause. What's the main theme of your day?",
    "What's on your mind right now? Share anything, big or small!"
  ]
};
```

---

## UX/Flow Details

1. **Daily Check-In Trigger**:
   - At the designated time (e.g. 8:00 PM), a local notification is triggered (or when the user next opens the app after that time).
   - A new message bubble from the bot is appended to the timeline:
     - *Content*: `"Hey! It's time for your daily vibe check-in. How are you feeling right now? 🤖"`
     - *Interactive chips* slide in below the bubble.

2. **Selecting a Vibe**:
   - The user taps the `stressed` (🌪️) chip.
   - The chip row disappears.
   - A user message is immediately logged: `"I'm feeling Stressed 🌪️"` with the mood attribute set to `stressed`.
   - The timeline scrolls down smoothly to focus on the conversation.

3. **Conversational Prompting**:
   - A typing indicator shows the bot is "typing..." for 1.2 seconds.
   - The bot replies: `"Take a deep breath 🌪️. What is the biggest thing draining your energy right now?"`
   - The user is prompted to type a text response or record a voice note.

4. **Finishing the Check-In**:
   - The user records a 30-second voice note describing their finals stress and hits send.
   - The entry is logged, automatically inheriting the `stressed` mood category from the session.
   - The bot replies with a final supportive emoji react or close: `"Got it. Sending you calm vibes for the rest of the evening! 🤍"` to close the interaction.
