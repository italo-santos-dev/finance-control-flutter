import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/active_model.dart';
import 'package:flutter_investment_control/models/asset_model.dart';
import 'package:flutter_investment_control/models/transaction_model.dart';
import 'package:flutter_investment_control/pages/active/details/active_details_page.dart';
import 'package:flutter_investment_control/pages/active/extract/extract_page.dart';
import 'package:flutter_investment_control/pages/active/widgets/add_asset_modal/add_asset_modal.dart';
import 'package:flutter_investment_control/pages/active/widgets/portfolio_allocation_chart.dart';
import 'package:flutter_investment_control/pages/active/widgets/portfolio_assets_carousel.dart';
import 'package:flutter_investment_control/pages/active/widgets/portfolio_evolution_chart.dart';
import 'package:flutter_investment_control/pages/active/widgets/portfolio_header.dart';
import 'package:flutter_investment_control/pages/active/widgets/portfolio_monthly_dividends.dart';
import 'package:flutter_investment_control/pages/active/widgets/portfolio_summary_cards.dart';
import 'package:flutter_investment_control/pages/active/widgets/portfolio_top_performance.dart';
import 'package:flutter_investment_control/pages/active/widgets/portfolio_upcoming_dividends.dart';

import 'package:flutter_investment_control/services/asset_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssetList extends StatefulWidget {
  const AssetList({super.key});

  @override
  State<AssetList> createState() => _AssetListState();
}

class _AssetListState extends State<AssetList> {
  List<Asset> assets = [];
  bool isLoading = true;
  bool _hideValues = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController tickerController = TextEditingController();
  final TextEditingController segmentController = TextEditingController();
  final TextEditingController activeTypeController = TextEditingController();
  final TextEditingController averagePriceController = TextEditingController();
  final TextEditingController currentPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  @override
  void dispose() {
    tickerController.dispose();
    segmentController.dispose();
    activeTypeController.dispose();
    averagePriceController.dispose();
    currentPriceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    try {
      setState(() => isLoading = true);

      final List<Asset> loadedAssets = List.from(context.read<AssetProvider>().assets);
      final prefs = await SharedPreferences.getInstance();
      final assetListJson = prefs.getStringList('assets');

      if (assetListJson != null) {
        final List<Asset> assetsFromPrefs = assetListJson.map((json) {
          final assetMap = jsonDecode(json);
          final transactionsList = assetMap['transactions'] != null
              ? List<Transaction>.from(assetMap['transactions'].map((t) {
                  return Transaction(
                    date: DateTime.tryParse(t['date'] ?? '') ?? DateTime.now(),
                    ticker: t['ticker'] ?? '',
                    type: t['type'] == 'buy' ? TransactionType.buy : TransactionType.sell,
                    market: t['market'] ?? 'B3',
                    maturityDate: DateTime.tryParse(t['maturityDate'] ?? '') ?? DateTime.now(),
                    institution: t['institution'] ?? 'Corretora',
                    tradingCode: t['tradingCode'] ?? '',
                    quantity: t['quantity'] ?? 0,
                    price: (t['price'] as num?)?.toDouble() ?? 0.0,
                    amount: (t['amount'] as num?)?.toDouble() ?? 0.0,
                  );
                }))
              : <Transaction>[];

          return Asset.fromJson(assetMap)..setTransactions = transactionsList;
        }).toList();

        for (final assetFromPrefs in assetsFromPrefs) {
          if (!loadedAssets.any((a) => a.ticker == assetFromPrefs.ticker)) {
            loadedAssets.add(assetFromPrefs);
          }
        }
      }

      // Initial default assets if portfolio is brand new
      if (loadedAssets.isEmpty) {
        loadedAssets.addAll([
          Asset(
            ticker: 'ITUB4',
            activeType: 'Ação',
            segment: 'Itaú Unibanco',
            averagePrice: 28.50,
            currentPrice: 34.90,
            quantity: 1500,
            transactions: [],
            isFullyLiquidated: false,
          ),
          Asset(
            ticker: 'HGLG11',
            activeType: 'FII',
            segment: 'CSHG Logística',
            averagePrice: 160.00,
            currentPrice: 190.17,
            quantity: 350,
            transactions: [],
            isFullyLiquidated: false,
          ),
          Asset(
            ticker: 'WEGE3',
            activeType: 'Ação',
            segment: 'WEG S.A.',
            averagePrice: 32.00,
            currentPrice: 39.00,
            quantity: 800,
            transactions: [],
            isFullyLiquidated: false,
          ),
          Asset(
            ticker: 'VALE3',
            activeType: 'Ação',
            segment: 'Vale S.A.',
            averagePrice: 62.00,
            currentPrice: 68.50,
            quantity: 500,
            transactions: [],
            isFullyLiquidated: false,
          ),
        ]);
      }

      setState(() {
        assets = loadedAssets;
        isLoading = false;
      });

      _saveAssets();
      context.read<AssetProvider>().updateAssets(loadedAssets);
    } catch (e) {
      debugPrint('Error loading assets: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _saveAssets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assetListJson = assets.map((asset) {
        final assetMap = asset.toJson();
        assetMap['transactions'] = asset.transactions
            .map((transaction) => {
                  'date': transaction.date.toIso8601String(),
                  'ticker': transaction.ticker,
                  'type': transaction.type.toString(),
                  'market': transaction.market,
                  'maturityDate': transaction.maturityDate.toIso8601String(),
                  'institution': transaction.institution,
                  'tradingCode': transaction.tradingCode,
                  'quantity': transaction.quantity,
                  'price': transaction.price,
                  'amount': transaction.amount,
                })
            .toList();
        return jsonEncode(assetMap);
      }).toList();
      await prefs.setStringList('assets', assetListJson);
    } catch (e) {
      debugPrint('Error saving assets: $e');
    }
  }

  void _addAsset(Asset newAsset) {
    final existingAsset = assets.firstWhereOrNull((a) => a.ticker.toUpperCase() == newAsset.ticker.toUpperCase());

    if (existingAsset != null) {
      final totalQuantity = existingAsset.quantity + newAsset.quantity;
      final totalInvested = (existingAsset.averagePrice * existingAsset.quantity) +
          (newAsset.averagePrice * newAsset.quantity);
      final updatedAveragePrice = totalQuantity > 0 ? (totalInvested / totalQuantity) : 0.0;

      existingAsset.averagePrice = updatedAveragePrice;
      existingAsset.quantity = totalQuantity;
      if (newAsset.currentPrice > 0) {
        existingAsset.currentPrice = newAsset.currentPrice;
      }
    } else {
      assets.add(newAsset);
    }

    setState(() {});
    _saveAssets();
    context.read<AssetProvider>().updateAssets(assets);
  }

  void _deleteAsset(Asset asset) {
    setState(() {
      assets.removeWhere((a) => a.ticker == asset.ticker);
    });
    _saveAssets();
    context.read<AssetProvider>().updateAssets(assets);
  }

  double get _totalPortfolioEquity {
    return assets.fold(0.0, (sum, item) => sum + item.totalAmount);
  }

  double get _monthlyYieldPct {
    if (assets.isEmpty) return 2.45;
    double totalCost = assets.fold(0.0, (sum, item) => sum + (item.averagePrice * item.quantity));
    if (totalCost == 0) return 0.0;
    return ((_totalPortfolioEquity - totalCost) / totalCost) * 100;
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Dashboard Page Header
                        PortfolioHeader(
                          hideValues: _hideValues,
                          onToggleHideValues: () => setState(() => _hideValues = !_hideValues),
                          onAddAsset: () => _showAddAssetDialog(context),
                        ),
                        const SizedBox(height: 16),

                        // 2. Top Summary Metrics Grid
                        PortfolioSummaryCards(
                          totalEquity: _totalPortfolioEquity,
                          monthlyYieldPct: _monthlyYieldPct,
                          accumulatedDividends: 4520.00,
                          projectedDividends: 850.00,
                          hideValues: _hideValues,
                        ),
                        const SizedBox(height: 20),

                        // 3. Asset Cards Carousel / Grid
                        PortfolioAssetsCarousel(
                          assets: assets,
                          totalPortfolioValue: _totalPortfolioEquity,
                          hideValues: _hideValues,
                          onSelectAsset: (asset) => _showAssetActionModal(context, asset),
                          onViewAll: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${assets.length} ativos em carteira')),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // 4. Responsive Main Section (2 Columns on Wide Screens, Stacked on Mobile)
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column (Evolution Chart, Top 5 Performance, Monthly Dividends Bar Chart)
                              Expanded(
                                flex: 7,
                                child: Column(
                                  children: [
                                    PortfolioEvolutionChart(
                                      totalEquity: _totalPortfolioEquity,
                                      hideValues: _hideValues,
                                    ),
                                    const SizedBox(height: 16),
                                    PortfolioTopPerformance(
                                      assets: assets,
                                      onViewAll: () {},
                                    ),
                                    const SizedBox(height: 16),
                                    PortfolioMonthlyDividends(
                                      accumulatedDividends: 4520.00,
                                      hideValues: _hideValues,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Right Column (Allocation Donut Chart, Upcoming Dividend Calendar)
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    PortfolioAllocationChart(
                                      assets: assets,
                                      totalPortfolioValue: _totalPortfolioEquity,
                                    ),
                                    const SizedBox(height: 16),
                                    const PortfolioUpcomingDividends(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          // Mobile Stacked Layout
                          Column(
                            children: [
                              PortfolioEvolutionChart(
                                totalEquity: _totalPortfolioEquity,
                                hideValues: _hideValues,
                              ),
                              const SizedBox(height: 16),
                              PortfolioAllocationChart(
                                assets: assets,
                                totalPortfolioValue: _totalPortfolioEquity,
                              ),
                              const SizedBox(height: 16),
                              PortfolioTopPerformance(
                                assets: assets,
                                onViewAll: () {},
                              ),
                              const SizedBox(height: 16),
                              PortfolioMonthlyDividends(
                                accumulatedDividends: 4520.00,
                                hideValues: _hideValues,
                              ),
                              const SizedBox(height: 16),
                              const PortfolioUpcomingDividends(),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  void _showAddAssetDialog(BuildContext context) {
    AddAssetModal.show(
      context,
      existingAssets: assets,
      onAssetAdded: (newAsset) {
        _addAsset(newAsset);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ativo ${newAsset.ticker} adicionado à sua carteira com sucesso!'),
            backgroundColor: AppColors.cardDark,
          ),
        );
      },
    );
  }

  void _showAssetActionModal(BuildContext context, Asset asset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Opções para ${asset.ticker}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.analytics_outlined, color: AppColors.blueAccent),
                title: const Text('Ver Análise Detalhada (TradingView/Investidor10)', style: TextStyle(color: Colors.white, fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActiveDetailsPage(
                        active: Active(
                          icon: 'https://icons.brapi.dev/icons/${asset.ticker}.png',
                          name: asset.segment.isNotEmpty ? asset.segment : asset.ticker,
                          symbol: asset.ticker,
                          lastPrice: asset.currentPrice,
                          sector: asset.activeType,
                          segment: asset.segment,
                          dividendYield: 6.8,
                          lastYearHigh: asset.currentPrice * 1.15,
                          lastYearLow: asset.currentPrice * 0.85,
                        ),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined, color: AppColors.emeraldGreen),
                title: const Text('Ver Extrato de Transações', style: TextStyle(color: Colors.white, fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ExtratoPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.redLoss),
                title: const Text('Remover Ativo da Carteira', style: TextStyle(color: AppColors.redLoss, fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context, asset);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Asset asset) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Excluir Ativo', style: TextStyle(color: Colors.white)),
        content: Text('Deseja realmente remover ${asset.ticker} da sua carteira?', style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.redLoss),
            onPressed: () {
              _deleteAsset(asset);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${asset.ticker} removido da carteira.')),
              );
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, bool uppercase = false}) {
    return TextFormField(
      controller: controller,
      textCapitalization: uppercase ? TextCapitalization.characters : TextCapitalization.none,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: _inputDecoration(label),
      validator: (val) => (val == null || val.trim().isEmpty) ? 'Campo obrigatório' : null,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      filled: true,
      fillColor: AppColors.inputDark,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderDark)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderDark)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primaryBlue)),
    );
  }
}
