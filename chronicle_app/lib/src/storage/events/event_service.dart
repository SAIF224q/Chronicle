import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';

import '../database/chronicle_schema.dart';
import '../database/database_service.dart';

class ChronicleEventDraft {
  const ChronicleEventDraft({
    required this.eventType,
    required this.entryId,
    required this.payload,
    this.createdAt,
  });

  final String eventType;
  final int entryId;
  final Map<String, Object?> payload;
  final int? createdAt;
}

class ChronicleEventRecord {
  const ChronicleEventRecord({
    required this.id,
    required this.eventType,
    required this.entryId,
    required this.payloadJson,
    required this.createdAt,
    required this.eventHash,
    required this.previousHash,
  });

  factory ChronicleEventRecord.fromDatabaseMap(Map<String, Object?> map) {
    return ChronicleEventRecord(
      id: map['id']! as int,
      eventType: map['event_type']! as String,
      entryId: map['entry_id']! as int,
      payloadJson: map['payload']! as String,
      createdAt: map['created_at']! as int,
      eventHash: map['event_hash']! as String,
      previousHash: map['previous_hash'] as String?,
    );
  }

  final int id;
  final String eventType;
  final int entryId;
  final String payloadJson;
  final int createdAt;
  final String eventHash;
  final String? previousHash;
}

class EventService {
  EventService(this._databaseService);

  final DatabaseService _databaseService;

  Future<String?> getLatestEventHash({DatabaseExecutor? executor}) async {
    if (executor != null) {
      return _readLatestEventHash(executor);
    }

    final database = await _databaseService.openDatabaseConnection();
    return _readLatestEventHash(database);
  }

  Future<ChronicleEventRecord> writeEvent(
    ChronicleEventDraft draft, {
    DatabaseExecutor? executor,
  }) async {
    _validateDraft(draft);

    if (executor != null) {
      return _writeEventWithExecutor(executor, draft);
    }

    return _databaseService.transaction(
      (transaction) => _writeEventWithExecutor(transaction, draft),
    );
  }

  Future<String?> _readLatestEventHash(DatabaseExecutor executor) async {
    final rows = await executor.rawQuery('''
      SELECT event_hash
      FROM ${ChronicleSchema.eventsTable}
      ORDER BY id DESC
      LIMIT 1
      ''');

    if (rows.isEmpty) {
      return null;
    }

    return rows.first['event_hash'] as String;
  }

  Future<ChronicleEventRecord> _writeEventWithExecutor(
    DatabaseExecutor executor,
    ChronicleEventDraft draft,
  ) async {
    final previousHash = await _readLatestEventHash(executor);
    final createdAt =
        draft.createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payloadJson = _canonicalJsonEncode(draft.payload);

    // Events are chained by hash so every write remains append-only and
    // tamper-evident.
    final eventHash = _buildEventHash(
      eventType: draft.eventType,
      entryId: draft.entryId,
      payload: draft.payload,
      createdAt: createdAt,
      previousHash: previousHash,
    );

    final id = await executor
        .insert(ChronicleSchema.eventsTable, <String, Object?>{
          'event_type': draft.eventType,
          'entry_id': draft.entryId,
          'payload': payloadJson,
          'created_at': createdAt,
          'event_hash': eventHash,
          'previous_hash': previousHash,
        });

    final insertedRows = await executor.query(
      ChronicleSchema.eventsTable,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    return ChronicleEventRecord.fromDatabaseMap(insertedRows.single);
  }

  void _validateDraft(ChronicleEventDraft draft) {
    if (draft.eventType.trim().isEmpty) {
      throw ArgumentError.value(
        draft.eventType,
        'eventType',
        'Event type must not be empty.',
      );
    }

    if (draft.entryId <= 0) {
      throw ArgumentError.value(
        draft.entryId,
        'entryId',
        'Entry ID must be greater than zero.',
      );
    }

    if (draft.createdAt case final int createdAt when createdAt <= 0) {
      throw ArgumentError.value(
        draft.createdAt,
        'createdAt',
        'createdAt must be a positive Unix timestamp.',
      );
    }
  }

  String _buildEventHash({
    required String eventType,
    required int entryId,
    required Map<String, Object?> payload,
    required int createdAt,
    required String? previousHash,
  }) {
    final canonicalEvent = _canonicalJsonEncode(<String, Object?>{
      'created_at': createdAt,
      'entry_id': entryId,
      'event_type': eventType,
      'payload': payload,
      'previous_hash': previousHash ?? '',
    });

    return sha256.convert(utf8.encode(canonicalEvent)).toString();
  }

  String _canonicalJsonEncode(Object? value) {
    return jsonEncode(_normalizeJsonValue(value));
  }

  Object? _normalizeJsonValue(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }

    if (value is List) {
      return value.map(_normalizeJsonValue).toList(growable: false);
    }

    if (value is Map) {
      final sortedKeys =
          value.keys.map((Object? key) => key.toString()).toList()..sort();
      final normalized = <String, Object?>{};

      for (final key in sortedKeys) {
        normalized[key] = _normalizeJsonValue(value[key]);
      }

      return normalized;
    }

    throw ArgumentError(
      'Unsupported payload value type: ${value.runtimeType}.',
    );
  }
}
