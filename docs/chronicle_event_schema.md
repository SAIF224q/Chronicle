# Chronicle Event Schema

## Purpose

This document defines the **event model** used by Chronicle’s append-only storage engine.

Chronicle records user actions as events rather than modifying rows directly.
Events are immutable and stored sequentially.

This approach ensures:

data integrity
recoverability
timeline reliability

---

# Event Model Overview

Every user action generates an event.

Examples:

EntryCreated
EntryArchived
TagAdded
TagRemoved
MediaAttached

Events are stored in the **events table**.

---

# Event Table Structure

events

id INTEGER PRIMARY KEY
event_type TEXT
entry_id INTEGER
payload TEXT
created_at INTEGER
event_hash TEXT
previous_hash TEXT

---

# Field Definitions

id
Auto increment event identifier.

event_type
Defines what action occurred.

entry_id
Logical entry identifier associated with the event.

payload
JSON structure containing event-specific data.

created_at
Unix timestamp of event creation.

event_hash
Hash of the event contents.

previous_hash
Hash of the previous event.

---

# Hash Chain

Each event contains a hash of the previous event.

Example chain:

Event1 → hash A
Event2 → previous_hash A
Event3 → previous_hash B

This forms a **tamper-evident chain**.

If any event changes, the chain breaks.

---

# Event Types

## EntryCreated

Creates a new journal entry.

Payload example:

{
"type": "text",
"content": "Thought about building Chronicle",
"media_path": null
}

---

## MediaAttached

Associates media with an entry.

Payload:

{
"media_type": "image",
"path": "/media/images/20260311_123.jpg"
}

---

## TagAdded

Adds a tag to an entry.

Payload:

{
"tag": "ideas"
}

---

## TagRemoved

Removes a tag.

Payload:

{
"tag": "ideas"
}

---

## EntryArchived

Marks entry as archived.

Payload:

{
"reason": "user_action"
}

---

# Event Write Process

When writing an event:

1 Fetch last event hash
2 Generate new event payload
3 Compute event_hash
4 Store event with previous_hash reference

Pseudo example:

new_hash = hash(event_data + previous_hash)

---

# Entry ID Generation

Entry IDs must remain stable.

Use incremental integers.

Example:

entry_id = last_entry_id + 1

---

# Event Replay

To reconstruct the journal state:

1 Read events in chronological order
2 Apply events sequentially
3 Build entry state

This process can rebuild the system from scratch.

---

# Event Retention

Events are never deleted.

Old events remain part of history.

This ensures Chronicle remains a **complete historical log**.

---

# Future Extensions

Additional event types may include:

EntryEditedNote
EntryFavorited
EntryPinned

All implemented using the same event schema.
