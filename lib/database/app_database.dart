import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance_control.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Multiplatform support (Desktop / Windows / FFI + Mobile)
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
    } else if (kIsWeb) {
      // For Web fallback or mobile standard
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      return await openDatabase(path, version: 1, onCreate: _createDB);
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      return await openDatabase(path, version: 1, onCreate: _createDB);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Transactions table (Single Source of Truth for financial events)
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

    // Indexes for fast date and ticker queries
    await db.execute('CREATE INDEX idx_transactions_ticker ON transactions (ticker)');
    await db.execute('CREATE INDEX idx_transactions_date ON transactions (date)');

    // 2. Assets table (Metadata & Current Quotes Cache)
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

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
