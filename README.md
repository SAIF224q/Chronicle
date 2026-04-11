# Chronicle

Chronicle is a project designed to manage and track events and activities effectively. It provides a structured way to record information, allowing users to easily access and manipulate their data.

## Features
- User-friendly interface for data entry
- Advanced search capabilities
- Data visualization options
- Export and import functionality
- Tag-based organization (hashtags)

## Data Storage

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

## Installation
To install Chronicle, follow these steps:
1. Clone the repository:
   ```
   git clone https://github.com/SAIF224q/Chronicle.git
   ```
2. Navigate into the directory:
   ```
   cd Chronicle
   ```
3. Install dependencies:
   ```
   npm install
   ```

## Usage
After installation, you can start the project:
```bash
npm start
```
Visit `http://localhost:3000` to view the application.

## Contributing
Contributions are welcome! Please read the [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements
- Thanks to all the contributors who made this project possible.
- Inspired by the work of the open-source community.