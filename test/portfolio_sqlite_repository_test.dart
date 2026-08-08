import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_investment_control/models/trade_transaction.dart';
import 'package:flutter_investment_control/models/transaction_model.dart';
import 'package:flutter_investment_control/repositories/portfolio_repository.dart';
import 'package:flutter_investment_control/repositories/transaction_repository.dart';

class MockTransactionRepository extends TransactionRepository {
  final List<TradeTransaction> _inMemoryDb = [];

  @override
  Future<void> createTransaction(TradeTransaction transaction) async {
    _inMemoryDb.add(transaction);
  }

  @override
  Future<List<TradeTransaction>> getAllTransactions() async {
    return List.from(_inMemoryDb);
  }

  @override
  Future<List<TradeTransaction>> getTransactionsByTicker(String ticker) async {
    return _inMemoryDb.where((t) => t.ticker == ticker).toList();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _inMemoryDb.removeWhere((t) => t.id == id);
  }
}

void main() {
  group('SQLite & Portfolio Repository Tests', () {
    late MockTransactionRepository transactionRepo;
    late PortfolioRepository portfolioRepo;

    setUp(() {
      transactionRepo = MockTransactionRepository();
      portfolioRepo = PortfolioRepository(transactionRepository: transactionRepo);
    });

    test('Single BUY transaction creates exact portfolio position and extract entry', () async {
      final trade = TradeTransaction(
        id: 'trade-1',
        ticker: 'PETR4',
        name: 'Petrobras',
        type: TransactionType.buy,
        quantity: 100,
        price: 35.20,
        fees: 0.0,
        total: 3520.00,
        date: DateTime(2026, 8, 8),
        broker: 'XP Investimentos',
        activeType: 'Ação',
        segment: 'Petróleo e Gás',
        createdAt: DateTime(2026, 8, 8),
      );

      await transactionRepo.createTransaction(trade);

      final transactions = await transactionRepo.getAllTransactions();
      expect(transactions.length, 1);
      expect(transactions.first.ticker, 'PETR4');
      expect(transactions.first.total, 3520.00);

      final positions = await portfolioRepo.getPortfolioPositions();
      expect(positions.length, 1);
      expect(positions.first.ticker, 'PETR4');
      expect(positions.first.quantity, 100);
      expect(positions.first.averagePrice, 35.20);
    });

    test('Multiple BUY and SELL operations calculate correct net quantity and weighted average price', () async {
      // 1. Buy 100 @ 30.00 = 3000.00
      await transactionRepo.createTransaction(TradeTransaction(
        id: 'trade-1',
        ticker: 'VALE3',
        name: 'Vale S.A.',
        type: TransactionType.buy,
        quantity: 100,
        price: 30.00,
        total: 3000.00,
        date: DateTime(2026, 8, 1),
        broker: 'XP',
        createdAt: DateTime(2026, 8, 1),
      ));

      // 2. Buy 100 @ 40.00 = 4000.00 (Total invested = 7000, Total buy qty = 200, Avg = 35.00)
      await transactionRepo.createTransaction(TradeTransaction(
        id: 'trade-2',
        ticker: 'VALE3',
        name: 'Vale S.A.',
        type: TransactionType.buy,
        quantity: 100,
        price: 40.00,
        total: 4000.00,
        date: DateTime(2026, 8, 5),
        broker: 'XP',
        createdAt: DateTime(2026, 8, 5),
      ));

      // 3. Sell 50 (Net qty = 150)
      await transactionRepo.createTransaction(TradeTransaction(
        id: 'trade-3',
        ticker: 'VALE3',
        name: 'Vale S.A.',
        type: TransactionType.sell,
        quantity: 50,
        price: 42.00,
        total: 2100.00,
        date: DateTime(2026, 8, 8),
        broker: 'XP',
        createdAt: DateTime(2026, 8, 8),
      ));

      final positions = await portfolioRepo.getPortfolioPositions();
      expect(positions.length, 1);
      expect(positions.first.ticker, 'VALE3');
      expect(positions.first.quantity, 150);
      expect(positions.first.averagePrice, 35.00);
    });
  });
}
