# Chronicle Storage Engine

## Overview

The Chronicle Storage Engine is responsible for safely storing and retrieving journal entries in a **local-first, append-only system**.

The engine is designed around three principles:

1. **Immutability**
2. **Local-first storage**
3. **Reliable timeline reconstruction**

Once a journal entry is created, it is never overwritten or modified. Instead, any changes are recorded as **new events**.

This design prevents accidental data loss and preserves the integrity of the timeline.

---

# Storage Philosophy

Chronicle treats each user action as an **event**.

Examples of events:

Entry created
Entry archived
Tag added
Tag removed

Instead of updating existing rows, the system appends new events to the database.

The visible state of the timeline is reconstructed by replaying these events.

This concept is similar to **event sourcing**.

---

# Core Components

The Chronicle Storage Engine consists of the following parts:

Event Log
Media Store
Index Layer
Query Engine

---

# Event Log

The Event Log is the primary source of truth.

All actions are stored as events in the database.

Events are stored in chronological order.

Each event describes what happened.

Example:

EntryCreated
EntryArchived
TagAdded

---

# Event Table

events

id INTEGER PRIMARY KEY
event_type TEXT
entry_id INTEGER
payload TEXT
created_at INTEGER

---

## Event Fields

id
Unique identifier.

event_type
Type of event.

entry_id
ID of the journal entry associated with the event.

payload
JSON containing additional information.

created_at
Timestamp of the event.

---

# Example Event

Entry creation event:

{
"event_type": "EntryCreated",
"entry_id": 101,
"payload": {
"type": "text",
"content": "Idea for a personal timeline journal"
},
"created_at": 1710183382
}

---

# Media Store

Media files are stored in the local filesystem.

Example structure:

/chronicle/

```
media/
    images/
    videos/
    audio/
```

Database stores references to media paths.

Example:

/media/images/20260311_1710183382.jpg

Media files are never automatically deleted.

---

# Entry Reconstruction

Entries shown in the timeline are reconstructed by processing events.

Example event sequence:

1 EntryCreated
2 TagAdded
3 TagAdded
4 EntryArchived

The system builds the current state by replaying these events.

---

# Timeline Index

To avoid replaying the entire event log each time, Chronicle maintains a lightweight index.

Table: entry_index

entry_id INTEGER PRIMARY KEY
type TEXT
content TEXT
media_path TEXT
created_at INTEGER
archived INTEGER

This index represents the **current state of entries**.

The index is updated whenever a new event is written.

---

# Write Flow

When a user creates a new entry:

1 Generate entry_id
2 Save media file (if needed)
3 Write EntryCreated event
4 Update entry_index table

---

# Archive Flow

If a user archives an entry:

1 Write EntryArchived event
2 Update entry_index archived flag

The original entry data remains unchanged.

---

# Tagging Events

Tags are also stored as events.

Example events:

TagAdded
TagRemoved

Payload example:

{
"tag": "ideas"
}

---

# Query Engine

The query engine reads from the **entry_index** table for fast retrieval.

Typical query:

SELECT * FROM entry_index
WHERE archived = 0
ORDER BY created_at DESC

This allows the timeline to load instantly.

---

# Data Integrity

Chronicle ensures data safety using these rules:

Events are append-only.

Events are never edited.

Indexes can be rebuilt from events.

Media files are never overwritten.

---

# Index Recovery

If the index becomes corrupted, it can be rebuilt.

Steps:

1 Clear entry_index table
2 Replay all events from event log
3 Rebuild entry states

This guarantees recoverability.

---

# Export Compatibility

Export uses the entry_index table to generate structured data.

Events may optionally be exported for full history reconstruction.

Export format:

chronicle_export.zip

entries.json
media/

---

# Performance Strategy

To maintain performance as the event log grows:

Entry index used for reads

Events stored sequentially

Queries executed on index table

This ensures fast timeline rendering.

---

# Future Improvements

Encrypted event log

Version snapshots

Time-travel timeline view

Multi-device sync

Deduplicated media storage

---

# Summary

The Chronicle Storage Engine guarantees that:

Memories cannot disappear silently.

The full history of actions is preserved.

The timeline remains reliable and recoverable.

Chronicle becomes a durable record of personal experiences stored entirely on the user's device.
