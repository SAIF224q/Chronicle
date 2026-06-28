# Chronicle

Chronicle is a local-first journaling application built with Flutter. It helps users capture daily notes, voice recordings, location metadata, tags, and media in a secure offline-friendly app.

## What it is

- A Flutter app for managing journal entries and activity records
- Local storage based on SQLite for offline-first usage
- Support for text entries, image media, audio recordings, tags, and location metadata
- Designed for mobile and desktop platforms supported by Flutter

## Key features

- Create and edit journal entries
- Attach images and media
- Record and playback audio
- Add tags and search entries quickly
- Export and backup data as a ZIP archive
- Local SQLite storage with event auditing and current entry indexing

## Project structure

- `chronicle_app/` — Flutter application source and configuration
- `chronicle_app/lib/` — Flutter Dart source code
- `chronicle_app/android/` — Android build files
- `chronicle_app/ios/` — iOS build files
- `docs/` — design docs, architecture guides, and project specifications
- `features/` — feature specifications and design drafts

## Data storage

Chronicle uses **SQLite** (embedded database) for local-first data storage. Your data is stored entirely on your device.

### Database Location
- **Database file**: `chronicle.db` in the app's documents directory
- **Media files**: Images stored in `chronicle/media/images/`

### Database Structure

The database contains 3 main tables:

1. **`events`** - Event-sourced audit log
   - `id` - Primary key
   - `event_type` - Type of event (EntryCreated, EntryEdited, TagAdded, etc.)
   - `entry_id` - Reference to entry
   - `payload` - JSON event data
   - `created_at` - Unix timestamp
   - `event_hash` - Cryptographic hash
   - `previous_hash` - Chain linkage

2. **`entry_index`** - Current state of journal entries
   - `entry_id` - Primary key
   - `type` - Entry type ("text" or "image")
   - `content` - Entry text content
   - `media_path` - Path to image file
   - `created_at` - Creation timestamp
   - `updated_at` - Last edit timestamp
   - `archived` - Archival status

3. **`entry_tags`** - Tags for entries
   - `entry_id` - Reference to entry
   - `tag` - Lowercase tag name

## Exporting Your Data

You can export all your data from the app for backup purposes:

1. Tap the menu button (⋮) in the top-right corner of the app bar
2. Select **"Export Data"**
3. Choose how to save/share the exported ZIP file

The exported file (`chronicle_export_{timestamp}.zip`) contains:
- `entries.json` - All your journal entries with tags and timestamps
- `media/` folder - Copies of all attached images

This ensures you have a backup of your data that you can access even if the app is deleted.

## Getting started

### Prerequisites

- Flutter SDK installed and configured
- A connected device, emulator, or desktop support enabled

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/SAIF224q/Chronicle.git
   ```
2. Open the Flutter app folder:
   ```bash
   cd Chronicle/chronicle_app
   ```
3. Fetch Flutter dependencies:
   ```bash
   flutter pub get
   ```

### Run the app

- Run on the default device:
  ```bash
  flutter run
  ```
- Run on a specific platform, for example Android:
  ```bash
  flutter run -d android
  ```

## Development notes

- Package name: `chronicle_app`
- Version: `1.0.0+1`
- Key dependencies:
  - `sqflite`
  - `path_provider`
  - `image_picker`
  - `archive`
  - `share_plus`
  - `record`
  - `audioplayers`
  - `url_launcher`
  - `geolocator`
  - `google_fonts`

## Contributing
Contributions are welcome! Please read the [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements
- Thanks to all the contributors who made this project possible.
- Inspired by the work of the open-source community.