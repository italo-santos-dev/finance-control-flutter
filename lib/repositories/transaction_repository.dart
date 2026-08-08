import 'package:flutter_investment_control/database/app_database.dart';
import 'package:flutter_investment_control/models/trade_transaction.dart';
import 'package:sqflite/sqflite.dart';

abstract class ITransactionRepository {
  Future<void> createTransaction(TradeTransaction transaction);
  Future<List<TradeTransaction>> getAllTransactions();
  Future<List<TradeTransaction>> getTransactionsByTicker(String ticker);
  Future<void> deleteTransaction(String id);
}

class TransactionRepository implements ITransactionRepository {
  final AppDatabase _dbProvider = AppDatabase.instance;

  @override
  Future<void> createTransaction(TradeTransaction transaction) async {
    final db = await _dbProvider.database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<TradeTransaction>> getAllTransactions() async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC, created_at DESC',
    );
    return result.map((json) => TradeTransaction.fromMap(json)).toList();
  }

  @override
  Future<List<TradeTransaction>> getTransactionsByTicker(String ticker) async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'transactions',
      where: 'ticker = ?',
      whereArgs: [ticker.toUpperCase().trim()],
      orderBy: 'date DESC',
    );
    return result.map((json) => TradeTransaction.fromMap(json)).toList();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await _dbProvider.database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> seedInitialTransactionsIfEmpty(List<TradeTransaction> defaultTrades) async {
    final db = await _dbProvider.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM transactions')) ?? 0;
    if (count == 0 && defaultTrades.isNotEmpty) {
      final batch = db.batch();
      for (final t in defaultTrades) {
        batch.insert('transactions', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    }
  }
}
