import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Database Service
/// Manages SQLite database connection and migrations
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static const String _dbName = 'app_database.db';
  static const int _dbVersion = 1;

  // Table Names
  static const String tableCoreCache = 'core_cache';

  // Columns - Core Cache
  static const String colKey = 'key';
  static const String colData = 'data';
  static const String colLastUpdated = 'last_updated';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Core Cache Table
    // Generic key-value store for caching API responses
    await db.execute('''
      CREATE TABLE $tableCoreCache (
        $colKey TEXT PRIMARY KEY,
        $colData TEXT NOT NULL,
        $colLastUpdated INTEGER NOT NULL
      )
    ''');
  }

  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
