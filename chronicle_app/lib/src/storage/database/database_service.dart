import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'chronicle_schema.dart';

typedef DatabaseDocumentsDirectoryProvider = Future<Directory> Function();

class DatabaseService {
  DatabaseService({
    DatabaseDocumentsDirectoryProvider? documentsDirectoryProvider,
    DatabaseFactory? factory,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _databaseFactory = factory ?? databaseFactory;

  Database? _database;
  final DatabaseDocumentsDirectoryProvider _documentsDirectoryProvider;
  final DatabaseFactory _databaseFactory;

  Future<void> initializeDatabase() async {
    await openDatabaseConnection();
  }

  Future<Database> openDatabaseConnection() async {
    final cachedDatabase = _database;
    if (cachedDatabase != null) {
      return cachedDatabase;
    }

    final databasePath = await getDatabasePath();
    final database = await _databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: ChronicleSchema.databaseVersion,
        onConfigure: _configureDatabase,
        onCreate: _createDatabase,
      ),
    );

    _database = database;
    return database;
  }

  Future<String> getDatabasePath() async {
    final documentsDirectory = await _documentsDirectoryProvider();
    return p.join(documentsDirectory.path, ChronicleSchema.databaseName);
  }

  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?> arguments = const <Object?>[],
  ]) async {
    final database = await openDatabaseConnection();
    return database.rawQuery(sql, arguments);
  }

  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final database = await openDatabaseConnection();
    return database.insert(table, values, conflictAlgorithm: conflictAlgorithm);
  }

  Future<void> execute(String sql) async {
    final database = await openDatabaseConnection();
    await database.execute(sql);
  }

  Future<T> transaction<T>(
    Future<T> Function(Transaction transaction) action,
  ) async {
    final database = await openDatabaseConnection();
    return database.transaction(action);
  }

  Future<void> close() async {
    final database = _database;
    if (database == null) {
      return;
    }

    await database.close();
    _database = null;
  }

  Future<void> _configureDatabase(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
    await database.rawQuery('PRAGMA journal_mode = WAL');
    await database.execute('PRAGMA synchronous = NORMAL');
    await database.rawQuery('PRAGMA busy_timeout = 5000');
    await database.execute('PRAGMA temp_store = MEMORY');
  }

  Future<void> _createDatabase(Database database, int version) async {
    final batch = database.batch();

    for (final statement in ChronicleSchema.createTableStatements) {
      batch.execute(statement);
    }

    for (final statement in ChronicleSchema.createIndexStatements) {
      batch.execute(statement);
    }

    await batch.commit(noResult: true);
  }
}
