# Chronicle App

A local-first journaling application built with Flutter.

## Data Storage

Chronicle uses **SQLite** for local-first data storage. Your data stays on your device.

### Database Location
- **Database file**: `chronicle.db` in the app's documents directory
- **Media files**: Images stored in `chronicle/media/images/`

### Database Structure

1. **`events`** - Event-sourced audit log
   - `id`, `event_type`, `entry_id`, `payload`, `created_at`, `event_hash`, `previous_hash`

2. **`entry_index`** - Current state of journal entries
   - `entry_id`, `type`, `content`, `media_path`, `created_at`, `updated_at`, `archived`

3. **`entry_tags`** - Tags for entries
   - `entry_id`, `tag`

## Exporting Your Data

1. Tap the menu button (⋮) in the top-right corner of the app bar
2. Select **"Export Data"**
3. Save/share the exported ZIP file

The exported file (`chronicle_export_{timestamp}.zip`) contains:
- `entries.json` - All entries with tags and timestamps
- `media/` folder - All attached images

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
