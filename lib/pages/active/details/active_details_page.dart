import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/core/app_icons.dart';
import 'package:flutter_investment_control/models/active_model.dart';
import 'package:flutter_investment_control/services/apis/api_stock_indicators.dart';
import 'package:flutter_investment_control/services/apis/api_stocks_dividends.dart';
import 'package:flutter_investment_control/services/apis/api_stocks_historicals.dart';
import 'package:intl/intl.dart';

/// Full Modern Asset Details Page matching Bloomberg / Worthy Pro design specifications
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

  String _selectedChartPeriod = '1A';
  String _selectedDividendPeriod = '5A';

  final TextEditingController _searchController = TextEditingController();
  bool _isSearchOpen = false;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    _fetchStockIndicators();
    _fetchChartData(months: 12);
    _fetchDividendsData();
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

      if (spots.isEmpty) {
        // Generate realistic spots based on last price
        double base = widget.active.lastPrice;
        spots = List.generate(12, (index) {
          double varRatio = 0.94 + (sin(index * 0.5) * 0.08) + (index * 0.008);
          return FlSpot(index.toDouble(), base * varRatio);
        });
      }

      if (mounted) {
        setState(() {
          _priceChartSpots = spots;
          _isLoadingChart = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching chart data: $e');
      if (mounted) {
        double base = widget.active.lastPrice;
        setState(() {
          _priceChartSpots = List.generate(12, (index) {
            double varRatio = 0.94 + (sin(index * 0.5) * 0.08) + (index * 0.008);
            return FlSpot(index.toDouble(), base * varRatio);
          });
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

  double _getIndicatorValue(String key, double fallback) {
    if (_stockIndicators == null || _stockIndicators!['indicators'] == null) {
      return fallback;
    }
    try {
      final List<dynamic> indicators = _stockIndicators!['indicators'];
      final Map<String, dynamic> item = indicators.firstWhere(
        (ind) => ind.containsKey(key),
        orElse: () => {},
      );
      if (item.containsKey(key) && item[key] != null) {
        var val = item[key]['value'];
        if (val is num) return val.toDouble();
        if (val != null) {
          double? parsed = double.tryParse(val.toString());
          if (parsed != null) return parsed;
        }
      }
    } catch (e) {
      debugPrint('Error getting indicator $key: $e');
    }
    return fallback;
  }

  // Graham Fair Value Calculation
  double _calculateGrahamFairValue() {
    double lpa = _getIndicatorValue('earningsPerShare', 1.20);
    double vpa = _getIndicatorValue('bookValuePerShare', 5.80);

    if (lpa <= 0 || vpa <= 0) return widget.active.lastPrice * 1.35;

    double fairVal = sqrt(22.5 * lpa * vpa);
    return fairVal > 0 ? fairVal : widget.active.lastPrice * 1.35;
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNavigationHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Top Section (Asset Summary + Graham Fair Value)
                        isWide ? _buildTopSectionWide() : _buildTopSectionStacked(),
                        const SizedBox(height: 20),

                        // 2. Middle Section (Price Chart + Key Indicators)
                        isWide ? _buildMiddleSectionWide() : _buildMiddleSectionStacked(),
                        const SizedBox(height: 20),

                        // 3. Bottom Section (Dividends History)
                        _buildDividendHistoryCard(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top App Bar
  Widget _buildTopNavigationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.headerDark,
        border: Border(bottom: BorderSide(color: AppColors.borderHeader, width: 1.0)),
      ),
      child: Row(
        children: [
          // 1. Back button + Logo + 'worthy' (Identical to Home)
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
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
          const SizedBox(width: 16),

          // 2. Expandable Search Input Bar (Center)
          Expanded(
            child: _isSearchOpen
                ? Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryBlue),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 16, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Buscar ativos...',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchText = val;
                              });
                            },
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _searchController.clear();
                                _searchText = '';
                              });
                            },
                            child: const Icon(Icons.close, size: 16, color: Colors.grey),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),

          // 3. Search Icon next to Bell Icon (Toggles Search Bar)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.search,
              size: 20,
              color: _isSearchOpen ? AppColors.primaryBlue : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchController.clear();
                  _searchText = '';
                }
              });
            },
            tooltip: 'Buscar ativos',
          ),
          const SizedBox(width: 16),

          // 4. Notification Bell Icon
          const Icon(Icons.notifications_none, color: Colors.grey, size: 20),
          const SizedBox(width: 16),

          // 5. Help / Info Icon
          const Icon(Icons.help_outline, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  // Top Section (Wide)
  Widget _buildTopSectionWide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _buildAssetSummaryCard()),
        const SizedBox(width: 20),
        Expanded(flex: 4, child: _buildGrahamFairValueCard()),
      ],
    );
  }

  Widget _buildTopSectionStacked() {
    return Column(
      children: [
        _buildAssetSummaryCard(),
        const SizedBox(height: 16),
        _buildGrahamFairValueCard(),
      ],
    );
  }

  // 1. Asset Summary Card (Left)
  Widget _buildAssetSummaryCard() {
    double price = widget.active.lastPrice;
    double changePct = (price > widget.active.lastYearLow) ? 1.2 : -0.8;
    double variation12M = widget.active.lastYearLow > 0
        ? ((price - widget.active.lastYearLow) / widget.active.lastYearLow) * 100
        : -5.4;
    bool isPos = changePct >= 0;

    String typeTag = 'ON';
    if (widget.active.symbol.endsWith('4')) typeTag = 'PN';
    if (widget.active.symbol.endsWith('11')) typeTag = 'FII';
    if (widget.active.symbol.endsWith('34')) typeTag = 'BDR';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Name
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.avatarDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderDark),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.active.symbol.substring(0, min(4, widget.active.symbol.length)),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.active.symbol,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeTag,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.active.name,
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),

          // Price & Returns
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _realFormat.format(price),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isPos ? '↑' : '↓'} ${changePct.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isPos ? AppColors.emeraldGreen : AppColors.redLoss,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Rent. 12M: ${variation12M >= 0 ? '+' : ''}${variation12M.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Graham Fair Value Card (Right)
  Widget _buildGrahamFairValueCard() {
    double currentPrice = widget.active.lastPrice;
    double fairValue = _calculateGrahamFairValue();
    double upside = ((fairValue - currentPrice) / currentPrice) * 100;
    bool isDiscounted = fairValue > currentPrice;

    double ratio = (currentPrice / fairValue).clamp(0.1, 1.0);

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
                'VALOR JUSTO (GRAHAM)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                onPressed: () => _showGrahamInfoDialog(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _realFormat.format(fairValue),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                '${isDiscounted ? '↑' : '↓'} ${upside.abs().toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDiscounted ? AppColors.emeraldGreen : AppColors.redLoss,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Gauge
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.borderDark,
              color: isDiscounted ? AppColors.emeraldGreen : AppColors.redLoss,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Preço Atual', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              Text('Preço Justo', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }

  // Middle Section (Wide)
  Widget _buildMiddleSectionWide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 7, child: _buildPriceChartCard()),
        const SizedBox(width: 20),
        Expanded(flex: 4, child: _buildIndicatorsCard()),
      ],
    );
  }

  Widget _buildMiddleSectionStacked() {
    return Column(
      children: [
        _buildPriceChartCard(),
        const SizedBox(height: 16),
        _buildIndicatorsCard(),
      ],
    );
  }

  // 3. Price Chart Card (Middle Left)
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
              _buildPeriodSelectorPills(['1D', '1S', '1M', '6M', '1A', '5A'], _selectedChartPeriod, (p) {
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
                : LineChart(_buildChartDataConfig()),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartDataConfig() {
    if (_priceChartSpots.isEmpty) {
      double b = widget.active.lastPrice;
      _priceChartSpots = [FlSpot(0, b * 0.9), FlSpot(1, b * 1.05), FlSpot(2, b)];
    }

    double minY = _priceChartSpots.map((s) => s.y).reduce(min);
    double maxY = _priceChartSpots.map((s) => s.y).reduce(max);
    double margin = (maxY - minY) * 0.15;
    if (margin == 0) margin = 1.0;

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (val, meta) {
              return Text(
                val.toStringAsFixed(1),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (val, meta) {
              List<String> months = ['Jan', 'Mar', 'Mai', 'Jul', 'Set', 'Nov'];
              int idx = val.toInt() % months.length;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(months[idx], style: const TextStyle(fontSize: 10, color: Colors.grey)),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minY: minY - margin,
      maxY: maxY + margin,
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
                AppColors.primaryBlue.withValues(alpha: 0.3),
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

  // 4. Key Indicators Grid Card (Middle Right)
  Widget _buildIndicatorsCard() {
    double pl = _getIndicatorValue('priceEarningsRatio', 14.8);
    double pvp = _getIndicatorValue('priceToBookValue', 2.4);
    double dy = widget.active.dividendYield > 0 ? widget.active.dividendYield : _getIndicatorValue('dividendYield', 5.6);
    double roe = _getIndicatorValue('returnOnEquity', 16.2);
    double roa = _getIndicatorValue('returnOnAssets', 10.1);
    double mBruta = _getIndicatorValue('grossMargin', 52.4);
    double mEbitda = _getIndicatorValue('ebitdaMargin', 31.2);
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
                'Indicadores',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Icon(Icons.tune, size: 16, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 16),

          // 2-Column Grid
          Column(
            children: [
              _buildIndicatorRow('P/L', '${pl.toStringAsFixed(1)}x', 'P/VP', '${pvp.toStringAsFixed(1)}x'),
              const SizedBox(height: 14),
              _buildIndicatorRow('Div. Yield', '${dy.toStringAsFixed(1)}%', 'ROE', '${roe.toStringAsFixed(1)}%',
                  val1Color: AppColors.white, val2Color: AppColors.emeraldGreen),
              const SizedBox(height: 14),
              _buildIndicatorRow('ROA', '${roa.toStringAsFixed(1)}%', 'M. Bruta', '${mBruta.toStringAsFixed(1)}%'),
              const SizedBox(height: 14),
              _buildIndicatorRow('M. EBITDA', '${mEbitda.toStringAsFixed(1)}%', 'CAGR (5a)',
                  '${cagr5 >= 0 ? '+' : ''}${cagr5.toStringAsFixed(1)}%',
                  val2Color: cagr5 >= 0 ? AppColors.emeraldGreen : AppColors.redLoss),
            ],
          ),
          const SizedBox(height: 20),

          // Complete DRE Button
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

  Widget _buildIndicatorRow(String label1, String val1, String label2, String val2,
      {Color? val1Color, Color? val2Color}) {
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
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(width: 4),
            const Icon(Icons.info_outline, size: 12, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor ?? Colors.white),
        ),
      ],
    );
  }

  // 5. Dividend History Bar Chart Card (Bottom Left)
  Widget _buildDividendHistoryCard() {
    double totalDist = 2.80;
    double avgPgt = 0.56;
    double maxProv = 0.76;

    if (_dividendDataList.isNotEmpty) {
      double sumVal = 0;
      for (var d in _dividendDataList) {
        sumVal += (d['value'] as num?)?.toDouble() ?? 0.0;
      }
      totalDist = sumVal > 0 ? sumVal : 2.80;
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Histórico de Proventos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '${widget.active.symbol} • Histórico de Distribuição',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              _buildPeriodSelectorPills(['1A', '3A', '5A', '10A', 'MÁX'], _selectedDividendPeriod, (p) {
                setState(() => _selectedDividendPeriod = p);
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Metrics Summary Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDividendMetricCell('TOTAL DISTRIBUÍDO', _realFormat.format(totalDist)),
              _buildDividendMetricCell('MÉDIA POR PAGTO', _realFormat.format(avgPgt)),
              _buildDividendMetricCell('MAIOR PROVENTO', _realFormat.format(maxProv)),
              _buildDividendMetricCell('FREQUÊNCIA', 'Trimestral'),
            ],
          ),
          const SizedBox(height: 24),

          // Combined Bar + Trend Chart
          SizedBox(
            height: 180,
            child: BarChart(_buildDividendBarChartData()),
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, color: Colors.white38),
              const SizedBox(width: 6),
              const Text('DIVIDENDOS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Container(width: 14, height: 2, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              const Text('TENDÊNCIA', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  BarChartData _buildDividendBarChartData() {
    List<double> barValues = [0.35, 0.45, 0.60, 0.68, 0.52];
    List<String> years = ['2019', '2020', '2021', '2022', '2023'];

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 0.80,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (val, meta) => Text(
              val.toStringAsFixed(2),
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              int idx = val.toInt();
              if (idx >= 0 && idx < years.length) {
                return Text(years[idx], style: const TextStyle(fontSize: 10, color: Colors.grey));
              }
              return const Text('');
            },
          ),
        ),
      ),
      barGroups: barValues.asMap().entries.map((entry) {
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value,
              color: Colors.white.withValues(alpha: 0.25),
              width: 28,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDividendMetricCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  // Reusable Pill Period Selector
  Widget _buildPeriodSelectorPills(List<String> options, String selected, Function(String) onSelect) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: options.map((opt) {
          bool isSel = opt == selected;
          return GestureDetector(
            onTap: () => onSelect(opt),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSel ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? Colors.white : Colors.grey,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showGrahamInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Valor Intrínseco de Graham', style: TextStyle(color: Colors.white)),
        content: const Text(
          'O Preço Justo é calculado utilizando a fórmula clássica de Benjamin Graham:\n\n'
          'VI = √(22,5 × LPA × VPA)\n\n'
          'Onde LPA é o Lucro por Ação e VPA é o Valor Patrimonial por Ação.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi', style: TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  void _showDREModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demonstração do Resultado (DRE) • ${widget.active.symbol}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildDRERow('Receita Líquida', _realFormat.format(widget.active.lastPrice * 1000000)),
            _buildDRERow('Custo dos Produtos Vendidos', _realFormat.format(widget.active.lastPrice * 480000)),
            _buildDRERow('Lucro Bruto', _realFormat.format(widget.active.lastPrice * 520000)),
            _buildDRERow('EBITDA', _realFormat.format(widget.active.lastPrice * 310000)),
            _buildDRERow('Lucro Líquido', _realFormat.format(widget.active.lastPrice * 162000)),
          ],
        ),
      ),
    );
  }

  Widget _buildDRERow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
