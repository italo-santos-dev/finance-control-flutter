import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// Clean service for AwesomeAPI (100% Free, no token required for live rates & crypto)
class AwesomeMarketsApi {
  final String _endpoint = 'https://economia.awesomeapi.com.br/last/BTC-BRL,USD-BRL,EUR-BRL,GBP-BRL,ETH-BRL,CAD-BRL';
  final NumberFormat _realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');

  Future<List<Map<String, dynamic>>> fetchGlobalMarkets() async {
    try {
      final response = await http.get(Uri.parse(_endpoint)).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        List<Map<String, dynamic>> markets = [];

        // 1. BTC / BRL
        if (jsonData.containsKey('BTCBRL')) {
          var btc = jsonData['BTCBRL'];
          double price = double.tryParse(btc['bid'].toString()) ?? 0.0;
          double change = double.tryParse(btc['pctChange'].toString()) ?? 0.0;
          bool isPositive = change >= 0;

          markets.add({
            "symbol": "BTC/BRL",
            "name": "Bitcoin",
            "price": "R\$ ${_realFormat.format(price).replaceAll('R\$', '').trim()}",
            "change": change >= 0 ? "+${change.toStringAsFixed(2)}%" : "${change.toStringAsFixed(2)}%",
            "isPositive": isPositive,
            "points": [price * 0.98, price * 0.99, price * 1.005, price],
          });
        }

        // 2. USD / BRL (Dólar)
        if (jsonData.containsKey('USDBRL')) {
          var usd = jsonData['USDBRL'];
          double price = double.tryParse(usd['bid'].toString()) ?? 0.0;
          double change = double.tryParse(usd['pctChange'].toString()) ?? 0.0;
          bool isPositive = change >= 0;

          markets.add({
            "symbol": "USD/BRL",
            "name": "Dólar Comercial",
            "price": "R\$ ${price.toStringAsFixed(2)}",
            "change": change >= 0 ? "+${change.toStringAsFixed(2)}%" : "${change.toStringAsFixed(2)}%",
            "isPositive": isPositive,
            "points": [price * 0.99, price * 0.995, price * 1.002, price],
          });
        }

        // 3. EUR / BRL (Euro)
        if (jsonData.containsKey('EURBRL')) {
          var eur = jsonData['EURBRL'];
          double price = double.tryParse(eur['bid'].toString()) ?? 0.0;
          double change = double.tryParse(eur['pctChange'].toString()) ?? 0.0;
          bool isPositive = change >= 0;

          markets.add({
            "symbol": "EUR/BRL",
            "name": "Euro",
            "price": "R\$ ${price.toStringAsFixed(2)}",
            "change": change >= 0 ? "+${change.toStringAsFixed(2)}%" : "${change.toStringAsFixed(2)}%",
            "isPositive": isPositive,
            "points": [price * 0.99, price * 0.996, price * 1.001, price],
          });
        }

        // 4. GBP / BRL (Libra Esterlina)
        if (jsonData.containsKey('GBPBRL')) {
          var gbp = jsonData['GBPBRL'];
          double price = double.tryParse(gbp['bid'].toString()) ?? 0.0;
          double change = double.tryParse(gbp['pctChange'].toString()) ?? 0.0;
          bool isPositive = change >= 0;

          markets.add({
            "symbol": "GBP/BRL",
            "name": "Libra Esterlina",
            "price": "R\$ ${price.toStringAsFixed(2)}",
            "change": change >= 0 ? "+${change.toStringAsFixed(2)}%" : "${change.toStringAsFixed(2)}%",
            "isPositive": isPositive,
            "points": [price * 0.985, price * 0.992, price * 1.003, price],
          });
        }

        // 5. ETH / BRL (Ethereum)
        if (jsonData.containsKey('ETHBRL')) {
          var eth = jsonData['ETHBRL'];
          double price = double.tryParse(eth['bid'].toString()) ?? 0.0;
          double change = double.tryParse(eth['pctChange'].toString()) ?? 0.0;
          bool isPositive = change >= 0;

          markets.add({
            "symbol": "ETH/BRL",
            "name": "Ethereum",
            "price": "R\$ ${_realFormat.format(price).replaceAll('R\$', '').trim()}",
            "change": change >= 0 ? "+${change.toStringAsFixed(2)}%" : "${change.toStringAsFixed(2)}%",
            "isPositive": isPositive,
            "points": [price * 0.97, price * 0.995, price * 1.01, price],
          });
        }

        // 6. CAD / BRL (Dólar Canadense)
        if (jsonData.containsKey('CADBRL')) {
          var cad = jsonData['CADBRL'];
          double price = double.tryParse(cad['bid'].toString()) ?? 0.0;
          double change = double.tryParse(cad['pctChange'].toString()) ?? 0.0;
          bool isPositive = change >= 0;

          markets.add({
            "symbol": "CAD/BRL",
            "name": "Dólar Canadense",
            "price": "R\$ ${price.toStringAsFixed(2)}",
            "change": change >= 0 ? "+${change.toStringAsFixed(2)}%" : "${change.toStringAsFixed(2)}%",
            "isPositive": isPositive,
            "points": [price * 0.99, price * 0.994, price * 1.002, price],
          });
        }

        return markets;
      }
    } catch (e) {
      debugPrint('Error fetching AwesomeAPI markets: $e');
    }
    return [];
  }
}
