# Chronicle Query Engine

## Purpose

The query engine provides fast access to the user's journal entries while preserving the append-only event model.

Instead of replaying the event log for every query, Chronicle maintains a **materialized index table**.

This enables fast timeline loading.

---

# Index Table

entry_index

entry_id INTEGER PRIMARY KEY
type TEXT
content TEXT
media_path TEXT
created_at INTEGER
archived INTEGER

---

# Tag Index

entry_tags

entry_id INTEGER
tag TEXT

---

# Index Update Strategy

When events are written, the index must update accordingly.

Example:

EntryCreated
→ insert new row in entry_index

TagAdded
→ insert row in entry_tags

TagRemoved
→ remove row from entry_tags

EntryArchived
→ set archived = 1

---

# Timeline Query

To render the main timeline:

SELECT * FROM entry_index
WHERE archived = 0
ORDER BY created_at DESC

---

# Tag Filtering

To filter entries by tag:

SELECT entry_index.*
FROM entry_index
JOIN entry_tags
ON entry_index.entry_id = entry_tags.entry_id
WHERE entry_tags.tag = 'ideas'

---

# Date Filtering

Chronicle supports filtering by time range.

Example query:

SELECT * FROM entry_index
WHERE created_at BETWEEN start_timestamp AND end_timestamp

---

# Search Query

Basic text search:

SELECT * FROM entry_index
WHERE content LIKE '%keyword%'

Future improvement may include full-text search.

---

# Pagination

To prevent loading too many entries:

Use pagination.

Example:

SELECT * FROM entry_index
ORDER BY created_at DESC
LIMIT 50

---

# Index Rebuild

If corruption occurs:

1 Clear index tables
2 Replay events sequentially
3 Rebuild index state

This ensures full recoverability.

---

# Performance Goals

Timeline load time should be under:

200 milliseconds for 1000 entries.

Using index tables ensures consistent performance.

---

# Future Improvements

Full text search index

Memory caching

Timeline grouping by date

Graph-based memory linking
