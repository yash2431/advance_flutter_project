// lib/app/data/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../utils/app_constants.dart';
import '../models/recording_model.dart';

class DatabaseService extends GetxService {
  static Database? _database;

  Future<DatabaseService> init() async {
    _database = await _initDB();
    return this;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, AppConstants.DATABASE_NAME);

    return await openDatabase(
      path,
      version: AppConstants.DATABASE_VERSION,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.RECORDINGS_TABLE}(
        ${AppConstants.COLUMN_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AppConstants.COLUMN_NAME} TEXT NOT NULL,
        ${AppConstants.COLUMN_FILE_PATH} TEXT NOT NULL,
        ${AppConstants.COLUMN_DATE} INTEGER NOT NULL,
        ${AppConstants.COLUMN_DURATION} INTEGER NOT NULL,
        ${AppConstants.COLUMN_SIZE} INTEGER NOT NULL,
        ${AppConstants.COLUMN_IS_FAVORITE} INTEGER DEFAULT 0,
        ${AppConstants.COLUMN_IS_DELETED} INTEGER DEFAULT 0,
        ${AppConstants.COLUMN_TRANSCRIPTION} TEXT
      )
    ''');
  }

  Future<int> insertRecording(Recording recording) async {
    return await _database!.insert(
      AppConstants.RECORDINGS_TABLE,
      recording.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Recording>> getRecordings({
    bool? isFavorite,
    bool? isDeleted,
    String? searchKeyword,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<Map<String, dynamic>> maps = [];
    String whereClause = '';
    List<dynamic> whereArgs = [];

    // Apply filters
    if (isFavorite != null) {
      whereClause += '${AppConstants.COLUMN_IS_FAVORITE} = ?';
      whereArgs.add(isFavorite ? 1 : 0);
    }
    if (isDeleted != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '${AppConstants.COLUMN_IS_DELETED} = ?';
      whereArgs.add(isDeleted ? 1 : 0);
    } else {
      // Default to not deleted if not explicitly requested
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '${AppConstants.COLUMN_IS_DELETED} = 0';
    }

    if (searchKeyword != null && searchKeyword.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(${AppConstants.COLUMN_NAME} LIKE ? OR ${AppConstants.COLUMN_TRANSCRIPTION} LIKE ?)';
      whereArgs.add('%$searchKeyword%');
      whereArgs.add('%$searchKeyword%');
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '${AppConstants.COLUMN_DATE} >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '${AppConstants.COLUMN_DATE} <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    maps = await _database!.query(
      AppConstants.RECORDINGS_TABLE,
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: '${AppConstants.COLUMN_DATE} DESC', // Order by newest first
    );

    return List.generate(maps.length, (i) {
      return Recording.fromMap(maps[i]);
    });
  }

  Future<int> updateRecording(Recording recording) async {
    return await _database!.update(
      AppConstants.RECORDINGS_TABLE,
      recording.toMap(),
      where: '${AppConstants.COLUMN_ID} = ?',
      whereArgs: [recording.id],
    );
  }

  Future<int> deleteRecording(int id) async {
    return await _database!.delete(
      AppConstants.RECORDINGS_TABLE,
      where: '${AppConstants.COLUMN_ID} = ?',
      whereArgs: [id],
    );
  }

  // Specific methods for soft delete and restore
  Future<int> softDeleteRecording(int id) async {
    return await _database!.update(
      AppConstants.RECORDINGS_TABLE,
      {AppConstants.COLUMN_IS_DELETED: 1},
      where: '${AppConstants.COLUMN_ID} = ?',
      whereArgs: [id],
    );
  }

  Future<int> restoreRecording(int id) async {
    return await _database!.update(
      AppConstants.RECORDINGS_TABLE,
      {AppConstants.COLUMN_IS_DELETED: 0},
      where: '${AppConstants.COLUMN_ID} = ?',
      whereArgs: [id],
    );
  }

  Future<Recording?> getRecordingById(int id) async {
    final maps = await _database!.query(
      AppConstants.RECORDINGS_TABLE,
      where: '${AppConstants.COLUMN_ID} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Recording.fromMap(maps.first);
    }
    return null;
  }
}
