# Chronicle Media Manager

## Purpose

The media manager handles storage and retrieval of all non-text assets.

This includes:

images
videos
audio files

Media is stored locally on the user's device.

---

# Media Storage Structure

Chronicle uses a structured filesystem layout.

Example:

/chronicle/

```
media/
    images/
    videos/
    audio/
```

---

# File Naming Strategy

Media filenames must be unique.

Chronicle uses timestamp-based naming.

Example:

20260311_1710183382.jpg

Format:

YYYYMMDD_timestamp.extension

---

# Media Save Process

When a user adds media:

1 Receive file from picker
2 Generate filename
3 Ensure media directory exists
4 Copy file to Chronicle folder
5 Return relative path

Example returned path:

/media/images/20260311_1710183382.jpg

---

# Media Reference Storage

The database does not store binary files.

Instead it stores a **path reference**.

Example:

media_path = "/media/images/20260311_1710183382.jpg"

---

# Media Loading

To display media:

1 Retrieve path from database
2 Build absolute path using documents directory
3 Load file

---

# Storage Safety

Chronicle must never overwrite media files.

Always generate unique filenames.

---

# Storage Optimization

Future versions may generate smaller previews.

Example:

photo_original.jpg
photo_preview.jpg

Original files must remain intact.

---

# Media Cleanup

Media should never be deleted automatically.

Deletion only occurs when the user explicitly removes a file.

---

# Media Export

During export:

Media files must be copied into:

export/media/

The export archive must contain all referenced files.

---

# Future Improvements

Deduplicated media storage

Automatic thumbnail generation

Video compression

Background upload for optional cloud sync
