# Codex Implementation Prompt — Chronicle App

You are building a mobile application called **Chronicle**.

Chronicle is a **local-first personal timeline journal** where users can save thoughts, photos, and ideas in a chronological chat-style interface.

You must follow the architecture and specification defined in:

PROJECT_SPEC.md
ARCHITECTURE.md
TASKS.md

Your job is to implement the MVP described in those documents.

---

# Core Requirements

Chronicle must follow these rules:

1. **Local-first architecture**
2. **No cloud dependency**
3. **All data stored locally**
4. **Media stored in filesystem**
5. **SQLite used for structured data**
6. **Offline functionality required**

---

# Technology Stack

Framework: Flutter
Language: Dart

Database: SQLite (sqflite package)

Media capture: image_picker

Filesystem access: path_provider

Export: archive package (for ZIP export)

---

# Project Structure

Create the following folder structure.

lib/

```
main.dart

core/
    database/
        database_service.dart
    models/
        entry_model.dart
        tag_model.dart
    services/
        entry_service.dart
        tag_service.dart

features/
    timeline/
        timeline_screen.dart
        timeline_item.dart
    
    create_entry/
        create_entry_screen.dart
    
    tags/
        tag_parser.dart

storage/
    media_manager.dart

export/
    export_service.dart
```

---

# Database Implementation

Create SQLite database named:

chronicle.db

Tables:

entries
tags
entry_tags

---

## entries table

id INTEGER PRIMARY KEY
type TEXT
content TEXT
media_path TEXT
created_at INTEGER
archived INTEGER DEFAULT 0

---

## tags table

id INTEGER PRIMARY KEY
name TEXT UNIQUE

---

## entry_tags table

entry_id INTEGER
tag_id INTEGER

---

# Entry Types

Supported types:

text
image

---

# Entry Creation Rules

When a user creates an entry:

1. Save media file to filesystem (if image)
2. Insert entry into database
3. Parse tags from text using #tag syntax
4. Store tags in tags table
5. Link tags using entry_tags

---

# Timeline UI

Main screen must show entries ordered by timestamp.

Display:

text entries
image entries

Each entry shows:

content
media (if exists)
timestamp
tags

Design should resemble **simple chat bubbles**.

---

# Media Storage

Create media directory inside app documents folder.

Example:

/chronicle/media/images/

Generate unique filenames using timestamp.

Example:

2026_03_11_1710183382.jpg

Store only the relative path in the database.

---

# Export Feature

Implement export function.

Steps:

1. Query all entries
2. Convert entries to JSON
3. Copy media files
4. Create ZIP archive

ZIP structure:

chronicle_export.zip

```
entries.json
media/
    images/
```

Save ZIP file to device storage.

---

# Coding Guidelines

Follow these principles:

Keep code modular

Separate UI from data logic

Use services for database operations

Use models for data structures

Use clear naming

Avoid unnecessary dependencies

---

# MVP Definition

The MVP is complete when:

User can create text entries

User can add photos

Entries appear in timeline

Tags work

Data stored locally

Export feature works

App runs completely offline

---

# Development Strategy

Implement features in this order:

1 Project setup
2 Database layer
3 Media manager
4 Entry creation
5 Timeline UI
6 Tag system
7 Export feature
8 UI polish

Always keep the app runnable after each step.

---

# Final Goal

Chronicle should be a **fast, minimal, private journaling app** where users can store memories safely on their own device without relying on cloud services.
