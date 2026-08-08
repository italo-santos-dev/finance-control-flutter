import 'package:flutter_investment_control/models/transaction_model.dart';

class TradeTransaction {
  final String id;
  final String ticker;
  final String name;
  final TransactionType type;
  final double quantity;
  final double price;
  final double fees;
  final double total;
  final DateTime date;
  final String broker;
  final String activeType;
  final String segment;
  final DateTime createdAt;

  TradeTransaction({
    required this.id,
    required this.ticker,
    required this.name,
    required this.type,
    required this.quantity,
    required this.price,
    this.fees = 0.0,
    required this.total,
    required this.date,
    required this.broker,
    this.activeType = 'Ação',
    this.segment = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticker': ticker.toUpperCase().trim(),
      'name': name.trim(),
      'type': type == TransactionType.buy ? 'BUY' : (type == TransactionType.sell ? 'SELL' : 'DIVIDEND'),
      'quantity': quantity,
      'price': price,
      'fees': fees,
      'total': total,
      'date': date.toIso8601String(),
      'broker': broker.trim(),
      'active_type': activeType,
      'segment': segment.trim(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TradeTransaction.fromMap(Map<String, dynamic> map) {
    String typeStr = (map['type'] ?? 'BUY').toString().toUpperCase();
    TransactionType tType = TransactionType.buy;
    if (typeStr == 'SELL' || typeStr == 'VENDA') {
      tType = TransactionType.sell;
    }

    return TradeTransaction(
      id: (map['id'] ?? '').toString(),
      ticker: (map['ticker'] ?? '').toString().toUpperCase(),
      name: (map['name'] ?? map['ticker'] ?? '').toString(),
      type: tType,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      fees: (map['fees'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse((map['date'] ?? '').toString()) ?? DateTime.now(),
      broker: (map['broker'] ?? 'Sua Instituição').toString(),
      activeType: (map['active_type'] ?? 'Ação').toString(),
      segment: (map['segment'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  // Convert to existing legacy Transaction model for backward compatibility
  Transaction toLegacyTransaction() {
    return Transaction(
      date: date,
      ticker: ticker,
      type: type,
      market: 'B3',
      maturityDate: date.add(const Duration(days: 365)),
      institution: broker,
      tradingCode: ticker,
      quantity: quantity.toInt(),
      price: price,
      amount: total,
    );
  }
}
