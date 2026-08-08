import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/asset_model.dart';
import 'package:flutter_investment_control/models/trade_transaction.dart';
import 'package:flutter_investment_control/models/transaction_model.dart';
import 'package:flutter_investment_control/pages/active/widgets/add_asset_modal/add_asset_operation_form.dart';
import 'package:flutter_investment_control/pages/active/widgets/add_asset_modal/add_asset_search_field.dart';
import 'package:flutter_investment_control/pages/active/widgets/add_asset_modal/add_asset_selected_card.dart';
import 'package:flutter_investment_control/pages/active/widgets/add_asset_modal/add_asset_summary_preview.dart';
import 'package:flutter_investment_control/services/apis/api_service.dart';
import 'package:flutter_investment_control/services/asset_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddAssetModal extends StatefulWidget {
  final List<Asset> existingAssets;
  final Function(Asset)? onAssetAdded;

  const AddAssetModal({
    super.key,
    required this.existingAssets,
    this.onAssetAdded,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Asset> existingAssets,
    Function(Asset)? onAssetAdded,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddAssetModal(
        existingAssets: existingAssets,
        onAssetAdded: onAssetAdded,
      ),
    );
  }

  @override
  State<AddAssetModal> createState() => _AddAssetModalState();
}

class _AddAssetModalState extends State<AddAssetModal> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _selectedAsset;
  bool _isLoadingPrice = false;
  bool _priceUnavailable = false;
  double _currentPrice = 0.0;
  double _changePercent = 0.0;
  String _updateTime = '';

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController();
  final TextEditingController _feesController = TextEditingController();
  String _selectedBroker = 'XP Investimentos';
  DateTime _purchaseDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _feesController.dispose();
    super.dispose();
  }

  Future<void> _onAssetSelected(Map<String, dynamic> asset) async {
    setState(() {
      _selectedAsset = asset;
      _isLoadingPrice = true;
      _priceUnavailable = false;
    });

    String ticker = (asset['ticker'] ?? asset['symbol'] ?? '').toString().toUpperCase();

    try {
      final details = await _apiService.getAssetDetails(ticker);

      if (details != null && details['currentPrice'] != null && (details['currentPrice'] as num) > 0) {
        double price = (details['currentPrice'] as num).toDouble();
        double change = (details['change'] as num?)?.toDouble() ?? 0.0;

        if (mounted) {
          setState(() {
            _currentPrice = price;
            _changePercent = change;
            _updateTime = DateFormat('HH:mm').format(DateTime.now());
            _isLoadingPrice = false;
            _priceUnavailable = false;
            if (_purchasePriceController.text.isEmpty) {
              _purchasePriceController.text = price.toStringAsFixed(2);
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentPrice = (asset['lastPrice'] as num?)?.toDouble() ?? 0.0;
            _isLoadingPrice = false;
            _priceUnavailable = _currentPrice <= 0;
            if (_currentPrice > 0 && _purchasePriceController.text.isEmpty) {
              _purchasePriceController.text = _currentPrice.toStringAsFixed(2);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPrice = false;
          _priceUnavailable = true;
        });
      }
    }
  }

  Future<void> _saveAsset() async {
    if (_selectedAsset == null) return;

    double qty = double.tryParse(_quantityController.text.replaceAll(',', '.').trim()) ?? 0.0;
    double buyPrice = double.tryParse(_purchasePriceController.text.replaceAll(',', '.').trim()) ?? 0.0;
    double fees = double.tryParse(_feesController.text.replaceAll(',', '.').trim()) ?? 0.0;

    if (qty <= 0 || buyPrice <= 0) return;

    setState(() => _isSaving = true);

    String ticker = (_selectedAsset!['ticker'] ?? _selectedAsset!['symbol'] ?? '').toString().toUpperCase();
    String name = (_selectedAsset!['name'] ?? _selectedAsset!['segment'] ?? ticker).toString();
    String type = (_selectedAsset!['activeType'] ?? 'Ação').toString();
    String segment = (_selectedAsset!['segment'] ?? name).toString();

    // 1. Create SQLite TradeTransaction (Single Source of Truth)
    final newTrade = TradeTransaction(
      id: 'trade-${DateTime.now().millisecondsSinceEpoch}',
      ticker: ticker,
      name: name,
      type: TransactionType.buy,
      quantity: qty,
      price: buyPrice,
      fees: fees,
      total: (qty * buyPrice) + fees,
      date: _purchaseDate,
      broker: _selectedBroker,
      activeType: type,
      segment: segment,
      createdAt: DateTime.now(),
    );

    // 2. Persist to SQLite Database & update Provider state
    await context.read<AssetProvider>().addTradeTransaction(newTrade);

    if (widget.onAssetAdded != null) {
      final legacyAsset = Asset(
        ticker: ticker,
        activeType: type,
        segment: segment,
        averagePrice: buyPrice,
        currentPrice: _currentPrice > 0 ? _currentPrice : buyPrice,
        quantity: qty.toInt(),
        transactions: [newTrade.toLegacyTransaction()],
        isFullyLiquidated: false,
      );
      widget.onAssetAdded!(legacyAsset);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  bool get _isValid {
    if (_selectedAsset == null) return false;
    double qty = double.tryParse(_quantityController.text.replaceAll(',', '.').trim()) ?? 0.0;
    double buyPrice = double.tryParse(_purchasePriceController.text.replaceAll(',', '.').trim()) ?? 0.0;
    return qty > 0 && buyPrice > 0;
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> known = [
      {'ticker': 'PETR4', 'name': 'Petróleo Brasileiro S.A. Petrobras', 'activeType': 'Ação', 'segment': 'Petróleo e Gás'},
      {'ticker': 'VALE3', 'name': 'Vale S.A.', 'activeType': 'Ação', 'segment': 'Mineração'},
      {'ticker': 'ITUB4', 'name': 'Itaú Unibanco Holding S.A.', 'activeType': 'Ação', 'segment': 'Bancos'},
      {'ticker': 'BBDC4', 'name': 'Banco Bradesco S.A.', 'activeType': 'Ação', 'segment': 'Bancos'},
      {'ticker': 'BBAS3', 'name': 'Banco do Brasil S.A.', 'activeType': 'Ação', 'segment': 'Bancos'},
      {'ticker': 'SANB11', 'name': 'Banco Santander Brasil S.A.', 'activeType': 'Ação', 'segment': 'Bancos'},
      {'ticker': 'WEGE3', 'name': 'WEG S.A.', 'activeType': 'Ação', 'segment': 'Motores e Equipamentos'},
      {'ticker': 'HGLG11', 'name': 'CSHG Logística FII', 'activeType': 'FII', 'segment': 'Imóveis Industriais'},
      {'ticker': 'MXRF11', 'name': 'Maxi Renda FII', 'activeType': 'FII', 'segment': 'Títulos e Valores Mobiliários'},
      {'ticker': 'KNCR11', 'name': 'Kinea Rendimentos Imobiliários', 'activeType': 'FII', 'segment': 'Papel / CRI'},
      {'ticker': 'XPML11', 'name': 'XP Malls FII', 'activeType': 'FII', 'segment': 'Shoppings'},
      {'ticker': 'BTC', 'name': 'Bitcoin', 'activeType': 'Cripto', 'segment': 'Criptomoeda'},
      {'ticker': 'ETH', 'name': 'Ethereum', 'activeType': 'Cripto', 'segment': 'Smart Contracts'},
    ];

    double qty = double.tryParse(_quantityController.text.replaceAll(',', '.').trim()) ?? 0.0;
    double buyPrice = double.tryParse(_purchasePriceController.text.replaceAll(',', '.').trim()) ?? 0.0;
    double fees = double.tryParse(_feesController.text.replaceAll(',', '.').trim()) ?? 0.0;

    return Dialog(
      backgroundColor: AppColors.backgroundDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.borderDark)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.add_circle_outline, color: AppColors.primaryBlue, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Adicionar Novo Ativo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_selectedAsset == null)
                AddAssetSearchField(
                  knownAssets: known,
                  onAssetSelected: _onAssetSelected,
                )
              else ...[
                AddAssetSelectedCard(
                  assetData: _selectedAsset!,
                  currentPrice: _currentPrice,
                  changePercent: _changePercent,
                  updateTime: _updateTime,
                  isLoadingPrice: _isLoadingPrice,
                  priceUnavailable: _priceUnavailable,
                  onRetryPrice: () => _onAssetSelected(_selectedAsset!),
                  onChangeAsset: () => setState(() => _selectedAsset = null),
                ),
                const SizedBox(height: 16),

                AddAssetOperationForm(
                  quantityController: _quantityController,
                  purchasePriceController: _purchasePriceController,
                  feesController: _feesController,
                  selectedBroker: _selectedBroker,
                  purchaseDate: _purchaseDate,
                  onBrokerChanged: (b) => setState(() => _selectedBroker = b),
                  onDateSelected: (d) => setState(() => _purchaseDate = d),
                  onValuesChanged: () => setState(() {}),
                ),
                const SizedBox(height: 16),

                AddAssetSummaryPreview(
                  ticker: (_selectedAsset!['ticker'] ?? _selectedAsset!['symbol'] ?? '').toString().toUpperCase(),
                  assetName: (_selectedAsset!['name'] ?? _selectedAsset!['segment'] ?? '').toString(),
                  assetType: (_selectedAsset!['activeType'] ?? 'Ação').toString(),
                  quantity: qty,
                  purchasePrice: buyPrice,
                  fees: fees,
                  purchaseDate: _purchaseDate,
                  broker: _selectedBroker,
                ),
              ],
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isValid && !_isSaving ? _saveAsset : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: AppColors.inputDark,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSaving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text(
                          'Adicionar ativo',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
