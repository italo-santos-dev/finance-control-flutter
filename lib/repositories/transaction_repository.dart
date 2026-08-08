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
    if (db != null) {
      await db.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      // Robust Web & Fallback storage
      final current = await _dbProvider.getWebTransactions();
      current.removeWhere((item) => item['id'] == transaction.id);
      current.add(transaction.toMap());
      await _dbProvider.saveWebTransactions(current);
    }
  }

  @override
  Future<List<TradeTransaction>> getAllTransactions() async {
    final db = await _dbProvider.database;
    if (db != null) {
      final result = await db.query(
        'transactions',
        orderBy: 'date DESC, created_at DESC',
      );
      return result.map((json) => TradeTransaction.fromMap(json)).toList();
    } else {
      // Robust Web & Fallback storage
      final current = await _dbProvider.getWebTransactions();
      final list = current.map((json) => TradeTransaction.fromMap(json)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
  }

  @override
  Future<List<TradeTransaction>> getTransactionsByTicker(String ticker) async {
    final db = await _dbProvider.database;
    if (db != null) {
      final result = await db.query(
        'transactions',
        where: 'ticker = ?',
        whereArgs: [ticker.toUpperCase().trim()],
        orderBy: 'date DESC',
      );
      return result.map((json) => TradeTransaction.fromMap(json)).toList();
    } else {
      final current = await _dbProvider.getWebTransactions();
      final list = current
          .where((item) => (item['ticker'] ?? '').toString().toUpperCase() == ticker.toUpperCase().trim())
          .map((json) => TradeTransaction.fromMap(json))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await _dbProvider.database;
    if (db != null) {
      await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      final current = await _dbProvider.getWebTransactions();
      current.removeWhere((item) => item['id'] == id);
      await _dbProvider.saveWebTransactions(current);
    }
  }

  Future<void> seedInitialTransactionsIfEmpty(List<TradeTransaction> defaultTrades) async {
    final db = await _dbProvider.database;
    if (db != null) {
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM transactions')) ?? 0;
      if (count == 0 && defaultTrades.isNotEmpty) {
        final batch = db.batch();
        for (final t in defaultTrades) {
          batch.insert('transactions', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      }
    } else {
      final current = await _dbProvider.getWebTransactions();
      if (current.isEmpty && defaultTrades.isNotEmpty) {
        final initialList = defaultTrades.map((t) => t.toMap()).toList();
        await _dbProvider.saveWebTransactions(initialList);
      }
    }
  }
}
