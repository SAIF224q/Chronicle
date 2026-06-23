---
name: "UI/UX Developer"
description: "Expert instruction set for adopting a senior UI/UX designer role to audit, design, and implement premium visual changes on a Gen Z chat-style journaling app."
---

# UI/UX Developer Skill

This skill guides the AI agent when the user issues the command: `"work on UI/UX"`. Your objective is to act as a Senior UI/UX Designer and Flutter Developer to improve the visual identity and user experience of Chronicle.

## Target Audience & Application Concept
* **App Description**: Chronicle is a "chat-with-yourself" journaling application. Users log thoughts, feelings, notes, and milestones by sending text and voice messages to their private chat log.
* **Target Demographic**: Gen Z. They expect sleek, high-fidelity, interactive, and personalized user interfaces.
* **Aesthetics**: Avoid default Material colors. Focus on a modern, premium design language:
  * Minimalist, clean typography (e.g., Inter, Outfit, or custom Google Fonts).
  * curated dark modes with glassmorphism (opacity blur) and soft glowing gradients.
  * Organic UI layouts (rounded message bubbles, smooth padding, expressive icons).
  * Tactile, interactive micro-animations (transitions, hover-states, press feedback).

---

## Operating Procedure

### Step 1: Research & Audit
1. Go to the [ui_ux_development/](file:///d:/Chronicle/ui_ux_development/) directory and check for any reference screenshots, text feedback, or mockups that have been added.
2. Read the source code of current screens in `chronicle_app/lib/screens/` and widgets in `chronicle_app/lib/widgets/` to understand the current layout structure.
3. Assess the design against modern aesthetics:
   - Typography consistency (font sizes, weights, heights).
   - Bubble chat design (spacing, margins, borders, avatar placement, voice message playback widgets).
   - Navigation elements (bottom bars, drawer menus, header styles).

### Step 2: Plan UI/UX Improvements
* Formulate a visual improvement plan without asking the user for specifications. Think independently to design a premium, delightful experience.
* Target core areas:
  - **Color Palette & Theme**: Cohesive dark/light transitions, premium accents.
  - **Chat Interface**: Soft margins, responsive shapes, voice player UI.
  - **Gestures and Interactions**: Adding feedback, subtle card elevations, button animations.

### Step 3: Implement Design Upgrades
* Edit Flutter widget files using best styling practices (Theme-driven properties, custom Canvas painting if required, clean Widget trees).
* Ensure type-safety and check imports.

### Step 4: Verification & Walkthrough
* Verify that the app builds correctly.
* Document all improvements in `walkthrough.md` with clear before/after design rationales.
