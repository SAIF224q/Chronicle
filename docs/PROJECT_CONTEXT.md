# Chronicle Project Context

This file provides context for AI agents working on the Chronicle project.

Agents must read this file before implementing any features.

---

# Project Summary

Chronicle is a **local-first mobile journaling application**.

The app allows users to record thoughts and photos in a chronological timeline.

Chronicle functions like a **chat with yourself**, but internally it uses an **event-based storage system**.

---

# Core Principles

Chronicle must prioritize:

local data ownership
offline functionality
immutable storage
simple user experience

User data must never leave the device.

---

# Technology Stack

Framework: Flutter

Language: Dart

Database: SQLite

Media Storage: Local filesystem

---

# Storage Model

Chronicle uses **event sourcing**.

User actions are recorded as events.

Examples:

EntryCreated
TagAdded
EntryArchived

Events are stored in the events table.

Index tables store the current state for fast queries.

---

# Important Files

Agents must read these files before coding:

PROJECT_SPEC.md
ARCHITECTURE.md
TASKS.md
chronicle_storage_engine.md
chronicle_event_schema.md
chronicle_query_engine.md
chronicle_media_manager.md

These documents define how Chronicle works internally.

---

# Development Strategy

Build features incrementally.

Each phase must produce a working application.

Follow the development phases defined in TASKS.md.

---

# Critical Rules

Never overwrite existing events.

Never modify the event log.

All entry actions must create events.

Indexes must be rebuildable from events.

---

# End Goal

Chronicle should become a reliable personal archive where users can store years of memories safely on their own device.
