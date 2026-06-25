class ChronicleSchema {
  const ChronicleSchema._();

  static const String databaseName = 'chronicle.db';
  static const int databaseVersion = 6;

  static const String eventsTable = 'events';
  static const String entryIndexTable = 'entry_index';
  static const String entryTagsTable = 'entry_tags';
  static const String appSettingsTable = 'app_settings';

  static const List<String> createTableStatements = <String>[
    '''
    CREATE TABLE IF NOT EXISTS events (
      id INTEGER PRIMARY KEY,
      event_type TEXT NOT NULL,
      entry_id INTEGER NOT NULL,
      payload TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      event_hash TEXT NOT NULL UNIQUE,
      previous_hash TEXT
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS entry_index (
      entry_id INTEGER PRIMARY KEY,
      type TEXT NOT NULL,
      content TEXT,
      media_path TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER,
      archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1)),
      hidden INTEGER NOT NULL DEFAULT 0 CHECK (hidden IN (0, 1)),
      location_name TEXT,
      latitude REAL,
      longitude REAL,
      mood TEXT NOT NULL DEFAULT 'none',
      transcript TEXT
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS entry_tags (
      entry_id INTEGER NOT NULL,
      tag TEXT NOT NULL,
      PRIMARY KEY (entry_id, tag)
    )
    ''',
    '''
    CREATE TABLE IF NOT EXISTS app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
    ''',
  ];

  static const List<String> createIndexStatements = <String>[
    '''
    CREATE INDEX IF NOT EXISTS idx_events_entry_id
    ON events(entry_id)
    ''',
    '''
    CREATE INDEX IF NOT EXISTS idx_events_created_at
    ON events(created_at)
    ''',
    '''
    CREATE INDEX IF NOT EXISTS idx_entry_index_timeline
    ON entry_index(archived, created_at DESC)
    ''',
    '''
    CREATE INDEX IF NOT EXISTS idx_entry_tags_tag
    ON entry_tags(tag)
    ''',
  ];
}
