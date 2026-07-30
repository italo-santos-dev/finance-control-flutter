import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/core/app_icons.dart';
import 'package:flutter_investment_control/models/active_model.dart';
import 'package:flutter_investment_control/pages/active/details/active_details_page.dart';
import 'package:flutter_investment_control/pages/active/active_page.dart';
import 'package:flutter_investment_control/services/apis/api_brapi_get_logo.dart';
import 'package:flutter_investment_control/services/apis/api_stocks_ibovespa.dart';
import 'package:flutter_investment_control/widgets/adverts/adverts_widget.dart';
import 'package:flutter_investment_control/widgets/btc/chart_page.dart';
import 'package:flutter_investment_control/widgets/buttons/modern_cta_button.dart';
import 'package:flutter_investment_control/widgets/home/sparkline_painter.dart';
import 'package:flutter_investment_control/widgets/home/stock_ticker_widget.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Real data collections loaded from APIs
  List<Active> stockIndicators = [];
  List<Active> filteredStocks = [];

  List<Map<String, dynamic>> emAltaList = [];
  List<Map<String, dynamic>> emBaixaList = [];
  List<Map<String, dynamic>> maisNegociadosList = [];
  List<Map<String, dynamic>> globalMarketsList = [];
  List<Map<String, dynamic>> newsList = [];

  final List<Map<String, dynamic>> defaultNewsList = [
    {
      "badge": "MACROECONOMIA",
      "badgeColor": AppColors.primaryBlue,
      "source": "Valor Econômico • Há 2 horas",
      "title": "Fed mantém juros e sinaliza cautela para os próximos cortes no ano",
      "image": "https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?q=80&w=800&auto=format&fit=crop",
    },
    {
      "badge": "TECH & IA",
      "badgeColor": AppColors.emeraldGreen,
      "source": "Bloomberg • Há 4 horas",
      "title": "Nvidia supera estimativas e impulsiona rali global de semicondutores",
      "image": "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=800&auto=format&fit=crop",
    },
  ];

  final List<Map<String, dynamic>> courses = [
    {
      "icon": Icons.trending_up,
      "title": "Como funciona o CDI?",
      "subtitle": "Entenda o principal indicador de renda fixa...",
      "level": "Iniciante",
      "duration": "3 min",
    },
    {
      "icon": Icons.account_balance,
      "title": "Tesouro Direto na Prática",
      "subtitle": "Guia completo para investir em títulos públicos...",
      "level": "Iniciante",
      "duration": "5 min",
    },
  ];

  List<Active> selecionadas = [];
  String searchText = '';
  String selectedCategory = 'Todos';
  NumberFormat real = NumberFormat.currency(locale: 'pt-br', name: 'R\$');

  StockIbovespaApi api = StockIbovespaApi();
  ApiBrapiGetLogo apiBrapi = ApiBrapiGetLogo();

  InterstitialAd? _interstitialAd;

  bool isSearchActive = false;
  final FocusNode _searchFocusNode = FocusNode();

  final TextEditingController _searchController = TextEditingController();
  late Timer _timer;
  bool isLoading = true;

  void _toggleSearch() {
    setState(() {
      isSearchActive = !isSearchActive;
      if (isSearchActive) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
        searchText = '';
        filteredStocks = stockIndicators;
        _searchFocusNode.unfocus();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      _createInterstitialAd();
    });

    fetchData();
    fetchGlobalMarkets();
    fetchNews();
  }

  @override
  void dispose() {
    _timer.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Fetch stocks from real API
  fetchData() async {
    try {
      var data = await api.fetchStockIndicators();
      var logoUrls = await apiBrapi.fetchLogoUrls();

      List<Active> loaded = [];
      List<Map<String, dynamic>> emAltaTemp = [];
      List<Map<String, dynamic>> emBaixaTemp = [];
      List<Map<String, dynamic>> maisNegociadosTemp = [];

      for (var item in data) {
        double lastPrice = (item['lastPrice'] as num?)?.toDouble() ?? 0.0;
        double change = (item['change'] as num?)?.toDouble() ?? 0.0;
        double dy = (item['dividendYield'] as num?)?.toDouble() ?? 0.0;
        String symbol = (item['symbol'] as String?)?.trim() ?? '';
        String name = (item['name'] as String?)?.trim() ?? '';
        String sector = (item['sector'] as String?)?.trim() ?? '';

        // Ignore zeroed, unquoted or delisted stocks (price <= 0 or change <= -99%)
        if (lastPrice <= 0.0 || change <= -99.0 || symbol.isEmpty) {
          continue;
        }

        var assetDetails = logoUrls.firstWhere(
          (element) => element['ticker'] == symbol,
          orElse: () => {},
        );

        Active active = Active(
          icon: assetDetails.isNotEmpty ? assetDetails['logoUrl'] : AppIcons.btc,
          name: name,
          symbol: symbol,
          lastPrice: lastPrice,
          sector: sector,
          segment: item['segment'] ?? '',
          dividendYield: dy,
          lastYearHigh: (item['lastYearHigh'] as num?)?.toDouble() ?? 0.0,
          lastYearLow: (item['lastYearLow'] as num?)?.toDouble() ?? 0.0,
        );
        loaded.add(active);

        Map<String, dynamic> itemData = {
          "active": active,
          "symbol": symbol,
          "name": name,
          "sector": sector,
          "price": real.format(lastPrice),
          "rawPrice": lastPrice,
          "change": change >= 0 ? "+${change.toStringAsFixed(2)}%" : "${change.toStringAsFixed(2)}%",
          "rawChange": change,
          "isPositive": change >= 0,
        };

        if (change > 0) {
          emAltaTemp.add(itemData);
        } else if (change < 0) {
          emBaixaTemp.add(itemData);
        }
        maisNegociadosTemp.add(itemData);
      }

      // Sort Em Alta by highest positive change
      emAltaTemp.sort((a, b) => (b['rawChange'] as double).compareTo(a['rawChange'] as double));
      // Sort Em Baixa by lowest negative change
      emBaixaTemp.sort((a, b) => (a['rawChange'] as double).compareTo(b['rawChange'] as double));
      // Sort Mais Negociados by highest price/market volume
      maisNegociadosTemp.sort((a, b) => (b['rawPrice'] as double).compareTo(a['rawPrice'] as double));

      if (mounted) {
        setState(() {
          stockIndicators = loaded;
          filteredStocks = stockIndicators;
          emAltaList = emAltaTemp.take(3).toList();
          emBaixaList = emBaixaTemp.take(3).toList();
          maisNegociadosList = maisNegociadosTemp.take(3).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Fetch real market quotes (BTC/BRL, USD/BRL, EUR/BRL, GBP/BRL, ETH/BRL, CAD/BRL) via free open AwesomeAPI endpoint
  Future<void> fetchGlobalMarkets() async {
    try {
      final response = await http
          .get(Uri.parse('https://economia.awesomeapi.com.br/last/BTC-BRL,USD-BRL,EUR-BRL,GBP-BRL,ETH-BRL,CAD-BRL'))
          .timeout(const Duration(seconds: 8));

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
            "price": "R\$ ${real.format(price).replaceAll('R\$', '').trim()}",
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
            "price": "R\$ ${real.format(price).replaceAll('R\$', '').trim()}",
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

        if (mounted && markets.isNotEmpty) {
          setState(() {
            globalMarketsList = markets;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching global markets: $e');
    }
  }

  // Fetch real financial news
  Future<void> fetchNews() async {
    try {
      final response = await http.get(Uri.parse('https://brapi.dev/api/news?limit=4'));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final newsData = jsonData['news'] as List<dynamic>? ?? [];
        List<Map<String, dynamic>> loadedNews = [];

        for (int i = 0; i < newsData.length; i++) {
          var n = newsData[i];
          loadedNews.add({
            "badge": i % 2 == 0 ? "MACROECONOMIA" : "TECH & IA",
            "badgeColor": i % 2 == 0 ? AppColors.primaryBlue : AppColors.emeraldGreen,
            "source": "${n['source'] ?? 'Notícias'} • ${n['date'] ?? ''}",
            "title": n['title'] ?? '',
            "image": n['imageUrl'] ?? (i % 2 == 0 
                ? "https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?q=80&w=800&auto=format&fit=crop"
                : "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=800&auto=format&fit=crop"),
          });
        }

        if (mounted && loadedNews.isNotEmpty) {
          setState(() {
            newsList = loadedNews;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching news: $e');
    }
  }

  Widget _buildIcon(String? iconUrl) {
    double avatarSize = 36.0;

    if (iconUrl != null && iconUrl.isNotEmpty && iconUrl.endsWith('.svg')) {
      if (iconUrl == 'https://brapi.dev/favicon.svg') {
        return CircleAvatar(
          backgroundColor: const Color(0xFF1E2230),
          radius: avatarSize / 2.0,
          child: Image.asset(
            AppIcons.btc,
            height: avatarSize * 0.7,
            width: avatarSize * 0.7,
          ),
        );
      } else {
        return ClipOval(
          child: SvgPicture.network(
            iconUrl,
            placeholderBuilder: (_) => const CircularProgressIndicator(strokeWidth: 2),
            headers: const {'Accept': 'image/svg+xml'},
            height: avatarSize,
            width: avatarSize,
          ),
        );
      }
    } else {
      return CircleAvatar(
        backgroundColor: AppColors.chipDark,
        radius: avatarSize / 2.0,
        child: Image.asset(
          AppIcons.btc,
          height: avatarSize * 0.7,
          width: avatarSize * 0.7,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark, // Stitch dark theme background
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: searchText.isNotEmpty
                  ? _buildSearchResultsView()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        bool isDesktop = constraints.maxWidth > 800;

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 32.0 : 16.0,
                            vertical: 16.0,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeroBanner(),
                                  const SizedBox(height: 24),
                                  _buildSectionHeader('Mercados Globais', onSeeAll: () {}),
                                  const SizedBox(height: 12),
                                  _buildGlobalMarketsRow(),
                                  const SizedBox(height: 24),
                                  _buildCategoryFilters(),
                                  const SizedBox(height: 24),
                                  _buildMarketListsSection(isDesktop),
                                  const SizedBox(height: 24),
                                  _buildSectionHeaderWithIcon(Icons.newspaper_outlined, 'Radar Financeiro', onSeeAll: () {}),
                                  const SizedBox(height: 12),
                                  _buildNewsSection(isDesktop),
                                  const SizedBox(height: 24),
                                  _buildSectionHeaderWithIcon(Icons.school_outlined, 'Aprenda a Investir', onSeeAll: () {}),
                                  const SizedBox(height: 12),
                                  _buildLearningSection(isDesktop),
                                  const SizedBox(height: 24),
                                  _buildCallToActionBanner(isDesktop),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Interactive Search Results View
  Widget _buildSearchResultsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resultados da busca (${filteredStocks.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    searchText = '';
                    filteredStocks = stockIndicators;
                  });
                },
                icon: const Icon(Icons.close, size: 14, color: AppColors.blueAccent),
                label: const Text('Limpar busca', style: TextStyle(color: AppColors.blueAccent, fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredStocks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum ativo encontrado para "$searchText"',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredStocks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    Active active = filteredStocks[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: ListTile(
                        leading: _buildIcon(active.icon),
                        title: Text(
                          active.symbol,
                          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${active.name} • ${active.sector}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              real.format(active.lastPrice),
                              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'DY ${active.dividendYield.toStringAsFixed(2)}%',
                                style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          showDetails(active);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Header / Top Navigation Bar
  Widget _buildTopBar() {
    bool showSearchBar = isSearchActive || searchText.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: AppColors.headerDark,
        border: Border(
          bottom: BorderSide(color: AppColors.borderHeader, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Logo & Name (Logo height matches small 'worthy' font)
          Row(
            children: [
              Image.asset(
                AppIcons.logo_icon_02,
                height: 13,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 5),
              const Text(
                'worthy',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  letterSpacing: 0.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Conditional Search Input Bar or Spacer
          if (showSearchBar)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.inputDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.blueAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: (value) {
                          setState(() {
                            searchText = value.trim().toUpperCase();
                            filteredStocks = stockIndicators
                                .where((active) =>
                                    active.symbol.toUpperCase().contains(searchText) ||
                                    active.name.toUpperCase().contains(searchText) ||
                                    active.sector.toUpperCase().contains(searchText) ||
                                    active.segment.toUpperCase().contains(searchText))
                                .toList();
                          });
                        },
                        style: const TextStyle(color: AppColors.white, fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Buscar ativos ou relatórios...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleSearch,
                      child: const Icon(Icons.close, color: Colors.grey, size: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 8),
          // Notification Bell
          Stack(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.notifications_none, color: Colors.grey, size: 20),
                onPressed: () {},
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.emeraldGreen,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // User Profile Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.chipDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderMedium),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Operador',
                      style: TextStyle(fontSize: 10, color: AppColors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'CONTA PRO',
                      style: TextStyle(fontSize: 7, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                const CircleAvatar(
                  radius: 11,
                  backgroundColor: AppColors.primaryBlue,
                  child: Icon(Icons.person, size: 13, color: AppColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hero Welcome Banner
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.borderHero),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.rocket_launch_outlined, size: 12, color: AppColors.blueAccent),
                SizedBox(width: 6),
                Text(
                  'Bem-vindo ao worthy',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Comece sua jornada de\ninvestimentos.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Acompanhe o mercado, aprenda os fundamentos e construa seu portfólio com dados precisos em tempo real.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          StockTickerWidget(
            stocks: stockIndicators,
            onStockTap: (stock) => showDetails(stock),
          ),
        ],
      ),
    );
  }

  // Section Header Helper
  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(
            children: const [
              Text(
                'Ver todos ',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeaderWithIcon(IconData icon, String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(
            children: const [
              Text(
                'Ver todos ',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  // Mercados Globais Cards Row
  Widget _buildGlobalMarketsRow() {
    if (globalMarketsList.isEmpty) {
      return Shimmer.fromColors(
        baseColor: AppColors.cardDark,
        highlightColor: AppColors.borderInput,
        child: Row(
          children: List.generate(
            6,
            (_) => Expanded(
              child: Container(
                height: 80,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 850;

        if (isWide) {
          return Row(
            children: globalMarketsList.asMap().entries.map((entry) {
              int idx = entry.key;
              var market = entry.value;
              bool isLast = idx == globalMarketsList.length - 1;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 10.0),
                  child: _buildGlobalMarketCard(market),
                ),
              );
            }).toList(),
          );
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: globalMarketsList.map((market) {
                return Container(
                  width: 170,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildGlobalMarketCard(market),
                );
              }).toList(),
            ),
          );
        }
      },
    );
  }

  Widget _buildGlobalMarketCard(Map<String, dynamic> market) {
    bool isPositive = market['isPositive'] ?? true;
    Color color = isPositive ? AppColors.emeraldGreen : AppColors.redLoss;
    List<double> points = List<double>.from(market['points']);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.symbolDark,
                      child: Text(
                        market['symbol'][0],
                        style: const TextStyle(fontSize: 10, color: AppColors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            market['symbol'],
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            market['name'],
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  market['change'],
                  style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  market['price'],
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 40,
                height: 20,
                child: CustomPaint(
                  painter: SparklinePainter(data: points, color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Category Quick Filter Cards
  Widget _buildCategoryFilters() {
    final categories = [
      {"icon": Icons.business_outlined, "label": "Ações"},
      {"icon": Icons.apartment_outlined, "label": "FIIs"},
      {"icon": FontAwesomeIcons.bitcoin, "label": "Cripto"},
      {"icon": Icons.public_outlined, "label": "Global"},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((cat) {
        bool isSelected = selectedCategory == cat['label'];

        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (cat['label'] == 'Cripto') {
                navigateToBtcPage();
              } else {
                setState(() {
                  selectedCategory = cat['label'] as String;
                });
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.2) : AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : AppColors.borderDark,
                ),
              ),
              child: Column(
                children: [
                  cat['icon'] is IconData
                      ? Icon(cat['icon'] as IconData, size: 20, color: isSelected ? AppColors.blueAccent : Colors.grey)
                      : FaIcon(cat['icon'] as FaIconData, size: 18, color: isSelected ? AppColors.blueAccent : Colors.grey),
                  const SizedBox(height: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.white : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Responsive Market Lists Section (Em Alta, Em Baixa, Mais Negociados)
  Widget _buildMarketListsSection(bool isDesktop) {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildListCardColumn('Em Alta Hoje', Icons.local_fire_department_outlined, AppColors.fireRed, emAltaList)),
          const SizedBox(width: 16),
          Expanded(child: _buildListCardColumn('Em Baixa Hoje', Icons.trending_down_outlined, AppColors.redLoss, emBaixaList)),
          const SizedBox(width: 16),
          Expanded(child: _buildListCardColumn('Mais Negociados', Icons.swap_vert_outlined, AppColors.blueAccent, maisNegociadosList)),
        ],
      );
    } else {
      return Column(
        children: [
          _buildListCardColumn('Em Alta Hoje', Icons.local_fire_department_outlined, AppColors.fireRed, emAltaList),
          const SizedBox(height: 12),
          _buildListCardColumn('Em Baixa Hoje', Icons.trending_down_outlined, AppColors.redLoss, emBaixaList),
          const SizedBox(height: 12),
          _buildListCardColumn('Mais Negociados', Icons.swap_vert_outlined, AppColors.blueAccent, maisNegociadosList),
        ],
      );
    }
  }

  Widget _buildListCardColumn(String title, IconData icon, Color iconColor, List<Map<String, dynamic>> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4),
            child: Row(
              children: [
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.white),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Sem dados no momento',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            )
          else
            ...items.map((item) {
              bool isPositive = item['isPositive'] ?? true;
              Color changeColor = isPositive ? AppColors.emeraldGreen : AppColors.redLoss;
              Active? active = item['active'] as Active?;

              return InkWell(
                onTap: () {
                  if (active != null) showDetails(active);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.avatarDark,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item['symbol'].substring(0, math.min(4, (item['symbol'] as String).length)),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item['sector'],
                              style: const TextStyle(fontSize: 9, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item['price'],
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white),
                          ),
                          Text(
                            item['change'],
                            style: TextStyle(fontSize: 10, color: changeColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  // Radar Financeiro (News Cards)
  Widget _buildNewsSection(bool isDesktop) {
    List<Map<String, dynamic>> listToDisplay = newsList.isNotEmpty ? newsList : defaultNewsList;

    if (isDesktop) {
      return Row(
        children: listToDisplay.take(2).map((item) {
          return Expanded(
            child: Container(
              height: 190,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                image: DecorationImage(
                  image: NetworkImage(item['image']),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.92),
                      Colors.black.withValues(alpha: 0.3),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item['badgeColor'] ?? AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['badge'] ?? 'NOTÍCIA',
                        style: const TextStyle(fontSize: 10, color: AppColors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['source'] ?? '',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return SizedBox(
        height: 190,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: listToDisplay.length,
          itemBuilder: (context, index) {
            var item = listToDisplay[index];

            return Container(
              width: MediaQuery.of(context).size.width * 0.8,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                image: DecorationImage(
                  image: NetworkImage(item['image']),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.92),
                      Colors.black.withOpacity(0.3),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item['badgeColor'] ?? const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['badge'] ?? 'NOTÍCIA',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['title'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['source'] ?? '',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }

  // Learning Section
  Widget _buildLearningSection(bool isDesktop) {
    if (isDesktop) {
      return Row(
        children: courses.map((course) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.avatarDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(course['icon'] as IconData, color: AppColors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['title'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          course['subtitle'] as String,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.borderMedium,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          course['level'] as String,
                          style: const TextStyle(fontSize: 8, color: AppColors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course['duration'] as String,
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    } else {
      return Column(
        children: courses.map((course) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.avatarDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(course['icon'] as IconData, color: AppColors.blueAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'] as String,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        course['subtitle'] as String,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.borderMedium,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        course['level'] as String,
                        style: const TextStyle(fontSize: 8, color: AppColors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['duration'] as String,
                      style: const TextStyle(fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    }
  }

  // Call to Action Banner (Bottom)
  Widget _buildCallToActionBanner(bool isDesktop) {
    Widget textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pronto para dar o primeiro passo?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Monte sua carteira teórica, acompanhe o desempenho e teste suas estratégias sem risco.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[400],
            height: 1.4,
          ),
        ),
      ],
    );

    Widget actionButton = ModernCtaButton(
      onPressed: navigateToWalletPage,
      isDesktop: isDesktop,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bannerDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: textColumn),
                const SizedBox(width: 24),
                actionButton,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textColumn,
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: actionButton),
              ],
            ),
    );
  }

  // Loading Screen (Shimmer)
  Widget _buildLoadingScreen() {
    return Shimmer.fromColors(
      baseColor: AppColors.cardDark,
      highlightColor: AppColors.borderInput,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    bool isSearchOpen = isSearchActive || searchText.isNotEmpty;

    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: AppColors.headerDark,
        border: Border(
          top: BorderSide(color: AppColors.borderHeader, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(FontAwesomeIcons.borderAll, 'Dashboard', !isSearchOpen, () {
            if (isSearchOpen) _toggleSearch();
          }),
          _buildNavItem(Icons.search, 'Buscar', isSearchOpen, _toggleSearch),
          _buildNavItem(FontAwesomeIcons.wallet, 'Carteira', false, navigateToWalletPage),
          _buildNavItem(FontAwesomeIcons.newspaper, 'Notícias', false, navigateToWalletPage),
          _buildNavItem(FontAwesomeIcons.chartLine, 'Gráfico', false, navigateToBtcPage),
        ],
      ),
    );
  }

  Widget _buildNavItem(dynamic icon, String label, bool isActive, VoidCallback onTap) {
    Color color = isActive ? AppColors.primaryBlue : Colors.grey;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon is IconData
              ? Icon(icon, size: 18, color: color)
              : FaIcon(icon as FaIconData, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Navigation & Ad Handlers
  showDetails(Active active) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveDetailsPage(active: active),
      ),
    );
  }

  navigateToBtcPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChartPage(ticker: 'SANB11'),
      ),
    );
  }

  void navigateToWalletPage() {
    _showInterstitialAd(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AssetList()),
      );
    });
  }

  void _createInterstitialAd() {
    try {
      InterstitialAd.load(
        adUnitId: 'ca-app-pub-3940256099942544/1033173712',
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('$ad loaded.');
            _interstitialAd = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
      _interstitialAd = null;
    }
  }

  void _showInterstitialAd(OnAdClosedCallback onAdClosed) {
    if (_interstitialAd == null) {
      debugPrint('Anúncio null');
      onAdClosed();
      return;
    }

    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _interstitialAd = null;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _interstitialAd = null;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        onAdClosed();
      },
      onAdImpression: (InterstitialAd ad) => debugPrint('$ad impression occurred.'),
    );

    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoadingScreen(onAdClosed: onAdClosed)),
      );

      _interstitialAd?.show();
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      _interstitialAd = null;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      onAdClosed();
    }
  }
}
