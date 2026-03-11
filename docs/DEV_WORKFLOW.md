# Chronicle Development Workflow

This document describes the workflow AI agents should follow when implementing Chronicle.

---

# Development Strategy

Build the project in small incremental steps.

After each step the application must remain runnable.

---

# Phase 1 Project Initialization

Create Flutter project.

Set up folder structure.

Add dependencies:

sqflite
path_provider
image_picker
archive

Ensure app builds successfully.

---

# Phase 2 Database Layer

Implement database service.

Create tables:

events
entry_index
entry_tags

Test database initialization.

---

# Phase 3 Media Manager

Create media directory.

Implement:

saveImage()
generateFilename()
getMediaDirectory()

Verify media files save correctly.

---

# Phase 4 Entry Creation

Create entry creation service.

Process:

create entry ID
save media (if present)
write EntryCreated event
update index table

---

# Phase 5 Timeline UI

Create timeline screen.

Use ListView builder.

Render:

text entries
image entries

Display timestamps.

---

# Phase 6 Tag System

Parse tags from text using pattern:

#tag

Store tags in entry_tags table.

Allow filtering by tag.

---

# Phase 7 Export Feature

Implement export service.

Steps:

fetch entries
convert to JSON
copy media files
create ZIP archive

Verify exported data structure.

---

# Phase 8 UI Polish

Improve layout.

Add chat bubble style entries.

Improve spacing and typography.

---

# Completion Criteria

Chronicle MVP is complete when:

text entries work
photo entries work
timeline loads entries
tags work
data export works
app runs fully offline
