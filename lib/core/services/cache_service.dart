import 'dart:convert';
import 'package:mobile_app/core/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

/// Cache Service
/// Handles reading and writing to the local SQLite cache
class CacheService {
  static final DatabaseService _dbService = DatabaseService();

  /// Get cached data by key
  /// Returns decoded JSON or null if not found
  static Future<dynamic> getData(String key) async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseService.tableCoreCache,
      where: '${DatabaseService.colKey} = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final jsonString = maps.first[DatabaseService.colData] as String;
      try {
        return jsonDecode(jsonString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Save data to cache
  /// [value] will be JSON encoded
  static Future<void> setData(String key, dynamic value) async {
    final db = await _dbService.database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final jsonString = jsonEncode(value);

    await db.insert(
      DatabaseService.tableCoreCache,
      {
        DatabaseService.colKey: key,
        DatabaseService.colData: jsonString,
        DatabaseService.colLastUpdated: timestamp,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Remove specific key
  static Future<void> remove(String key) async {
    final db = await _dbService.database;
    await db.delete(
      DatabaseService.tableCoreCache,
      where: '${DatabaseService.colKey} = ?',
      whereArgs: [key],
    );
  }

  /// Clear all cache
  static Future<void> clearAll() async {
    final db = await _dbService.database;
    await db.delete(DatabaseService.tableCoreCache);
  }
}
