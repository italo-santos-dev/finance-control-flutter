import 'package:flutter/material.dart';
import 'package:flutter_investment_control/models/asset_model.dart';
import 'package:flutter_investment_control/models/trade_transaction.dart';
import 'package:flutter_investment_control/models/transaction_model.dart';
import 'package:flutter_investment_control/repositories/portfolio_repository.dart';
import 'package:flutter_investment_control/repositories/transaction_repository.dart';
import 'package:provider/provider.dart';

class AssetProvider extends ChangeNotifier {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final PortfolioRepository _portfolioRepo = PortfolioRepository();

  List<Asset> _assets = [];
  List<TradeTransaction> _transactions = [];
  bool _isLoading = false;

  List<Asset> get assets => _assets;
  List<TradeTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  Asset? selectedAsset;

  AssetProvider() {
    loadPortfolio();
  }

  Future<void> loadPortfolio() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Seed default transactions if local SQLite database is brand new
      await _transactionRepo.seedInitialTransactionsIfEmpty([
        TradeTransaction(
          id: 'initial-itub4',
          ticker: 'ITUB4',
          name: 'Itaú Unibanco Holding S.A.',
          type: TransactionType.buy,
          quantity: 1500,
          price: 28.50,
          total: 42750.00,
          date: DateTime.now().subtract(const Duration(days: 28, hours: 2)),
          broker: 'XP Investimentos',
          activeType: 'Ação',
          segment: 'Itaú Unibanco',
          createdAt: DateTime.now().subtract(const Duration(days: 28)),
        ),
        TradeTransaction(
          id: 'initial-hglg11',
          ticker: 'HGLG11',
          name: 'CSHG Logística FII',
          type: TransactionType.buy,
          quantity: 350,
          price: 160.00,
          total: 56000.00,
          date: DateTime.now().subtract(const Duration(days: 20, hours: 4)),
          broker: 'Banco Inter',
          activeType: 'FII',
          segment: 'CSHG Logística',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
        TradeTransaction(
          id: 'initial-wege3',
          ticker: 'WEGE3',
          name: 'WEG S.A.',
          type: TransactionType.buy,
          quantity: 800,
          price: 32.00,
          total: 25600.00,
          date: DateTime.now().subtract(const Duration(days: 14, hours: 1)),
          broker: 'BTG Pactual',
          activeType: 'Ação',
          segment: 'WEG S.A.',
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
        ),
        TradeTransaction(
          id: 'initial-vale3',
          ticker: 'VALE3',
          name: 'Vale S.A.',
          type: TransactionType.buy,
          quantity: 500,
          price: 62.00,
          total: 31000.00,
          date: DateTime.now().subtract(const Duration(days: 8, hours: 3)),
          broker: 'NuInvest',
          activeType: 'Ação',
          segment: 'Vale S.A.',
          createdAt: DateTime.now().subtract(const Duration(days: 8)),
        ),
        TradeTransaction(
          id: 'initial-sanb11',
          ticker: 'SANB11',
          name: 'Banco Santander Brasil S.A.',
          type: TransactionType.buy,
          quantity: 1000,
          price: 29.27,
          total: 29270.00,
          date: DateTime.now().subtract(const Duration(days: 4, hours: 5)),
          broker: 'XP Investimentos',
          activeType: 'Ação',
          segment: 'Santander BR',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ]);

      _transactions = await _transactionRepo.getAllTransactions();
      _assets = await _portfolioRepo.getPortfolioPositions();
    } catch (e) {
      debugPrint('Error loading SQLite portfolio: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTradeTransaction(TradeTransaction trade) async {
    try {
      await _transactionRepo.createTransaction(trade);
      _transactions = await _transactionRepo.getAllTransactions();
      _assets = await _portfolioRepo.getPortfolioPositions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding trade transaction to SQLite: $e');
    }
  }

  void updateAssets(List<Asset> newAssets) {
    _assets = List.from(newAssets);
    notifyListeners();
  }

  Future<void> removeAsset(Asset asset) async {
    try {
      _assets.removeWhere((a) => a.ticker == asset.ticker);
      // Remove all transactions associated with this asset ticker
      final trades = await _transactionRepo.getTransactionsByTicker(asset.ticker);
      for (var t in trades) {
        await _transactionRepo.deleteTransaction(t.id);
      }
      _transactions = await _transactionRepo.getAllTransactions();
      _assets = await _portfolioRepo.getPortfolioPositions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing asset from SQLite: $e');
    }
  }

  static AssetProvider of(BuildContext context, {bool listen = false}) {
    return Provider.of<AssetProvider>(context, listen: listen);
  }
}
