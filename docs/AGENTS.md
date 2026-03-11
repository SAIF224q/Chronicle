# Chronicle Agent Rules

This file defines how AI coding agents should operate when working on the Chronicle project.

The goal is to ensure that generated code follows the architecture and does not diverge from project principles.

---

# Primary Objective

Build a local-first mobile journaling application called Chronicle.

Chronicle must prioritize:

data ownership
offline functionality
immutable storage
simple user experience

---

# Mandatory Rules

Agents must follow these rules.

1 Never introduce cloud dependencies.

2 Never store user data outside the device.

3 Never overwrite existing entries.

4 Always follow append-only event model.

5 Follow architecture defined in ARCHITECTURE.md.

---

# File Responsibility

Each file should have a single responsibility.

Examples:

database_service.dart
handles database connection and queries

media_manager.dart
handles file storage

entry_service.dart
handles entry creation logic

timeline_screen.dart
renders timeline UI

---

# Coding Standards

Prefer clear readable code.

Use descriptive variable names.

Avoid unnecessary dependencies.

Avoid extremely complex abstractions.

---

# Architectural Boundaries

UI Layer
must never access database directly.

Application Layer
must coordinate logic.

Data Layer
must handle persistence.

---

# Event Storage Rules

All entry actions must create events.

Events must never be edited or deleted.

Indexes may be rebuilt from events.

---

# Error Handling

The system must gracefully handle:

database failures
filesystem issues
media loading errors

User data must never be lost.

---

# Performance Expectations

Timeline must load quickly.

Target:

under 200ms for 1000 entries.

---

# Testing Requirements

Agents must verify that:

entries save correctly
timeline loads entries
media files save properly
export generates valid ZIP

---

# Change Discipline

Agents must implement changes incrementally.

Each feature must be complete and runnable before starting the next feature.

---

# Long-Term Vision

Chronicle should evolve into a reliable personal archive where users can safely store years of memories on their own device.
