# Feature Specification: Retro Polaroid Scrapbook Board

## Goal
A journal is more than just a list of texts; it is a repository of life's moments. Gen Z users appreciate visual storytelling, retro aesthetics (such as polaroid/Instax film), and custom personalization (similar to Pinterest boards, scrapbook diaries, and VSCO grids). 

The **Retro Polaroid Scrapbook Board** introduces a highly aesthetic, secondary visual view mode inside Chronicle. It aggregates past photo attachments, text highlights, and mood logs, rendering them as interactive Polaroid prints and colored paper scraps pinned onto a customizable, rich background canvas (such as corkboard or flowing pastel gradients). Users can customize the placement, tape styles, and board backdrops, turning their private journal feed into a nostalgic, shareable scrapbook.

---

## User Interface (UI) Specs

### 1. Timeline Entryway Trigger
- **Header Icon**: A scrapbook/album icon (`Icons.auto_awesome_motion` or `Icons.photo_library_outlined`) placed in the top app bar of the main chat timeline (next to the search or settings button).
- **Tool tip / Pulsing Indicator**: For first-time users, a small neon tooltip badge reads: *"See your memories as a retro collage! 📸"*

### 2. Main Scrapbook Canvas Screen (`ScrapbookBoardScreen`)
- **Canvas Backdrop**:
  - The background fills the screen. Users can choose from multiple themes:
    - `Warm Corkboard 🪵`: A realistic wood-textured background with soft shadows.
    - `Pastel Aura 🌸`: A fluid, slow-moving mesh gradient of lavender, blush pink, and mint green.
    - `Retro Graph Paper 📝`: A minimalist off-white grid/notebook paper style.
    - `Midnight Neon 🌌`: A deep charcoal glassmorphism theme with flowing purple-blue backlights.
- **Polaroid Snapshot Cards (Photo Entries)**:
  - If a timeline entry has a `media_path` pointing to an image, it is styled as a classic Polaroid card:
    - A thick, slightly off-white rectangular border with an organic aspect ratio.
    - The image sits in the top square frame.
    - The bottom border features a handwritten caption using `GoogleFonts.caveat()` or `GoogleFonts.indieFlower()`.
    - Caption text includes: the date (e.g., *"June 28, '26"*), the logged mood emoji (e.g., *"Chill ☁️"*), and the location if available (e.g., *"📍 Dolores Park"*).
- **Sticky Note Cards (Text-only Entries)**:
  - If an entry has no media but contains text, it is rendered as a cute, textured "sticky note" paper scrap:
    - Colored in pastel tones (mint, lavender, butter yellow, or sky blue) depending on the mood.
    - A torn paper edge style at the bottom.
    - Contains a short, handwritten snippet of the journal text in a darker ink color.
- **Washi Tape & Pins**:
  - Every card on the board is "held up" by a strip of digital washi tape or a metallic push-pin at the top edge.
  - The washi tape has custom patterns (e.g., grid, glitter, checkers, neon).
- **Dynamic Card Rotations**:
  - To simulate a real physical board, each card has a slight random rotation angle (between `-6` and `+6` degrees) applied via `Transform.rotate` to give it a messy, hand-made feel.

### 3. Controls & Customization Overlay
- **Floating Action Bar (Bottom Center)**:
  - A clean, semi-transparent frosted glass control panel:
    - **Theme Palette Icon (`Icons.palette_outlined`)**: Opens a quick-select slider to change the board backdrop.
    - **Tape Style Icon (`Icons.style_outlined`)**: Changes the pattern of the washi tape applied to cards.
    - **Organize/Grid Toggle (`Icons.grid_view`)**: Instantly snaps all cards from freeform positions back into a neat, clean grid, or releases them to a freeform canvas.
    - **Share/Save Icon (`Icons.download_rounded`)**: Exports the entire board.

### 4. Share Sheet / Image Export Preview
- The app uses a `RepaintBoundary` wrapped around the canvas.
- When the user taps the Export button, it captures the entire canvas (excluding the floating action bar controls).
- Renders the collage as a high-resolution PNG image, triggers the native share sheet, and plays a subtle confetti animation.

---

## Data Specs

### 1. Database Schema
No database schema migrations are required. The layout and board settings are stored as serialized configuration keys inside the existing `app_settings` table to keep the database lightweight.

- **`app_settings` Keys**:
  - Key: `'scrapbook_board_theme'`, Value: `'pastel_aura'` (stores the active backdrop theme name).
  - Key: `'scrapbook_washi_style'`, Value: `'checkers'` (stores the active tape pattern).
  - Key: `'scrapbook_layout_positions'`, Value: A JSON-serialized string representing the layout coordinates of cards.
    - Example payload format:
      ```json
      {
        "102": { "x": 45.5, "y": 120.0, "rotation": -3.2 },
        "105": { "x": 200.0, "y": 80.5, "rotation": 4.1 },
        "108": { "x": 110.0, "y": 310.0, "rotation": 0.5 }
      }
      ```
      *(Note: If a card ID has no coordinate saved yet, it falls back to a default staggered grid placement calculated on runtime).*

### 2. Models & Queries
- **`ScrapbookCardModel`**:
  - Wraps the timeline entry along with its custom coordinate positioning:
    ```dart
    class ScrapbookCard {
      final int entryId;
      final String? mediaPath;
      final String? content;
      final String mood;
      final int createdAt;
      final String? locationName;
      
      double x;
      double y;
      double rotation;
      
      ScrapbookCard({
        required this.entryId,
        this.mediaPath,
        this.content,
        required this.mood,
        required this.createdAt,
        this.locationName,
        this.x = 0.0,
        this.y = 0.0,
        this.rotation = 0.0,
      });
    }
    ```
- **Timeline Query Scope**:
  - Query: Select the 30 most recent entries where `archived = 0` and `hidden = 0` and `unlock_at` is either null or has already passed.
  - Sort by `created_at DESC`.

---

## UX/Flow Details

1. **Entering the Scrapbook**:
   - The user opens the app and notices the scrapbook icon (`Icons.auto_awesome_motion`) glowing gently in the top bar.
   - The user taps the icon.
   - The screen transitions with a smooth fade-and-zoom effect, revealing the `ScrapbookBoardScreen` styled with a warm corkboard background.
   - The entries slide onto the screen, rendering as Polaroid photos (for image uploads) or pastel sticky notes (for text entries), each rotated slightly at a random angle.

2. **Interacting and Arranging**:
   - The user presses and holds a Polaroid card. The card raises slightly (scale increases by `1.05` and shadow deepens).
   - They drag their finger across the screen. The Polaroid follows their movement smoothly.
   - Once they release, the card drops back onto the canvas with a soft haptic vibration.
   - The app updates the coordinate entry in the `app_settings` JSON map:
     `"scrapbook_layout_positions": "..."`.

3. **Customizing the Aesthetic**:
   - The user taps the Palette icon in the bottom floating bar.
   - A scrollable sheet pops up. They tap `Pastel Aura 🌸`.
   - The corkboard fades out, replaced by a gorgeous, slow-pulsing pink and purple mesh gradient.
   - They tap the Washi Tape icon and select `Glitter ✨`. The tape on all Polaroid margins shifts to a sparkly gold design.

4. **Saving & Sharing the Vibe**:
   - The user arranges the cards to their liking and taps the Export icon.
   - The floating controls fade out of view.
   - The `RepaintBoundary` captures the screen.
   - A native share/save sheet pops up, allowing them to send the collage to Instagram or save it to their Photos app.
   - Once shared or saved, the floating controls fade back in, and a short message floats: *"Collage saved! Keep vibing. 🎨"*
   - The user swipes down or taps Back to return to the standard chat timeline.
