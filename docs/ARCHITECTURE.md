# Chronicle System Architecture

## Overview

Chronicle uses a **local-first architecture** built around an append-only event storage model.

All data is stored on the device using:

SQLite database
local filesystem

No external servers are required.

---

# High Level Architecture

Mobile App (Flutter)

UI Layer
Application Layer
Storage Engine
Filesystem Media Store

---

# Layer Responsibilities

## UI Layer

Responsible for rendering screens and handling user interaction.

Examples:

timeline screen
entry creation screen

UI must never directly access the database.

---

## Application Layer

Contains business logic.

Services coordinate actions such as:

entry creation
tag parsing
export operations

Examples:

entry_service.dart
tag_service.dart
export_service.dart

---

## Storage Engine

Handles all persistent data.

Components:

Event Log
Entry Index
Tag Index

Events represent user actions.

Indexes provide fast query access.

---

# Storage Engine Components

## Event Log

Primary source of truth.

Table:

events

Fields:

id
event_type
entry_id
payload
created_at
event_hash
previous_hash

Events are append-only.

---

## Entry Index

Materialized table representing current entry state.

Table:

entry_index

Fields:

entry_id
type
content
media_path
created_at
archived

This table enables fast timeline queries.

---

## Tag Index

Stores tag relationships.

Table:

entry_tags

Fields:

entry_id
tag

---

# Media Storage

Media files are stored in the filesystem.

Directory structure:

/chronicle/media/

```
images/
videos/
audio/
```

Database stores relative paths.

Example:

/media/images/20260311_123.jpg

---

# Entry Creation Flow

User creates entry

↓

media saved to filesystem

↓

EntryCreated event written

↓

index tables updated

↓

timeline refreshed

---

# Timeline Query

Timeline reads from entry_index.

Example query:

SELECT * FROM entry_index
WHERE archived = 0
ORDER BY created_at DESC

---

# Export System

Export module collects:

entries
tags
media

Output format:

chronicle_export.zip

entries.json
media/

---

# Offline Guarantee

All application features must work without internet access.

Chronicle must never depend on network connectivity.

---

# Future Extensions

encrypted event storage
cloud backup
multi-device sync
AI memory summaries
