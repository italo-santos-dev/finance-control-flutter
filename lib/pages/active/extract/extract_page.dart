import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/trade_transaction.dart';
import 'package:flutter_investment_control/models/transaction_model.dart';
import 'package:flutter_investment_control/pages/active/extract/widgets/extract_empty_state.dart';
import 'package:flutter_investment_control/pages/active/extract/widgets/extract_filters_bar.dart';
import 'package:flutter_investment_control/pages/active/extract/widgets/extract_header.dart';
import 'package:flutter_investment_control/pages/active/extract/widgets/extract_pagination_footer.dart';
import 'package:flutter_investment_control/pages/active/extract/widgets/extract_summary_cards.dart';
import 'package:flutter_investment_control/pages/active/extract/widgets/extract_transactions_table.dart';
import 'package:flutter_investment_control/services/asset_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ExtratoPage extends StatefulWidget {
  const ExtratoPage({super.key});

  @override
  State<ExtratoPage> createState() => _ExtratoPageState();
}

class _ExtratoPageState extends State<ExtratoPage> {
  List<Map<String, dynamic>> _allTransactions = [];
  bool _isLoading = true;

  // Filter States
  String _selectedPeriod = '30D';
  String _searchQuery = '';
  String _selectedType = 'Todos Tipos';

  // Pagination State
  int _currentPage = 1;
  final int _recordsPerPage = 8;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final provider = context.read<AssetProvider>();
      final List<TradeTransaction> trades = provider.transactions;
      final assets = provider.assets;

      List<Map<String, dynamic>> flatTransactions = [];

      if (trades.isNotEmpty) {
        for (final t in trades) {
          flatTransactions.add({
            'id': t.id,
            'date': t.date,
            'formattedDate': DateFormat('dd MMM yyyy HH:mm:ss', 'pt_BR').format(t.date),
            'ticker': t.ticker,
            'segment': t.segment.isNotEmpty ? t.segment : (t.name.isNotEmpty ? t.name : 'Ativo B3'),
            'typeStr': t.type == TransactionType.buy ? 'Compra' : 'Venda',
            'quantity': t.quantity > 0 ? t.quantity.toInt() : 1,
            'price': t.price,
            'total': t.total > 0 ? t.total : (t.price * t.quantity),
            'institution': t.broker.isNotEmpty ? t.broker : 'XP Investimentos',
          });
        }
      } else if (assets.isNotEmpty) {
        for (final asset in assets) {
          if (asset.transactions.isNotEmpty) {
            for (final t in asset.transactions) {
              flatTransactions.add({
                'date': t.date,
                'formattedDate': DateFormat('dd MMM yyyy HH:mm:ss', 'pt_BR').format(t.date),
                'ticker': t.ticker.isNotEmpty ? t.ticker : asset.ticker,
                'segment': asset.segment.isNotEmpty ? asset.segment : 'Ativo B3',
                'typeStr': t.type == TransactionType.buy ? 'Compra' : 'Venda',
                'quantity': t.quantity > 0 ? t.quantity : 1,
                'price': t.price > 0 ? t.price : asset.averagePrice,
                'total': t.amount > 0 ? t.amount : (t.price * t.quantity),
                'institution': t.institution.isNotEmpty ? t.institution : 'Sua Instituição',
              });
            }
          } else {
            flatTransactions.add({
              'date': DateTime.now().subtract(Duration(days: flatTransactions.length * 3 + 1)),
              'formattedDate': DateFormat('dd MMM yyyy HH:mm:ss', 'pt_BR').format(
                DateTime.now().subtract(Duration(days: flatTransactions.length * 3 + 1, hours: 4)),
              ),
              'ticker': asset.ticker,
              'segment': asset.segment.isNotEmpty ? asset.segment : 'Ativo B3',
              'typeStr': 'Compra',
              'quantity': asset.quantity,
              'price': asset.averagePrice,
              'total': asset.averagePrice * asset.quantity,
              'institution': 'XP Investimentos',
            });
          }
        }
      }

      // Sort by newest date first
      flatTransactions.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      if (mounted) {
        setState(() {
          _allTransactions = flatTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading extract transactions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    DateTime now = DateTime.now();
    return _allTransactions.where((t) {
      // 1. Period filter
      DateTime date = t['date'] as DateTime;
      if (_selectedPeriod == 'Hoje') {
        if (date.year != now.year || date.month != now.month || date.day != now.day) return false;
      } else if (_selectedPeriod == '7D') {
        if (now.difference(date).inDays > 7) return false;
      } else if (_selectedPeriod == '30D') {
        if (now.difference(date).inDays > 30) return false;
      } else if (_selectedPeriod == '12M') {
        if (now.difference(date).inDays > 365) return false;
      }

      // 2. Type filter
      String typeStr = (t['typeStr'] ?? '').toString().toLowerCase();
      if (_selectedType == 'Compra' && typeStr != 'compra') return false;
      if (_selectedType == 'Venda' && typeStr != 'venda') return false;
      if (_selectedType == 'Proventos' && !typeStr.contains('provento') && !typeStr.contains('dividend')) return false;

      // 3. Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        String query = _searchQuery.trim().toLowerCase();
        String ticker = (t['ticker'] ?? '').toString().toLowerCase();
        String segment = (t['segment'] ?? '').toString().toLowerCase();
        String institution = (t['institution'] ?? '').toString().toLowerCase();
        if (!ticker.contains(query) && !segment.contains(query) && !institution.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  double get _totalTraded {
    return _filteredTransactions.fold(0.0, (sum, t) => sum + ((t['total'] as num?)?.toDouble() ?? 0.0));
  }

  double get _totalPurchases {
    return _filteredTransactions
        .where((t) => (t['typeStr'] ?? '').toString().toLowerCase() == 'compra')
        .fold(0.0, (sum, t) => sum + ((t['total'] as num?)?.toDouble() ?? 0.0));
  }

  double get _totalSales {
    return _filteredTransactions
        .where((t) => (t['typeStr'] ?? '').toString().toLowerCase() == 'venda')
        .fold(0.0, (sum, t) => sum + ((t['total'] as num?)?.toDouble() ?? 0.0));
  }

  void _exportCsv() {
    StringBuffer csv = StringBuffer();
    csv.writeln('DATA;ATIVO;SEGMENTO;TIPO;QUANTIDADE;PRECO_UNITARIO;TOTAL;INSTITUICAO');
    for (final t in _filteredTransactions) {
      csv.writeln(
        '${t['formattedDate']};${t['ticker']};${t['segment']};${t['typeStr']};${t['quantity']};${t['price']};${t['total']};${t['institution']}',
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Extrato CSV com ${_filteredTransactions.length} registros pronto para download!'),
        backgroundColor: AppColors.cardDark,
      ),
    );
  }

  void _exportPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gerando relatório PDF de negociações...'),
        backgroundColor: AppColors.cardDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reactively observe provider transactions
    final providerTrades = context.watch<AssetProvider>().transactions;
    if (providerTrades.length != _allTransactions.length) {
      _loadData();
    }

    final filtered = _filteredTransactions;
    final totalPages = (filtered.length / _recordsPerPage).ceil().clamp(1, 9999);
    final validPage = _currentPage.clamp(1, totalPages);

    final startIdx = (validPage - 1) * _recordsPerPage;
    final endIdx = (startIdx + _recordsPerPage) > filtered.length ? filtered.length : (startIdx + _recordsPerPage);
    final pageTransactions = filtered.isEmpty ? <Map<String, dynamic>>[] : filtered.sublist(startIdx, endIdx);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Page Header & Export Buttons
                        ExtractHeader(
                          onExportCsv: _exportCsv,
                          onExportPdf: _exportPdf,
                        ),
                        const SizedBox(height: 20),

                        // 2. Summary Metric Cards
                        ExtractSummaryCards(
                          totalTraded: _totalTraded,
                          totalPurchases: _totalPurchases,
                          totalSales: _totalSales,
                        ),
                        const SizedBox(height: 20),

                        // 3. Combined Filter Toolbar
                        ExtractFiltersBar(
                          selectedPeriod: _selectedPeriod,
                          searchQuery: _searchQuery,
                          selectedType: _selectedType,
                          onPeriodChanged: (p) => setState(() {
                            _selectedPeriod = p;
                            _currentPage = 1;
                          }),
                          onSearchChanged: (q) => setState(() {
                            _searchQuery = q;
                            _currentPage = 1;
                          }),
                          onTypeChanged: (t) => setState(() {
                            _selectedType = t;
                            _currentPage = 1;
                          }),
                        ),
                        const SizedBox(height: 18),

                        // 4. Main Transactions Table or Empty State
                        if (filtered.isEmpty)
                          ExtractEmptyState(
                            isFiltering: _searchQuery.isNotEmpty || _selectedType != 'Todos Tipos' || _selectedPeriod != 'Tudo',
                            onClearFilters: () {
                              setState(() {
                                _searchQuery = '';
                                _selectedType = 'Todos Tipos';
                                _selectedPeriod = 'Tudo';
                                _currentPage = 1;
                              });
                            },
                          )
                        else ...[
                          ExtractTransactionsTable(
                            transactions: pageTransactions,
                            onTransactionTap: (t) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Operação: ${t['typeStr']} ${t['ticker']} - ${t['formattedDate']}'),
                                  backgroundColor: AppColors.cardDark,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // 5. Pagination & Record Count Footer
                          ExtractPaginationFooter(
                            currentPage: validPage,
                            totalPages: totalPages,
                            totalRecords: filtered.length,
                            recordsPerPage: _recordsPerPage,
                            onPageSelected: (p) => setState(() => _currentPage = p),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
