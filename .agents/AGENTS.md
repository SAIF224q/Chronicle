# Agent Rules & Workflows

This document defines the custom instructions and standard operating procedures (SOPs) for AI agents working in this repository. All agents must follow these rules strictly.

---

## 1. Feature Research & Logging (Scheduled Task Context)
*Note: This workflow is executed in a scheduled context by a separate agent instance.*
- **Goal**: Research modern social platforms and general trends to find highly desired features for a Gen Z chat-style journaling app.
- **Output**:
  - Save a detailed feature specification under `features/lowercase_with_underscores_name.md`.
  - Append the feature entry to [feature_log.md](file:///d:/Chronicle/feature_log.md) with status set to `not implemented`.

---

## 2. Feature Implementation Workflow
**Trigger**: When the user says: `"work on new feature"`.

1. **Locate Feature**: 
   - Open [feature_log.md](file:///d:/Chronicle/feature_log.md) and scan for features whose status is `not implemented`.
   - Identify the earliest feature that needs implementation and open its corresponding spec file under [features/](file:///d:/Chronicle/features/).
2. **Review Codebase**: Look at the relevant code sections that need modification (e.g. state management, models, screens).
3. **Implementation**:
   - Write clean, type-safe Flutter/Dart code.
   - Maintain the database schema and handle SQLite migrations properly if required.
4. **Verification**:
   - Verify that the codebase compiles and test cases pass.
5. **Mark Completed**:
   - Update the status column for the feature in [feature_log.md](file:///d:/Chronicle/feature_log.md) to `implemented`.
   - Add the **Date Implemented** (YYYY-MM-DD) column value.

---

## 3. UI/UX Improvement Workflow
**Trigger**: When the user says: `"work on UI/UX"`.

1. **Invoke UI/UX Skill**: Load and follow instructions in [.agents/skills/ui-ux-developer/SKILL.md](file:///d:/Chronicle/.agents/skills/ui-ux-developer/SKILL.md).
2. **Audit & Plan**: Check [ui_ux_development/](file:///d:/Chronicle/ui_ux_development/) folder for references. Audit existing screen layouts in `chronicle_app/lib/screens/`.
3. **Redesign & Polish**: Think independently to identify opportunities to elevate layout quality, animations, typography, and styling for a modern, Gen Z feel.
4. **Implementation & Walkthrough**: Modify styling files/widgets and document changes.
