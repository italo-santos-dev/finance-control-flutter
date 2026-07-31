import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Data Model representing a 100% International Global Asset Item
class GlobalStockItem {
  final String symbol;
  final String name;
  final String logoUrl;
  final double price;
  final double changePct;
  final double volume;
  final bool isPositive;
  final List<double> points;

  GlobalStockItem({
    required this.symbol,
    required this.name,
    required this.logoUrl,
    required this.price,
    required this.changePct,
    required this.volume,
    required this.isPositive,
    required this.points,
  });

  String get formattedPrice => '\$ ${price.toStringAsFixed(2)}';
  String get formattedChange =>
      isPositive ? '+${changePct.toStringAsFixed(2)}%' : '${changePct.toStringAsFixed(2)}%';

  String get formattedVolume {
    if (volume >= 1e9) {
      return 'Vol. \$${(volume / 1e9).toStringAsFixed(1)}B';
    } else if (volume >= 1e6) {
      return 'Vol. \$${(volume / 1e6).toStringAsFixed(1)}M';
    } else if (volume >= 1e3) {
      return 'Vol. \$${(volume / 1e3).toStringAsFixed(1)}K';
    } else {
      return 'Vol. \$${volume.toStringAsFixed(0)}';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      "symbol": symbol,
      "name": name,
      "sector": "Mercado Global",
      "price": formattedPrice,
      "rawPrice": price,
      "change": formattedChange,
      "rawChange": changePct,
      "isPositive": isPositive,
      "volumeStr": formattedVolume,
      "rawVolume": volume,
      "logoUrl": logoUrl,
      "points": points,
    };
  }
}

/// Data Repository for 100% International Assets ONLY (Excludes Brazilian Domestic Stocks)
class GlobalStocksRepository {
  static final GlobalStocksRepository _instance = GlobalStocksRepository._internal();
  factory GlobalStocksRepository() => _instance;
  GlobalStocksRepository._internal();

  // Smart In-Memory Cache
  Map<String, List<Map<String, dynamic>>>? _cachedResult;
  DateTime? _lastCacheTime;
  static const Duration _cacheDuration = Duration(seconds: 45);

  /// Fetch processed global market cards strictly containing 100% International Assets
  Future<Map<String, List<Map<String, dynamic>>>> getProcessedGlobalMarketCards() async {
    if (_cachedResult != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < _cacheDuration) {
      return _cachedResult!;
    }

    List<GlobalStockItem> items = [];

    // 1. Fetch international BDRs & global stocks from mFinance API
    items = await _fetchFromMfinance();

    // 2. Fetch international BDRs & global stocks from BRAPI if empty
    if (items.isEmpty) {
      items = await _fetchFromBrapiList();
    }

    // 3. Fetch international BDRs & global stocks from Investidor10 Web Scraper if empty
    if (items.isEmpty) {
      items = await _scrapeFromInvestidor10();
    }

    // 4. Fetch AwesomeAPI global currencies & cryptos if empty
    if (items.isEmpty) {
      items = await _fetchFromAwesomeApi();
    }

    if (items.isNotEmpty) {
      final processed = _categorizeAndSortEntireUniverse(items);
      _cachedResult = processed;
      _lastCacheTime = DateTime.now();
      return processed;
    }

    if (_cachedResult != null) {
      return _cachedResult!;
    }

    return {
      "emAlta": [],
      "emBaixa": [],
      "maisNegociados": [],
      "horizontalMarkets": [],
    };
  }

  /// Strict filter ensuring ONLY international assets are processed (Excludes Brazilian domestic stocks)
  bool _isStrictlyInternational(String symbol, String sector) {
    String sym = symbol.toUpperCase().trim();

    // Exclude Brazilian domestic stocks (ending in 3, 4, 11) and Ibovespa
    if (sym == 'IBOV' ||
        sym == 'IBOVESPA' ||
        (RegExp(r'\d$').hasMatch(sym) &&
            !sym.endsWith('34') &&
            !sym.endsWith('35') &&
            !sym.endsWith('39'))) {
      return false;
    }

    // Include BDRs of international companies (ending in 34, 35, 39)
    if (sym.endsWith('34') || sym.endsWith('35') || sym.endsWith('39')) {
      return true;
    }

    // Include pure US/International Tickers (e.g. AAPL, NVDA, MSFT, TSLA, PLTR)
    if (RegExp(r'^[A-Z]{1,5}$').hasMatch(sym)) {
      return true;
    }

    // Include currency/crypto pairs (e.g. USD/BRL, EUR/BRL, BTC/BRL)
    if (sym.contains('/')) {
      return true;
    }

    return false;
  }

  /// Dynamic fetcher processing mFinance API for international assets only
  Future<List<GlobalStockItem>> _fetchFromMfinance() async {
    List<GlobalStockItem> items = [];
    try {
      final response = await http
          .get(Uri.parse('https://mfinance.com.br/api/v1/stocks'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stocksList = data['stocks'] as List<dynamic>? ?? [];

        for (var item in stocksList) {
          String symbol = (item['symbol'] as String?)?.toUpperCase().trim() ?? '';
          String sector = (item['segment'] ?? item['sector'] ?? '').toString();
          if (symbol.isEmpty) continue;

          // Strictly filter for International Assets ONLY
          if (_isStrictlyInternational(symbol, sector)) {
            String name = (item['name'] as String?)?.trim() ?? symbol;
            double price = (item['lastPrice'] as num?)?.toDouble() ?? 0.0;
            double changePct = (item['change'] as num?)?.toDouble() ?? 0.0;
            double volume = (item['volume'] as num?)?.toDouble() ?? 0.0;

            if (price > 0) {
              bool isPositive = changePct >= 0;
              String cleanTicker = _extractCleanTicker(symbol, name);
              String domain = _guessDomain(cleanTicker, name);

              items.add(GlobalStockItem(
                symbol: cleanTicker,
                name: name,
                logoUrl: 'https://logo.clearbit.com/$domain',
                price: price,
                changePct: changePct,
                volume: volume > 0 ? volume : (price * 25000),
                isPositive: isPositive,
                points: [price * (1 - (changePct * 0.003)), price],
              ));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching mFinance international universe: $e');
    }
    return items;
  }

  /// Dynamic fetcher querying BRAPI for international assets only
  Future<List<GlobalStockItem>> _fetchFromBrapiList() async {
    List<GlobalStockItem> items = [];
    try {
      final response = await http
          .get(Uri.parse('https://brapi.dev/api/quote/list'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stocksList = data['stocks'] as List<dynamic>? ?? [];

        for (var item in stocksList) {
          String symbol = (item['stock'] as String?)?.toUpperCase().trim() ?? '';
          String sector = (item['sector'] as String?) ?? '';
          if (symbol.isEmpty) continue;

          if (_isStrictlyInternational(symbol, sector)) {
            String name = (item['name'] as String?)?.trim() ?? symbol;
            double price = (item['close'] as num?)?.toDouble() ?? (item['price'] as num?)?.toDouble() ?? 0.0;
            double changePct = (item['change'] as num?)?.toDouble() ?? 0.0;
            double volume = (item['volume'] as num?)?.toDouble() ?? 0.0;
            String logoUrl = (item['logo'] as String?) ?? '';

            if (price > 0) {
              bool isPositive = changePct >= 0;
              String cleanTicker = _extractCleanTicker(symbol, name);

              if (logoUrl.isEmpty) {
                String domain = _guessDomain(cleanTicker, name);
                logoUrl = 'https://logo.clearbit.com/$domain';
              }

              items.add(GlobalStockItem(
                symbol: cleanTicker,
                name: name,
                logoUrl: logoUrl,
                price: price,
                changePct: changePct,
                volume: volume > 0 ? volume : (price * 10000),
                isPositive: isPositive,
                points: [price * (1 - (changePct * 0.002)), price],
              ));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching BRAPI quote list: $e');
    }
    return items;
  }

  /// Web Scraper extracting international tickers dynamically
  Future<List<GlobalStockItem>> _scrapeFromInvestidor10() async {
    List<GlobalStockItem> items = [];
    try {
      final response = await http
          .get(
            Uri.parse('https://investidor10.com.br/bdrs/'),
            headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        String html = response.body;

        RegExp rowRegExp = RegExp(r'href="/bdrs/([^/]+)/"[\s\S]*?class="name">([^<]+)<[\s\S]*?R\$\s*([\d\.,]+)', caseSensitive: false);
        Iterable<RegExpMatch> matches = rowRegExp.allMatches(html);

        for (var match in matches) {
          String rawTicker = match.group(1)?.toUpperCase().trim() ?? '';
          String name = match.group(2)?.trim() ?? rawTicker;
          String priceStr = match.group(3)?.replaceAll('.', '').replaceAll(',', '.') ?? '0';
          double price = double.tryParse(priceStr) ?? 0.0;

          if (rawTicker.isNotEmpty && price > 0 && _isStrictlyInternational(rawTicker, '')) {
            String cleanTicker = _extractCleanTicker(rawTicker, name);
            String domain = _guessDomain(cleanTicker, name);

            items.add(GlobalStockItem(
              symbol: cleanTicker,
              name: name,
              logoUrl: 'https://logo.clearbit.com/$domain',
              price: price,
              changePct: 0.0,
              volume: 500000,
              isPositive: true,
              points: [price, price],
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Investidor10 scraper error: $e');
    }
    return items;
  }

  /// Dynamic fetcher using AwesomeAPI global market exchange rates
  Future<List<GlobalStockItem>> _fetchFromAwesomeApi() async {
    List<GlobalStockItem> items = [];
    try {
      final response = await http
          .get(Uri.parse('https://economia.awesomeapi.com.br/last/USD-BRL,EUR-BRL,BTC-BRL,ETH-BRL,GBP-BRL,CAD-BRL'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        data.forEach((key, item) {
          String code = (item['code'] as String?) ?? '';
          String name = (item['name'] as String?) ?? code;
          double price = double.tryParse((item['bid'] ?? '0').toString()) ?? 0.0;
          double changePct = double.tryParse((item['pctChange'] ?? '0').toString()) ?? 0.0;

          if (price > 0) {
            items.add(GlobalStockItem(
              symbol: '$code/BRL',
              name: name,
              logoUrl: '',
              price: price,
              changePct: changePct,
              volume: price * 500000,
              isPositive: changePct >= 0,
              points: [price * (1 - (changePct * 0.002)), price],
            ));
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching AwesomeAPI fallback: $e');
    }
    return items;
  }

  /// Derives US Ticker symbol from BDR symbol
  String _extractCleanTicker(String symbol, String name) {
    if (symbol.endsWith('34') || symbol.endsWith('35') || symbol.endsWith('39')) {
      String base = symbol.substring(0, symbol.length - 2);
      if (base == 'NVDC') return 'NVDA';
      if (base == 'AMZO') return 'AMZN';
      if (base == 'GOGL') return 'GOOGL';
      if (base == 'M1TA') return 'META';
      if (base == 'P2LT') return 'PLTR';
      if (base == 'C2OI') return 'COIN';
      if (base == 'S2NW') return 'SNOW';
      if (base == 'S1HO') return 'SHOP';
      if (base == 'U1BE') return 'UBER';
      if (base == 'I1NT') return 'INTC';
      if (base == 'A1MD') return 'AMD';
      if (base == 'R1OK') return 'ROKU';
      if (base == 'U1NI') return 'UNITY';
      if (base == 'R1IV') return 'RIVN';
      return base;
    }
    return symbol;
  }

  /// Guess corporate domain for logo fetching dynamically
  String _guessDomain(String ticker, String name) {
    String t = ticker.toLowerCase();
    if (t == 'nvda') return 'nvidia.com';
    if (t == 'aapl') return 'apple.com';
    if (t == 'msft') return 'microsoft.com';
    if (t == 'amzn') return 'amazon.com';
    if (t == 'googl' || t == 'goog') return 'google.com';
    if (t == 'meta') return 'meta.com';
    if (t == 'tsla') return 'tesla.com';
    if (t == 'pltr') return 'palantir.com';
    if (t == 'coin') return 'coinbase.com';
    if (t == 'snow') return 'snowflake.com';
    if (t == 'orcl') return 'oracle.com';
    if (t == 'intc') return 'intel.com';
    if (t == 'nflx') return 'netflix.com';
    if (t == 'amd') return 'amd.com';
    if (t == 'shop') return 'shopify.com';
    if (t == 'uber') return 'uber.com';
    if (t == 'roku') return 'roku.com';
    if (t == 'rivn') return 'rivian.com';
    if (t == 'hood') return 'robinhood.com';

    String clean = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (clean.isNotEmpty && clean.length > 3) return '$clean.com';
    return '$t.com';
  }

  /// Sorts 100% International Assets dynamically for Em Alta, Em Baixa, and Mais Negociados
  Map<String, List<Map<String, dynamic>>> _categorizeAndSortEntireUniverse(List<GlobalStockItem> items) {
    Map<String, GlobalStockItem> uniqueMap = {};
    for (var item in items) {
      uniqueMap[item.symbol] = item;
    }
    List<GlobalStockItem> uniqueList = uniqueMap.values.toList();

    List<GlobalStockItem> altaList = uniqueList.where((s) => s.changePct >= 0).toList();
    if (altaList.isEmpty) altaList = List.from(uniqueList);
    altaList.sort((a, b) => b.changePct.compareTo(a.changePct));

    List<GlobalStockItem> baixaList = uniqueList.where((s) => s.changePct < 0).toList();
    if (baixaList.isEmpty) baixaList = List.from(uniqueList);
    baixaList.sort((a, b) => a.changePct.compareTo(b.changePct));

    List<GlobalStockItem> negociadosList = List.from(uniqueList);
    negociadosList.sort((a, b) => b.volume.compareTo(a.volume));

    return {
      "emAlta": altaList.take(3).map((s) => s.toMap()).toList(),
      "emBaixa": baixaList.take(3).map((s) => s.toMap()).toList(),
      "maisNegociados": negociadosList.take(3).map((s) => s.toMap()).toList(),
      "horizontalMarkets": uniqueList.take(6).map((s) => s.toMap()).toList(),
    };
  }
}
