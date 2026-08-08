import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Multiplatform storage layer: Uses SQLite FFI on Windows/Linux/macOS,
/// native SQLite on Android/iOS, and persistent Local Storage on Web.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;
  static bool _isWebOrFallback = kIsWeb;

  AppDatabase._init();

  bool get isWebStorage => _isWebOrFallback;

  Future<Database?> get database async {
    if (kIsWeb) {
      _isWebOrFallback = true;
      return null;
    }
    if (_database != null) return _database!;
    try {
      _database = await _initDB('finance_control.db');
      return _database;
    } catch (e) {
      debugPrint('SQLite init failed, using robust fallback storage: $e');
      _isWebOrFallback = true;
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      final appSupportDir = await getApplicationSupportDirectory();
      final dbPath = join(appSupportDir.path, filePath);
      
      return await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        ),
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      return await openDatabase(path, version: 1, onCreate: _createDB);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        ticker TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        price REAL NOT NULL,
        fees REAL NOT NULL DEFAULT 0.0,
        total REAL NOT NULL,
        date TEXT NOT NULL,
        broker TEXT NOT NULL,
        active_type TEXT NOT NULL DEFAULT 'Ação',
        segment TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_transactions_ticker ON transactions (ticker)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions (date)');

    await db.execute('''
      CREATE TABLE assets (
        ticker TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        active_type TEXT NOT NULL,
        segment TEXT NOT NULL,
        current_price REAL NOT NULL DEFAULT 0.0,
        last_year_high REAL NOT NULL DEFAULT 0.0,
        last_year_low REAL NOT NULL DEFAULT 0.0,
        dividend_yield REAL NOT NULL DEFAULT 0.0,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // Web & Multiplatform Storage Helpers
  Future<List<Map<String, dynamic>>> getWebTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('db_transactions') ?? [];
    return list.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  Future<void> saveWebTransactions(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final list = items.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('db_transactions', list);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
