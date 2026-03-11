# Chronicle Development Tasks

This file defines the implementation roadmap for the Chronicle MVP.

---

# Phase 1 — Project Setup

Create Flutter project.

Set up folder structure.

Add dependencies:

sqflite
path_provider
image_picker
archive

Verify application runs.

---

# Phase 2 — Storage Engine

Implement SQLite database.

Create tables:

events
entry_index
entry_tags

Implement database service.

Functions:

initializeDatabase()
writeEvent()
getLastEventHash()

Test database creation.

---

# Phase 3 — Media Manager

Create media directory.

Structure:

/chronicle/media/images/

Implement media manager service.

Functions:

saveImage()
generateFilename()
getMediaDirectory()

Verify image storage.

---

# Phase 4 — Entry Creation

Create entry service.

Process:

generate entry_id

save media (optional)

write EntryCreated event

update entry_index table

parse tags

write TagAdded events

---

# Phase 5 — Timeline UI

Create timeline screen.

Use ListView builder.

Render entries from entry_index.

Display:

text entries
image entries
timestamps
tags

---

# Phase 6 — Tag Filtering

Implement tag filtering.

Query entry_tags table.

Display entries matching tag.

---

# Phase 7 — Export System

Implement export service.

Steps:

query entries

generate JSON file

copy media files

create ZIP archive

save ZIP to device storage

---

# Phase 8 — UI Polish

Improve message bubble layout.

Improve spacing.

Add timestamps.

Add light and dark theme.

---

# MVP Completion Criteria

Chronicle MVP is complete when:

user can create text entries

user can add photos

timeline displays entries

tags work correctly

export feature works

app functions fully offline
