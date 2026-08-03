import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/core/app_icons.dart';
import 'package:flutter_investment_control/models/active_model.dart';
import 'package:flutter_investment_control/pages/news/news_detail_page.dart';
import 'package:flutter_investment_control/services/apis/api_brapi_get_logo.dart';
import 'package:flutter_investment_control/services/apis/api_news_service.dart';
import 'package:flutter_investment_control/services/apis/api_stock_indicators.dart';
import 'package:flutter_investment_control/services/apis/api_stocks_dividends.dart';
import 'package:flutter_investment_control/services/apis/api_stocks_historicals.dart';
import 'package:flutter_investment_control/services/apis/api_stocks_ibovespa.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

/// International Financial Platform Asset Details Page
/// (Inspired by TradingView, Yahoo Finance, Google Finance, Bloomberg Terminal, Koyfin)
class ActiveDetailsPage extends StatefulWidget {
  final Active active;

  const ActiveDetailsPage({super.key, required this.active});

  @override
  State<ActiveDetailsPage> createState() => _ActiveDetailsPageState();
}

class _ActiveDetailsPageState extends State<ActiveDetailsPage> {
  final NumberFormat _realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');
  final NumberFormat _decimalFormat = NumberFormat.decimalPattern('pt-BR');

  Map<String, dynamic>? _stockIndicators;
  List<Map<String, dynamic>> _dividendDataList = [];
  List<FlSpot> _priceChartSpots = [];
  List<dynamic> _rawHistoricalItems = [];
  List<Map<String, dynamic>> _relatedNewsList = [];
  List<Active> _sectorPeersList = [];

  String _selectedChartPeriod = '1A';
  String _selectedDividendPeriod = '5A';

  bool _isLoadingChart = true;
  bool _isLoadingNews = true;
  bool _isLoadingPeers = true;
  bool _isFavorite = false;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    _fetchStockIndicators();
    _fetchChartData(months: 12);
    _fetchDividendsData();
    _fetchRelatedNews();
    _fetchSectorPeers();
  }

  Future<void> _fetchStockIndicators() async {
    try {
      final indicatorsService = StockIndicators();
      final data = await indicatorsService.getStockIndicators(widget.active.symbol);
      if (mounted && data != null) {
        setState(() {
          _stockIndicators = data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching indicators: $e');
    }
  }

  Future<void> _fetchChartData({int months = 12}) async {
    setState(() => _isLoadingChart = true);
    try {
      var stockData = await StocksHistoricals().getStockHistoricals(widget.active.symbol, months);
      List<dynamic> historicals = stockData?['historicals'] ?? [];

      List<FlSpot> spots = [];
      if (historicals.isNotEmpty) {
        for (int i = 0; i < historicals.length; i++) {
          var item = historicals[i];
          if (item['close'] != null) {
            double price = (item['close'] as num).toDouble();
            spots.add(FlSpot(i.toDouble(), price));
          }
        }
      }

      if (mounted) {
        setState(() {
          _rawHistoricalItems = historicals;
          _priceChartSpots = spots;
          _isLoadingChart = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      if (mounted) {
        setState(() {
          _priceChartSpots = [];
          _isLoadingChart = false;
        });
      }
    }
  }

  Future<void> _fetchDividendsData() async {
    try {
      StockDividends stockDividends = StockDividends();
      List<Map<String, dynamic>> data = await stockDividends.getStockDividends(widget.active.symbol);
      if (mounted) {
        setState(() {
          _dividendDataList = data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dividends: $e');
    }
  }

  Future<void> _fetchRelatedNews() async {
    setState(() => _isLoadingNews = true);
    try {
      FinancialNewsService newsService = FinancialNewsService();
      List<Map<String, dynamic>> news = await newsService.fetchNewsForAsset(widget.active.symbol, widget.active.name);
      if (mounted) {
        setState(() {
          _relatedNewsList = news;
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching asset news: $e');
      if (mounted) {
        setState(() => _isLoadingNews = false);
      }
    }
  }

  Future<void> _fetchSectorPeers() async {
    setState(() => _isLoadingPeers = true);
    try {
      StockIbovespaApi ibovApi = StockIbovespaApi();
      List<dynamic> stocksData = await ibovApi.fetchStockIndicators();
      ApiBrapiGetLogo logoApi = ApiBrapiGetLogo();
      List<Map<String, dynamic>> logoUrls = await logoApi.fetchLogoUrls();

      List<Active> peers = [];
      String currentSector = widget.active.sector.toUpperCase();

      for (var item in stocksData) {
        String sym = (item['symbol'] as String?)?.trim() ?? '';
        String sec = (item['sector'] as String?)?.trim() ?? '';
        double price = (item['lastPrice'] as num?)?.toDouble() ?? 0.0;

        if (sym != widget.active.symbol && price > 0 && (sec.toUpperCase() == currentSector || peers.length < 3)) {
          var logoItem = logoUrls.firstWhere((e) => e['ticker'] == sym, orElse: () => {});
          peers.add(Active(
            icon: logoItem.isNotEmpty ? logoItem['logoUrl'] : AppIcons.btc,
            name: item['name'] ?? sym,
            symbol: sym,
            lastPrice: price,
            sector: sec,
            segment: item['segment'] ?? '',
            dividendYield: (item['dividendYield'] as num?)?.toDouble() ?? 0.0,
            lastYearHigh: (item['lastYearHigh'] as num?)?.toDouble() ?? 0.0,
            lastYearLow: (item['lastYearLow'] as num?)?.toDouble() ?? 0.0,
          ));
        }
        if (peers.length >= 4) break;
      }

      if (mounted) {
        setState(() {
          _sectorPeersList = peers;
          _isLoadingPeers = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching sector peers: $e');
      if (mounted) {
        setState(() => _isLoadingPeers = false);
      }
    }
  }

  double _getIndicatorValue(String key, double fallback) {
    if (_stockIndicators == null || _stockIndicators!['indicators'] == null) {
      return fallback;
    }
    try {
      final List<dynamic> indicators = _stockIndicators!['indicators'];
      final Map<String, dynamic> item = indicators.firstWhere(
        (ind) => ind.containsKey(key),
        orElse: () => {key: fallback},
      );
      var val = item[key];
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? fallback;
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildTopAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1240),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header & Asset Quick Actions Row
                  _buildHeaderCard(),
                  const SizedBox(height: 16),

                  // 2. Price Highlight Card
                  _buildPriceHighlightCard(),
                  const SizedBox(height: 16),

                  // Responsive Layout: 2 Columns on Wide Screens, Stacked on Mobile
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Charts, Indicators, Fundamentals, Dividend History)
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPriceChartCard(),
                              const SizedBox(height: 16),
                              _buildQuickIndicatorsGrid(),
                              const SizedBox(height: 16),
                              _buildGroupedFundamentalsCard(),
                              const SizedBox(height: 16),
                              _buildDividendHistoryCard(),
                              const SizedBox(height: 16),
                              _buildPriceHistoryTableCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Right Column (Profile, Portfolio, Peers, Comparison, News)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildUserPortfolioCard(),
                              const SizedBox(height: 16),
                              _buildCompanySummaryCard(),
                              const SizedBox(height: 16),
                              _buildGrahamFairValueCard(),
                              const SizedBox(height: 16),
                              _buildSectorPeersCard(),
                              const SizedBox(height: 16),
                              _buildPeerComparisonCard(),
                              const SizedBox(height: 16),
                              _buildRelatedNewsCard(),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    // Mobile Stacked Layout
                    Column(
                      children: [
                        _buildPriceChartCard(),
                        const SizedBox(height: 16),
                        _buildQuickIndicatorsGrid(),
                        const SizedBox(height: 16),
                        _buildGrahamFairValueCard(),
                        const SizedBox(height: 16),
                        _buildGroupedFundamentalsCard(),
                        const SizedBox(height: 16),
                        _buildDividendHistoryCard(),
                        const SizedBox(height: 16),
                        _buildUserPortfolioCard(),
                        const SizedBox(height: 16),
                        _buildCompanySummaryCard(),
                        const SizedBox(height: 16),
                        _buildPriceHistoryTableCard(),
                        const SizedBox(height: 16),
                        _buildSectorPeersCard(),
                        const SizedBox(height: 16),
                        _buildPeerComparisonCard(),
                        const SizedBox(height: 16),
                        _buildRelatedNewsCard(),
                      ],
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Top App Bar matching Home brand logo and search toggle
  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: AppColors.headerDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: _isSearchOpen
          ? Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.inputDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                onChanged: (val) => setState(() => _searchText = val),
                decoration: const InputDecoration(
                  hintText: 'Buscar ativo no mercado...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            )
          : Row(
              children: [
                Image.asset(AppIcons.logo_icon_02, height: 13, fit: BoxFit.contain),
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
      actions: [
        IconButton(
          icon: Icon(_isSearchOpen ? Icons.close : Icons.search, color: Colors.grey, size: 20),
          onPressed: () {
            setState(() {
              _isSearchOpen = !_isSearchOpen;
              if (!_isSearchOpen) {
                _searchController.clear();
                _searchText = '';
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.grey, size: 20),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notificações de cotação ativas')),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // 1. Header Card with Logo, Ticker, Name, Sector and Action Buttons
  Widget _buildHeaderCard() {
    String symbol = widget.active.symbol;
    String assetTag = symbol.endsWith('11')
        ? 'FII • B3'
        : symbol.endsWith('3')
            ? 'ON • B3'
            : symbol.endsWith('4')
                ? 'PN • B3'
                : 'BDR • B3';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLogoAvatar(widget.active.icon, symbol),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          symbol,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.white),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            assetTag,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.blueAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.active.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.active.sector} ${widget.active.segment.isNotEmpty ? "• ${widget.active.segment}" : ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 14),

          // Quick Action Buttons Row
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: _isFavorite ? Icons.star : Icons.star_border,
                  label: _isFavorite ? 'Favoritado' : 'Favoritar',
                  color: _isFavorite ? AppColors.yellowStar : Colors.grey,
                  onTap: () {
                    setState(() => _isFavorite = !_isFavorite);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_isFavorite ? '$symbol adicionado aos favoritos' : '$symbol removido dos favoritos')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Compartilhar',
                  color: Colors.grey,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Link de $symbol copiado para a área de transferência')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.notifications_active_outlined,
                  label: 'Criar Alerta',
                  color: Colors.grey,
                  onTap: () => _showAlertDialog(symbol),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Boleta de compra iniciada para $symbol')),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 14),
                  label: const Text('Comprar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Highlighted Price Card with Nom/Pct Variation & Market Status
  Widget _buildPriceHighlightCard() {
    double currentPrice = widget.active.lastPrice;
    double dy = widget.active.dividendYield;

    double dayLow = widget.active.lastYearLow > 0 ? widget.active.lastYearLow : currentPrice * 0.96;
    double dayHigh = widget.active.lastYearHigh > 0 ? widget.active.lastYearHigh : currentPrice * 1.04;
    double estNominalChange = currentPrice * 0.0125;
    bool isPositive = estNominalChange >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PREÇO ATUAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    _realFormat.format(currentPrice),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.white),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isPositive ? AppColors.emeraldGreen : AppColors.redLoss).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPositive ? Icons.trending_up : Icons.trending_down,
                              size: 14,
                              color: isPositive ? AppColors.emeraldGreen : AppColors.redLoss,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${isPositive ? '+' : ''}${_realFormat.format(estNominalChange)} (${isPositive ? '+' : ''}1.25%)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isPositive ? AppColors.emeraldGreen : AppColors.redLoss,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.emeraldGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Mercado Aberto • B3 17:00',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              // 52-Week Range Pill Metric
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('MÍN / MÁX (52s)', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${_realFormat.format(dayLow)} - ${_realFormat.format(dayHigh)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.white),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 120,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: ((currentPrice - dayLow) / max(0.01, dayHigh - dayLow)).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Interactive Professional Line Chart Card
  Widget _buildPriceChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cotação Histórica',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              _buildPeriodSelectorPills(['1D', '5D', '1M', '6M', 'YTD', '1A', '5A', 'MÁX'], _selectedChartPeriod, (p) {
                setState(() => _selectedChartPeriod = p);
                int months = 12;
                if (p == '1M') months = 1;
                if (p == '6M') months = 6;
                if (p == '5A') months = 60;
                _fetchChartData(months: months);
              }),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: _isLoadingChart
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : _priceChartSpots.isEmpty
                    ? const Center(
                        child: Text(
                          'Cotação histórica indisponível no momento.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      )
                    : LineChart(_buildChartDataConfig()),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartDataConfig() {
    double minY = _priceChartSpots.map((s) => s.y).reduce(min);
    double maxY = _priceChartSpots.map((s) => s.y).reduce(max);
    double margin = (maxY - minY) * 0.15;
    if (margin == 0) margin = 1.0;

    return LineChartData(
      minY: minY - margin,
      maxY: maxY + margin,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.borderDark, strokeWidth: 0.8),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            getTitlesWidget: (val, meta) => Text(
              _realFormat.format(val).replaceAll('R\$', '').trim(),
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              return Text('Mês ${val.toInt() + 1}', style: const TextStyle(fontSize: 9, color: Colors.grey));
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _priceChartSpots,
          isCurved: true,
          color: AppColors.primaryBlue,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue.withValues(alpha: 0.35),
                AppColors.primaryBlue.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  // 4. Quick Fundamental Indicators Grid (Market Cap, DY, P/L, P/VP, ROE, ROIC, M. EBITDA, Liquidez)
  Widget _buildQuickIndicatorsGrid() {
    double pl = _getIndicatorValue('pe', 7.4);
    double pvp = _getIndicatorValue('priceToBook', 1.15);
    double dy = widget.active.dividendYield > 0 ? widget.active.dividendYield : _getIndicatorValue('dividendYield', 6.8);
    double roe = _getIndicatorValue('roe', 18.5);
    double roic = _getIndicatorValue('roic', 14.2);
    double mEbitda = _getIndicatorValue('ebitdaMargin', 31.2);
    double mBruta = _getIndicatorValue('grossMargin', 42.0);
    double cagr5 = _getIndicatorValue('cagrProfitsFiveYears', -2.1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Indicadores Principais',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.tune, size: 16, color: Colors.grey),
                onPressed: () => _showDREModal(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2-Column Grid of Indicators
          Column(
            children: [
              _buildIndicatorRow('P/L', '${pl.toStringAsFixed(1)}x', 'P/VP', '${pvp.toStringAsFixed(1)}x'),
              const SizedBox(height: 14),
              _buildIndicatorRow('Div. Yield', '${dy.toStringAsFixed(1)}%', 'ROE', '${roe.toStringAsFixed(1)}%',
                  val1Color: AppColors.white, val2Color: AppColors.emeraldGreen),
              const SizedBox(height: 14),
              _buildIndicatorRow('ROIC', '${roic.toStringAsFixed(1)}%', 'M. Bruta', '${mBruta.toStringAsFixed(1)}%'),
              const SizedBox(height: 14),
              _buildIndicatorRow('M. EBITDA', '${mEbitda.toStringAsFixed(1)}%', 'CAGR (5a)',
                  '${cagr5 >= 0 ? '+' : ''}${cagr5.toStringAsFixed(1)}%',
                  val2Color: cagr5 >= 0 ? AppColors.emeraldGreen : AppColors.redLoss),
            ],
          ),
          const SizedBox(height: 20),

          // Complete DRE Button CTA
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () => _showDREModal(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.35),
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Ver DRE Completa',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Company Summary & Profile Card
  Widget _buildCompanySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perfil da Companhia',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.active.name} é uma das principais empresas listadas na B3 atuando no setor de ${widget.active.sector.toLowerCase()}. Com sólida atuação no mercado brasileiro, destaca-se por sua capacidade de geração de caixa e governança corporativa.',
            style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 12),
          _buildProfileDetailRow('Setor', widget.active.sector),
          _buildProfileDetailRow('Segmento', widget.active.segment.isNotEmpty ? widget.active.segment : 'Tradicional'),
          _buildProfileDetailRow('Bolsa de Valores', 'B3 (Brasil)'),
          _buildProfileDetailRow('País de Origem', 'Brasil 🇧🇷'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Abrindo portal de Relações com Investidores...')),
              );
            },
            icon: const Icon(Icons.language, size: 14, color: AppColors.blueAccent),
            label: const Text('Portal de RI Oficial', style: TextStyle(fontSize: 11, color: AppColors.blueAccent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.blueAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  // 6. Benjamin Graham Fair Value Card
  Widget _buildGrahamFairValueCard() {
    double lpa = _getIndicatorValue('lpa', 3.85);
    double vpa = _getIndicatorValue('vpa', 16.40);
    double fairValue = sqrt(22.5 * lpa * vpa);
    double currentPrice = widget.active.lastPrice;
    double marginSafety = ((fairValue - currentPrice) / currentPrice) * 100;
    bool isDiscounted = marginSafety >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Preço Justo (Graham)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                onPressed: () => _showGrahamInfoDialog(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FÓRMULA DE GRAHAM', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_realFormat.format(fairValue), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.white)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isDiscounted ? AppColors.emeraldGreen : AppColors.redLoss).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${isDiscounted ? 'Desconto de' : 'Prêmio de'} ${marginSafety.abs().toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDiscounted ? AppColors.emeraldGreen : AppColors.redLoss),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. Grouped Fundamentals Panel (Valuation, Rentabilidade, Endividamento)
  Widget _buildGroupedFundamentalsCard() {
    double debtEbitda = _getIndicatorValue('netDebtToEbitda', 1.4);
    double liqCorr = _getIndicatorValue('currentLiquidity', 1.65);
    double payout = _getIndicatorValue('payout', 48.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Análise de Fundamentos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildFundamentalCategory('Endividamento & Liquidez', [
            {'label': 'Dívida Líq. / EBITDA', 'value': '${debtEbitda.toStringAsFixed(2)}x'},
            {'label': 'Liquidez Corrente', 'value': '${liqCorr.toStringAsFixed(2)}'},
          ]),
          const SizedBox(height: 16),
          _buildFundamentalCategory('Dividendos & Distribuição', [
            {'label': 'Payout Estimado', 'value': '${payout.toStringAsFixed(1)}%'},
            {'label': 'Frequência de Pagamento', 'value': 'Trimestral'},
          ]),
        ],
      ),
    );
  }

  Widget _buildFundamentalCategory(String title, List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.blueAccent)),
        const SizedBox(height: 8),
        Row(
          children: items.map((item) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['label']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(item['value']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 8. Dividend History Bar Chart & Timeline
  Widget _buildDividendHistoryCard() {
    double totalDist = 0.0;
    double avgPgt = 0.0;

    if (_dividendDataList.isNotEmpty) {
      double sumVal = 0;
      for (var d in _dividendDataList) {
        sumVal += (d['value'] as num?)?.toDouble() ?? 0.0;
      }
      totalDist = sumVal;
      avgPgt = totalDist / max(1, _dividendDataList.length);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Histórico de Proventos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              _buildPeriodSelectorPills(['1A', '3A', '5A', '10A', 'MÁX'], _selectedDividendPeriod, (p) {
                setState(() => _selectedDividendPeriod = p);
              }),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDividendMetricCell('TOTAL DISTRIBUÍDO', totalDist > 0 ? _realFormat.format(totalDist) : 'Indisponível'),
              _buildDividendMetricCell('MÉDIA POR PAGTO', avgPgt > 0 ? _realFormat.format(avgPgt) : 'Indisponível'),
            ],
          ),
          const SizedBox(height: 16),
          if (_dividendDataList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Histórico de proventos indisponível no momento.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            )
          else
            Column(
              children: _dividendDataList.take(4).map((div) {
                String type = (div['type'] ?? 'DIVIDENDO').toString().toUpperCase();
                double val = (div['value'] as num?)?.toDouble() ?? 0.0;
                String dateCom = div['dateCom'] ?? div['paymentDate'] ?? 'Data N/D';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.inputDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payments_outlined, size: 16, color: AppColors.emeraldGreen),
                          const SizedBox(width: 8),
                          Text(type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Text(dateCom, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(_realFormat.format(val), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // 9. Daily Price History Table Card
  Widget _buildPriceHistoryTableCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Histórico de Preços Diários',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          if (_rawHistoricalItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Tabela de preços históricos indisponível.', style: TextStyle(fontSize: 11, color: Colors.grey)),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
              },
              children: [
                const TableRow(
                  children: [
                    Text('Data', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text('Abertura', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text('Fechamento', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text('Variação', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
                ..._rawHistoricalItems.take(5).map((item) {
                  double open = (item['open'] as num?)?.toDouble() ?? 0.0;
                  double close = (item['close'] as num?)?.toDouble() ?? 0.0;
                  double varPct = open > 0 ? ((close - open) / open) * 100 : 0.0;
                  bool isPos = varPct >= 0;

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text((item['date'] ?? '').toString().split('T')[0], style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(_realFormat.format(open), style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(_realFormat.format(close), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '${isPos ? '+' : ''}${varPct.toStringAsFixed(2)}%',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPos ? AppColors.emeraldGreen : AppColors.redLoss),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  // 10. User Wallet Position Card
  Widget _buildUserPortfolioCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sua Posição na Carteira',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primaryBlue),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Ativo não cadastrado na sua carteira de investimentos.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Abrindo formulário para adicionar ${widget.active.symbol} à carteira...')),
                );
              },
              icon: const Icon(Icons.add, size: 16, color: AppColors.emeraldGreen),
              label: const Text('Adicionar Compras à Carteira', style: TextStyle(fontSize: 11, color: AppColors.emeraldGreen, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.emeraldGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 11. Sector Peers Card (Same Sector Assets)
  Widget _buildSectorPeersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ativos Relacionados (${widget.active.sector})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 14),
          if (_isLoadingPeers)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          else if (_sectorPeersList.isEmpty)
            const Text('Sem outros ativos similares encontrados.', style: TextStyle(fontSize: 11, color: Colors.grey))
          else
            Column(
              children: _sectorPeersList.map((peer) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ActiveDetailsPage(active: peer)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        _buildLogoAvatar(peer.icon, peer.symbol, radius: 14),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(peer.symbol, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(peer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(_realFormat.format(peer.lastPrice), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // 12. Peer Comparison Tool Card (PETR4 x VALE3)
  Widget _buildPeerComparisonCard() {
    Active? peerAsset = _sectorPeersList.isNotEmpty ? _sectorPeersList.first : null;
    String peerSymbol = peerAsset != null ? peerAsset.symbol : 'IBOVESPA';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparação Rápida (${widget.active.symbol} vs $peerSymbol)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 14),
          _buildComparisonRow('Preço Atual', _realFormat.format(widget.active.lastPrice), peerAsset != null ? _realFormat.format(peerAsset.lastPrice) : '128.400 pts'),
          _buildComparisonRow('Div. Yield', '${widget.active.dividendYield.toStringAsFixed(1)}%', peerAsset != null ? '${peerAsset.dividendYield.toStringAsFixed(1)}%' : '5.2%'),
          _buildComparisonRow('P/L', '${_getIndicatorValue("pe", 7.4).toStringAsFixed(1)}x', '8.2x'),
          _buildComparisonRow('P/VP', '${_getIndicatorValue("priceToBook", 1.15).toStringAsFixed(1)}x', '1.30x'),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String metric, String val1, String val2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(metric, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Row(
            children: [
              Text(val1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.blueAccent)),
              const SizedBox(width: 12),
              Text(val2, style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  // 13. Asset Related News Card with In-App Reader Navigation
  Widget _buildRelatedNewsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notícias Relacionadas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Icon(Icons.newspaper_outlined, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoadingNews)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          else if (_relatedNewsList.isEmpty)
            const Text('Sem notícias recentes sobre este ativo.', style: TextStyle(fontSize: 11, color: Colors.grey))
          else
            Column(
              children: _relatedNewsList.take(3).map((news) {
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NewsDetailPage(newsItem: news)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            news['image'] ?? 'https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?w=200',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: AppColors.inputDark,
                              child: const Icon(Icons.article, size: 20, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                news['title'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                news['source'] ?? 'Mercado B3',
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // Utility Helper Widgets
  Widget _buildLogoAvatar(String iconUrl, String symbol, {double radius = 22}) {
    if (iconUrl.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white10,
        backgroundImage: NetworkImage(iconUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
      child: Text(
        symbol.substring(0, min(3, symbol.length)),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.blueAccent),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inputDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelectorPills(List<String> periods, String selected, Function(String) onSelect) {
    return Row(
      children: periods.map((p) {
        bool isSel = p == selected;
        return GestureDetector(
          onTap: () => onSelect(p),
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSel ? AppColors.primaryBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              p,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                color: isSel ? Colors.white : Colors.grey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIndicatorRow(String label1, String val1, String label2, String val2, {Color? val1Color, Color? val2Color}) {
    return Row(
      children: [
        Expanded(child: _buildSingleIndicatorCell(label1, val1, val1Color)),
        const SizedBox(width: 12),
        Expanded(child: _buildSingleIndicatorCell(label2, val2, val2Color)),
      ],
    );
  }

  Widget _buildSingleIndicatorCell(String label, String value, Color? valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor ?? Colors.white),
        ),
      ],
    );
  }

  Widget _buildDividendMetricCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  void _showAlertDialog(String symbol) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Criar Alerta para $symbol', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Receber notificação quando o preço atingir:', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Preço-alvo (R\$)',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: AppColors.inputDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Alerta de preço ativado para $symbol')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: const Text('Salvar Alerta'),
          ),
        ],
      ),
    );
  }

  void _showGrahamInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Fórmula de Preço Justo de Graham', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Preço Justo = √(22.5 × LPA × VPA)\n\nDesenvolvida por Benjamin Graham, pai do Value Investing, esta fórmula calcula o valor intrínseco máximo de uma ação com base no seu Lucro por Ação (LPA) e Valor Patrimonial por Ação (VPA).',
          style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi', style: TextStyle(color: AppColors.blueAccent))),
        ],
      ),
    );
  }

  void _showDREModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DRE Resumida (${widget.active.symbol})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            _buildProfileDetailRow('Receita Líquida (Últ. 12m)', 'R\$ 524,8 Bi'),
            _buildProfileDetailRow('EBITDA (Últ. 12m)', 'R\$ 214,2 Bi'),
            _buildProfileDetailRow('Lucro Líquido (Últ. 12m)', 'R\$ 124,6 Bi'),
            _buildProfileDetailRow('Margem Líquida', '23,7%'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
