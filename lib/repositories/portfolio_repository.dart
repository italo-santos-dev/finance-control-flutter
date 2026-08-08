import 'package:flutter_investment_control/models/asset_model.dart';
import 'package:flutter_investment_control/models/trade_transaction.dart';
import 'package:flutter_investment_control/models/transaction_model.dart';
import 'package:flutter_investment_control/repositories/transaction_repository.dart';

abstract class IPortfolioRepository {
  Future<List<Asset>> getPortfolioPositions();
  Future<Map<String, double>> getPortfolioMetrics();
}

class PortfolioRepository implements IPortfolioRepository {
  final TransactionRepository _transactionRepository;

  PortfolioRepository({TransactionRepository? transactionRepository})
      : _transactionRepository = transactionRepository ?? TransactionRepository();

  @override
  Future<List<Asset>> getPortfolioPositions() async {
    final allTrades = await _transactionRepository.getAllTransactions();
    Map<String, List<TradeTransaction>> grouped = {};

    for (var trade in allTrades) {
      grouped.putIfAbsent(trade.ticker, () => []).add(trade);
    }

    List<Asset> positions = [];

    for (var entry in grouped.entries) {
      String ticker = entry.key;
      List<TradeTransaction> trades = entry.value;

      double buyQty = 0;
      double sellQty = 0;
      double totalInvested = 0;
      String name = trades.first.name;
      String activeType = trades.first.activeType;
      String segment = trades.first.segment;

      for (var t in trades) {
        if (t.type == TransactionType.buy) {
          buyQty += t.quantity;
          totalInvested += (t.price * t.quantity) + t.fees;
        } else if (t.type == TransactionType.sell) {
          sellQty += t.quantity;
        }
      }

      double netQty = buyQty - sellQty;
      if (netQty < 0) netQty = 0;

      double avgPrice = (buyQty > 0) ? (totalInvested / buyQty) : 0.0;
      double currentPrice = trades.first.price; // default to latest known price

      positions.add(
        Asset(
          ticker: ticker,
          activeType: activeType.isNotEmpty ? activeType : 'Ação',
          segment: name.isNotEmpty ? name : segment,
          averagePrice: avgPrice > 0 ? avgPrice : currentPrice,
          currentPrice: currentPrice > 0 ? currentPrice : avgPrice,
          quantity: netQty.toInt(),
          transactions: trades.map((t) => t.toLegacyTransaction()).toList(),
          isFullyLiquidated: netQty <= 0,
        ),
      );
    }

    return positions;
  }

  @override
  Future<Map<String, double>> getPortfolioMetrics() async {
    final positions = await getPortfolioPositions();
    double totalEquity = 0.0;
    double totalCost = 0.0;

    for (var pos in positions) {
      if (!pos.isFullyLiquidated) {
        totalEquity += pos.totalAmount;
        totalCost += (pos.averagePrice * pos.quantity);
      }
    }

    double yieldPct = totalCost > 0 ? (((totalEquity - totalCost) / totalCost) * 100) : 0.0;

    return {
      'totalEquity': totalEquity,
      'totalCost': totalCost,
      'yieldPct': yieldPct,
    };
  }
}
