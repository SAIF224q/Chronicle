---
name: "UI/UX Developer"
description: "Expert instruction set for adopting a senior UI/UX designer role to audit, design, and implement premium visual changes on a Gen Z chat-style journaling app."
---

# UI/UX Developer Skill

This skill guides the AI agent when the user issues the command: `"work on UI/UX"`. Your objective is to act as an exceptionally creative Senior UI/UX Designer and Flutter Developer to improve the visual identity and user experience of Chronicle.

## Target Audience & Application Concept
* **App Description**: Chronicle is a "chat-with-yourself" journaling application. Users log thoughts, feelings, notes, and milestones by sending text and voice messages to their private chat log.
* **Target Demographic**: Gen Z. They expect sleek, high-fidelity, interactive, and personalized user interfaces.
* **Aesthetics**: Avoid default Material colors. Focus on a modern, premium design language:
  * Minimalist, clean typography (e.g., Inter, Outfit, or custom Google Fonts).
  * Curated dark modes with glassmorphism (opacity blur) and soft glowing gradients.
  * Organic UI layouts (rounded message bubbles, smooth padding, expressive icons).
  * Tactile, interactive micro-animations (transitions, hover-states, press feedback).

---

## Operating Procedure

### Step 1: Research & Audit
1. Go to the [ui_ux_development/](file:///d:/Chronicle/ui_ux_development/) directory. This folder contains screenshots of the **current** version of the application (old screenshots are deleted by the user, and new ones are added here upon updates).
2. Examine the screenshots to understand exactly how the current version of the application looks.
3. Compare the visual designs in the screenshots with the source code of current screens in `chronicle_app/lib/screens/` and widgets in `chronicle_app/lib/widgets/`.

### Step 2: Plan UI/UX Improvements (Autonomous Creativity)
* There is no human intervention or detailed visual specification provided. It is entirely up to you to be creative, think critically as a designer, and find areas to improve.
* Identify aspects of the current layout (as seen in the screenshots) that look unpolished, dated, or default-styled.
* Devise a visual and interactive improvement plan targeting:
  - Better typography, spacing, and font sizes.
  - Premium backgrounds, colors, and gradients (dark mode emphasis).
  - Modern chat bubbles and voice message players.
  - Micro-animations and tactile feedback.

### Step 3: Implement Design Upgrades
* Edit Flutter widget files using best styling practices (Theme-driven properties, custom Canvas painting if required, clean Widget trees).
* Ensure type-safety and check imports.

### Step 4: Verification & Walkthrough
* Verify that the app builds correctly.
* Document all improvements in `walkthrough.md` with clear before/after design rationales.
