# Chronicle — Product Specification

## Overview

Chronicle is a **local-first mobile journaling application** that allows users to capture thoughts, photos, and ideas in a chronological timeline.

The interface resembles a **chat with yourself**, but internally the app functions as a **personal event-based database**.

Chronicle prioritizes:

* privacy
* local data ownership
* offline functionality
* immutable memory storage

All data is stored on the user's device.

---

# Core Philosophy

## Local First

Chronicle operates fully offline.

All user data is stored locally on the device using:

SQLite database
filesystem media storage

Cloud services are not required.

Future versions may include optional cloud backup.

---

## Immutable Timeline

Entries in Chronicle are **append-only**.

Instead of modifying or deleting entries directly, Chronicle records user actions as **events**.

Examples:

EntryCreated
TagAdded
EntryArchived

This ensures memories cannot disappear accidentally.

---

## Data Ownership

Users must always be able to export their data.

Export format:

ZIP archive containing:

entries.json
media files

This ensures long-term portability.

---

# MVP Features

## Timeline Journal

Main screen displays entries in chronological order.

Supported entry types:

text
image

Entries include:

content
media
timestamp
tags

---

## Entry Creation

Users can create entries by:

typing text
adding photos from camera or gallery

When created:

1 Media saved locally
2 EntryCreated event written
3 Index tables updated

---

## Tagging System

Users can add tags using hashtag syntax.

Example:

#ideas
#travel
#notes

Tags enable filtering and search.

---

## Media Storage

Media files are stored locally.

Example directory:

/chronicle/media/images/

Database stores only file paths.

---

## Data Export

Users can export their entire journal.

Export structure:

chronicle_export.zip

entries.json
media/

---

# Non Goals for MVP

The following features are excluded from the initial version:

cloud sync
user accounts
encryption
voice entries
video entries
AI analysis

---

# Target Platform

Mobile application.

Platforms:

Android
iOS

Framework:

Flutter

---

# Data Storage Model

Chronicle uses an **event-based storage model**.

Events are the primary source of truth.

Database tables include:

events
entry_index
entry_tags

The index tables store the current state of entries for fast queries.

Indexes can be rebuilt by replaying the event log.

---

# User Experience Goals

Chronicle should feel:

minimal
fast
reliable
distraction free

Users should be able to capture a memory within seconds.

---

# Long Term Vision

Chronicle becomes a **personal timeline archive** where users can safely store years of thoughts, photos, and experiences on their own device.
