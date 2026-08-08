import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/core/app_icons.dart';
import 'package:flutter_investment_control/models/active_model.dart';
import 'package:flutter_investment_control/pages/active/details/active_details_page.dart';
import 'package:flutter_investment_control/pages/news/news_detail_page.dart';
import 'package:flutter_investment_control/services/apis/api_awesome_markets.dart';
import 'package:flutter_investment_control/services/apis/api_brapi_get_logo.dart';
import 'package:flutter_investment_control/services/apis/api_news_service.dart';
import 'package:flutter_investment_control/services/apis/api_stocks_ibovespa.dart';
import 'package:flutter_investment_control/services/apis/global_stocks_service.dart';
import 'package:flutter_investment_control/widgets/adverts/adverts_widget.dart';
import 'package:flutter_investment_control/pages/home/widgets/home_chart_page.dart';
import 'package:flutter_investment_control/pages/active/active_page.dart';
import 'package:flutter_investment_control/pages/active/extract/extract_page.dart';
import 'package:flutter_investment_control/pages/active/widgets/add_asset_modal/add_asset_modal.dart';
import 'package:flutter_investment_control/widgets/buttons/modern_cta_button.dart';
import 'package:flutter_investment_control/pages/home/widgets/home_sparkline_painter.dart';
import 'package:flutter_investment_control/pages/home/widgets/home_stock_ticker_widget.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

  List<Map<String, dynamic>> globalEmAltaList = [];
  List<Map<String, dynamic>> globalEmBaixaList = [];
  List<Map<String, dynamic>> globalMaisNegociadosList = [];

  List<Map<String, dynamic>> globalMarketsList = [];
  List<Map<String, dynamic>> newsList = [];

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
  AwesomeMarketsApi apiAwesome = AwesomeMarketsApi();
  FinancialNewsService apiNews = FinancialNewsService();
  GlobalStocksRepository globalStocksRepo = GlobalStocksRepository();

  InterstitialAd? _interstitialAd;

  bool isSearchActive = false;
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  bool _isNavigating = false;

  late Timer _timer;
  bool isLoading = true;

  void _resetSearchState() {
    if (!mounted) return;
    _searchDebounceTimer?.cancel();
    setState(() {
      isSearchActive = false;
      _searchController.clear();
      searchText = '';
      filteredStocks = stockIndicators;
      _searchFocusNode.unfocus();
    });
  }

  void _toggleSearch() {
    setState(() {
      isSearchActive = !isSearchActive;
      if (isSearchActive) {
        _searchFocusNode.requestFocus();
      } else {
        _resetSearchState();
      }
    });
  }

  void _onSearchQueryChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        String query = value.trim().toUpperCase();
        searchText = query;
        if (query.isEmpty) {
          filteredStocks = stockIndicators;
        } else {
          filteredStocks = stockIndicators
              .where((active) =>
                  active.symbol.toUpperCase().contains(query) ||
                  active.name.toUpperCase().contains(query) ||
                  active.sector.toUpperCase().contains(query) ||
                  active.segment.toUpperCase().contains(query))
              .toList();
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      _createInterstitialAd();
    });

    // Initial sync for global market cards from live APIs
    globalStocksRepo.getProcessedGlobalMarketCards().then((processed) {
      if (mounted) {
        setState(() {
          globalEmAltaList = processed["emAlta"]!;
          globalEmBaixaList = processed["emBaixa"]!;
          globalMaisNegociadosList = processed["maisNegociados"]!;
        });
      }
    });

    fetchData();
    fetchGlobalMarkets();
    fetchNews();
  }

  @override
  void dispose() {
    _timer.cancel();
    _searchDebounceTimer?.cancel();
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

        // Filter out pure indices (IBOVESPA, IFIX) and illiquid anomaly microcaps (>50% change or >R$500 price)
        bool isIndex = symbol.toUpperCase().contains('IBOV') ||
            symbol.toUpperCase().contains('IFIX') ||
            name.toUpperCase().contains('ÍNDICE') ||
            name.toUpperCase().contains('INDICE');

        bool isAnomaly = change.abs() > 50.0 || (lastPrice > 500.0 && !symbol.contains('/'));

        if (!isIndex && !isAnomaly) {
          if (change > 0) {
            emAltaTemp.add(itemData);
          } else if (change < 0) {
            emBaixaTemp.add(itemData);
          }
          maisNegociadosTemp.add(itemData);
        }
      }

      // Sort Em Alta by highest positive change
      emAltaTemp.sort((a, b) => (b['rawChange'] as double).compareTo(a['rawChange'] as double));

      // Sort Em Baixa by lowest change (most negative first)
      emBaixaTemp.sort((a, b) => (a['rawChange'] as double).compareTo(b['rawChange'] as double));

      // Fallback for Em Baixa if fewer than 3 negative items exist (e.g. green market / after hours)
      if (emBaixaTemp.length < 3 && maisNegociadosTemp.isNotEmpty) {
        var fallbackBaixa = List<Map<String, dynamic>>.from(maisNegociadosTemp);
        fallbackBaixa.sort((a, b) => (a['rawChange'] as double).compareTo(b['rawChange'] as double));
        emBaixaTemp = fallbackBaixa;
      }

      // Prioritize top liquid B3 blue-chip stocks for Mais Negociados
      const topLiquidTickers = {
        'PETR4', 'VALE3', 'ITUB4', 'BBAS3', 'WEGE3', 'B3SA3', 'ABEV3',
        'BBDC4', 'MGLU3', 'RENT3', 'SANB11', 'SUZB3', 'JBSS3', 'ELET3',
        'GGBR4', 'CSNA3', 'LREN3', 'VBBR3', 'PRIO3', 'RAIZ4'
      };

      maisNegociadosTemp.sort((a, b) {
        bool aIsTop = topLiquidTickers.contains(a['symbol']);
        bool bIsTop = topLiquidTickers.contains(b['symbol']);
        if (aIsTop && !bIsTop) return -1;
        if (!aIsTop && bIsTop) return 1;
        return (b['rawPrice'] as double).compareTo(a['rawPrice'] as double);
      });

      if (mounted && loaded.isNotEmpty) {
        setState(() {
          stockIndicators = loaded;
          filteredStocks = stockIndicators;
          if (emAltaTemp.isNotEmpty) emAltaList = emAltaTemp.take(3).toList();
          if (emBaixaTemp.isNotEmpty) emBaixaList = emBaixaTemp.take(3).toList();
          if (maisNegociadosTemp.isNotEmpty) maisNegociadosList = maisNegociadosTemp.take(3).toList();
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

  // Fetch real international stock quotes & global market indexes via GlobalStocksRepository & AwesomeMarketsApi
  Future<void> fetchGlobalMarkets() async {
    try {
      final markets = await apiAwesome.fetchGlobalMarkets();
      final processedGlobalStocks = await globalStocksRepo.getProcessedGlobalMarketCards();

      if (mounted) {
        setState(() {
          if (markets.isNotEmpty) {
            globalMarketsList = markets;
          }
          if (processedGlobalStocks["emAlta"] != null && processedGlobalStocks["emAlta"]!.isNotEmpty) {
            globalEmAltaList = processedGlobalStocks["emAlta"]!;
          }
          if (processedGlobalStocks["emBaixa"] != null && processedGlobalStocks["emBaixa"]!.isNotEmpty) {
            globalEmBaixaList = processedGlobalStocks["emBaixa"]!;
          }
          if (processedGlobalStocks["maisNegociados"] != null && processedGlobalStocks["maisNegociados"]!.isNotEmpty) {
            globalMaisNegociadosList = processedGlobalStocks["maisNegociados"]!;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching global markets: $e');
    }
  }

  // Fetch real financial news combining BRAPI and G1 Economia / InfoMoney RSS
  Future<void> fetchNews() async {
    try {
      final loadedNews = await apiNews.fetchCombinedNews();
      if (mounted && loadedNews.isNotEmpty) {
        setState(() {
          newsList = loadedNews;
        });
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
                                  const SizedBox(height: 16),
                                  _buildMarketListsSection(
                                    isDesktop,
                                    alta: globalEmAltaList,
                                    baixa: globalEmBaixaList,
                                    maisNegociados: globalMaisNegociadosList,
                                  ),
                                  const SizedBox(height: 32),
                                  _buildSectionHeader('Mercado Brasileiro', onSeeAll: () {}),
                                  const SizedBox(height: 12),
                                  _buildCategoryFilters(),
                                  const SizedBox(height: 16),
                                  _buildMarketListsSection(
                                    isDesktop,
                                    alta: emAltaList,
                                    baixa: emBaixaList,
                                    maisNegociados: maisNegociadosList,
                                  ),
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
                onPressed: _resetSearchState,
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
                        onChanged: _onSearchQueryChanged,
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
          // Top Navigation Links
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.dashboard_outlined, size: 14, color: AppColors.primaryBlue),
            label: const Text('Mercados', style: TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 2),
          TextButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ActivePage()));
            },
            icon: const Icon(Icons.pie_chart_outline, size: 14, color: AppColors.emeraldGreen),
            label: const Text('Carteira', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ),
          const SizedBox(width: 2),
          TextButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ExtratoPage()));
            },
            icon: const Icon(Icons.receipt_long_outlined, size: 14, color: AppColors.blueAccent),
            label: const Text('Extrato', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            onPressed: () {
              AddAssetModal.show(context, existingAssets: []);
            },
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Novo Ativo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
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
  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSectionHeaderWithIcon(IconData icon, String title, {VoidCallback? onSeeAll}) {
    return Row(
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

  // Category Quick Filter Cards (Mercado Brasileiro)
  Widget _buildCategoryFilters() {
    final categories = [
      {"icon": Icons.business_outlined, "label": "Ações"},
      {"icon": Icons.apartment_outlined, "label": "FIIs"},
      {"icon": Icons.account_balance_outlined, "label": "Tesouro Direto"},
      {"icon": Icons.verified_outlined, "label": "BDRs"},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((cat) {
        bool isSelected = selectedCategory == cat['label'];

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = cat['label'] as String;
              });
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
  Widget _buildMarketListsSection(
    bool isDesktop, {
    required List<Map<String, dynamic>> alta,
    required List<Map<String, dynamic>> baixa,
    required List<Map<String, dynamic>> maisNegociados,
  }) {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildListCardColumn('Em Alta Hoje', Icons.local_fire_department_outlined, AppColors.fireRed, alta)),
          const SizedBox(width: 16),
          Expanded(child: _buildListCardColumn('Em Baixa Hoje', Icons.trending_down_outlined, AppColors.redLoss, baixa)),
          const SizedBox(width: 16),
          Expanded(child: _buildListCardColumn('Mais Negociados', Icons.swap_vert_outlined, AppColors.blueAccent, maisNegociados)),
        ],
      );
    } else {
      return Column(
        children: [
          _buildListCardColumn('Em Alta Hoje', Icons.local_fire_department_outlined, AppColors.fireRed, alta),
          const SizedBox(height: 12),
          _buildListCardColumn('Em Baixa Hoje', Icons.trending_down_outlined, AppColors.redLoss, baixa),
          const SizedBox(height: 12),
          _buildListCardColumn('Mais Negociados', Icons.swap_vert_outlined, AppColors.blueAccent, maisNegociados),
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
                'Dados indisponíveis no momento. Aguardando atualização da fonte de dados.',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            )
          else
            ...items.map((item) {
              bool isPositive = item['isPositive'] ?? true;
              Color changeColor = isPositive ? AppColors.emeraldGreen : AppColors.redLoss;
              Active? active = item['active'] as Active?;
              String? logoUrl = item['logoUrl'] as String?;
              String subtitleText = item['volumeStr'] != null
                  ? '${item['symbol']} • ${item['volumeStr']}'
                  : '${item['symbol']} • ${item['sector']}';

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
                          border: Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: logoUrl != null && logoUrl.isNotEmpty
                              ? Image.network(
                                  logoUrl,
                                  width: 26,
                                  height: 26,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Text(
                                    item['symbol'].substring(0, math.min(4, (item['symbol'] as String).length)),
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.white),
                                  ),
                                )
                              : Text(
                                  item['symbol'].substring(0, math.min(4, (item['symbol'] as String).length)),
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.white),
                                ),
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
                              subtitleText,
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

  void _showArticleModal(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        String imageUrl = (item['image'] as String?)?.trim() ?? '';

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderDark),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Image & Close Button
                    Stack(
                      children: [
                        Container(
                          height: 220,
                          width: double.infinity,
                          color: AppColors.avatarDark,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.newspaper_outlined, size: 50, color: Colors.white24),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.newspaper_outlined, size: 50, color: Colors.white24),
                                ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.85),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 18,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close, size: 20, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 14,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: item['badgeColor'] ?? AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['badge'] ?? 'NOTÍCIA',
                              style: const TextStyle(fontSize: 10, color: AppColors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Article Content Body
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.business_center_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                item['source'] ?? 'Mercado Financeiro',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.borderDark),
                          const SizedBox(height: 12),
                          Text(
                            (item['description'] as String?)?.isNotEmpty == true
                                ? item['description']
                                : item['title'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Concluído',
                                  style: TextStyle(color: AppColors.blueAccent, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSingleNewsCard(Map<String, dynamic> item, {double? width}) {
    String imageUrl = (item['image'] as String?)?.trim() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(
              newsItem: item,
              allNews: newsList,
            ),
          ),
        );
      },
      child: Container(
        width: width,
        height: 190,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // 1. Dynamic News Thumbnail Image with Loading & Error Handlers
              Positioned.fill(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: AppColors.cardDark,
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryBlue.withValues(alpha: 0.5),
                                  AppColors.cardDark,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.newspaper_outlined,
                                size: 44,
                                color: Colors.white24,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue.withValues(alpha: 0.5),
                              AppColors.cardDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.newspaper_outlined,
                            size: 44,
                            color: Colors.white24,
                          ),
                        ),
                      ),
              ),

              // 2. Dark Gradient Overlay for optimal text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.94),
                        Colors.black.withValues(alpha: 0.25),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),

              // 3. News Card Content (Badge, Title, Source)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                        item['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          height: 1.3,
                        ),
                        maxLines: 1,
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
            ],
          ),
        ),
      ),
    );
  }

  // Radar Financeiro (News Cards)
  Widget _buildNewsSection(bool isDesktop) {
    if (newsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: const Center(
          child: Text(
            'Aguardando atualização das notícias de fontes oficiais...',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    if (isDesktop) {
      return Row(
        children: newsList.take(2).map((item) {
          return Expanded(
            child: _buildSingleNewsCard(item),
          );
        }).toList(),
      );
    } else {
      return SizedBox(
        height: 190,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: newsList.length,
          itemBuilder: (context, index) {
            var item = newsList[index];
            return _buildSingleNewsCard(item, width: MediaQuery.of(context).size.width * 0.8);
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
          _buildNavItem(FontAwesomeIcons.newspaper, 'Notícias', false, () {
            if (newsList.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewsDetailPage(
                    newsItem: newsList.first,
                    allNews: newsList,
                  ),
                ),
              );
            }
          }),
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
  void showDetails(Active active) async {
    if (_isNavigating) return;
    _isNavigating = true;
    _searchFocusNode.unfocus();

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveDetailsPage(active: active),
        ),
      );
    } finally {
      _isNavigating = false;
      // Mandatory requirement: Automatically close search & reset Home state upon return
      if (mounted) {
        _resetSearchState();
      }
    }
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
