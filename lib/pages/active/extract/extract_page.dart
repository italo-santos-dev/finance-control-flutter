import 'package:flutter/material.dart';
import 'package:flutter_investment_control/models/asset_model.dart';
import 'package:flutter_investment_control/models/transaction_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_investment_control/pages/active/extract/allTransactions/all_transactions_page.dart';
import 'package:flutter_investment_control/services/apis/api_service.dart';
import 'package:flutter_investment_control/services/asset_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class ExtratoPage extends StatefulWidget {
  ExtratoPage({Key? key}) : super(key: key);

  @override
  _ExtratoPageState createState() => _ExtratoPageState();
}

class _ExtratoPageState extends State<ExtratoPage> {
  late List<Asset> assets = [];

  final ApiService _apiService = ApiService();

  DateTime _parseDate(String dateString) {
    try {
      if (dateString == '-') {
        return DateTime(2000, 1, 1);
      }

      final parts = dateString.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);

        return DateTime(year, month, day);
      } else {
        throw FormatException('Formato de data inválido: $dateString');
      }
    } catch (e) {
      throw FormatException('Erro ao processar a data: $e');
    }
  }

  double _extractNumericValue(String valueString) {
    try {
      final cleanedValue =
          double.parse(valueString.replaceAll(RegExp(r'[^\d.]'), ''));
      return cleanedValue;
    } catch (e) {
      throw ArgumentError('Erro ao extrair valor numérico: $e');
    }
  }

  bool isAssetFullyLiquidated(Asset asset) {
    // Filtra as transações de compra
    final buyTransactions = asset.transactions
        .where((transaction) => transaction.type == TransactionType.buy)
        .toList();

    // Filtra as transações de venda
    final sellTransactions = asset.transactions
        .where((transaction) => transaction.type == TransactionType.sell)
        .toList();

    // Soma os valores comprados e vendidos
    final buyAmount = buyTransactions.fold(
        0.0, (sum, transaction) => sum + transaction.amount);
    final sellAmount = sellTransactions.fold(
        0.0, (sum, transaction) => sum + transaction.amount);

    // Soma as quantidades compradas e vendidas
    final buyQuantity = buyTransactions.fold(
        0, (sum, transaction) => sum + transaction.quantity);
    final sellQuantity = sellTransactions.fold(
        0, (sum, transaction) => sum + transaction.quantity);

    // Verifica se a quantidade comprada é igual à quantidade vendida ou se só há transações de venda
    return buyQuantity == sellQuantity ||
        buyQuantity == 0 && sellQuantity > 0 ||
        buyAmount < sellAmount;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtenha os ativos diretamente do Provider
      final List<Asset> loadedAssets = context.read<AssetProvider>().assets;

      // Obtenha os ativos salvos no SharedPreferences
      final assetList = prefs.getStringList('assets');

      if (assetList != null) {
        // Adicione os ativos do SharedPreferences apenas se não existirem no Provider
        final List<Asset> assetsFromPrefs = assetList.map((json) {
          final assetMap = jsonDecode(json);

          final transactionsList = assetMap['transactions'] != null
              ? List<Transaction>.from(assetMap['transactions'].map((t) {
                  return Transaction(
                    date: DateTime.parse(t['date']),
                    ticker: t['ticker'],
                    type: t['type'] == 'buy'
                        ? TransactionType.buy
                        : TransactionType.sell,
                    market: t['market'],
                    maturityDate: DateTime.parse(t['maturityDate']),
                    institution: t['institution'],
                    tradingCode: t['tradingCode'],
                    quantity: t['quantity'],
                    price: t['price'],
                    amount: t['amount'],
                  );
                }))
              : [];

          return Asset.fromJson(assetMap)
            ..setTransactions = transactionsList.cast<Transaction>();
        }).toList();

        for (final assetFromPrefs in assetsFromPrefs) {
          final existingAssetIndex = loadedAssets
              .indexWhere((asset) => asset.ticker == assetFromPrefs.ticker);

          if (existingAssetIndex == -1) {
            loadedAssets.add(assetFromPrefs);
          }
        }
      }

      setState(() {
        assets.clear();
        assets.addAll(loadedAssets);
      });

      // Imprima os ativos para análise
      print('Ativos carregados:');
      for (final asset in loadedAssets) {
        print(
            'Ticker: ${asset.ticker}, Quantidade: ${asset.quantity}, Preço Médio: ${asset.averagePrice}, Segmento: ${asset.segment}');
        // for (final transaction in asset.transactions) {
        //   print('   Transação: ${transaction.type}, Quantidade: ${transaction.quantity}, Preço: ${transaction.price}');
        // }
      }

      // Salve os ativos carregados no SharedPreferences
      final assetListToSave =
          loadedAssets.map((asset) => jsonEncode(asset.toJson())).toList();
      prefs.setStringList('assets', assetListToSave);

      print('Test: $assetListToSave');
    } catch (e) {
      print("Erro ao carregar ativos: $e");
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Antes de salvar, remova o "F" do ticker após os números
      final assetList = assets.map((asset) {
        final cleanedTicker = asset.ticker
            .replaceAllMapped(RegExp(r'(\d+)F'), (match) => match.group(1)!);

        return jsonEncode({
          ...asset.toJson(),
          'ticker': cleanedTicker,
        });
      }).toList();

      prefs.setStringList('assets', assetList);
    } catch (e) {
      print("Erro ao salvar dados: $e");
    }
  }

  @override
  void dispose() {
    _saveData();
    super.dispose();
  }

  @override
  void deactivate() {
    _saveData();
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
          color: Colors.white,
        ),
        title: const Text(
          'Extrato de Negociações',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.upload_file,
              color: Colors.white,
            ),
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['csv'],
              );
              if (result != null) {
                final PlatformFile file = result.files.single;

                try {
                  final lines = await File(file.path!).readAsLines();
                  final transactionsByTradingCode =
                      <String, List<Transaction>>{};

                  lines.skip(1).forEach((line) {
                    final columns = line.split(',');

                    final date = _parseDate(columns[0]);
                    final ticker = columns[5];
                    final type = _getTypeFromString(columns[1]);
                    final market = columns[2];
                    final maturityDate = _parseDate(columns[3]);
                    final institution = columns[4];
                    final tradingCode = columns[5];
                    final quantity = int.parse(columns[6]);
                    final price = _extractNumericValue(columns[7]);
                    final amount = _extractNumericValue(columns[8]);

                    final transaction = Transaction(
                      date: date,
                      ticker: ticker,
                      type: type,
                      market: market,
                      maturityDate: maturityDate,
                      institution: institution,
                      tradingCode: tradingCode,
                      quantity: quantity,
                      price: price,
                      amount: amount,
                    );

                    transactionsByTradingCode
                        .putIfAbsent(tradingCode, () => [])
                        .add(transaction);
                  });

                  transactionsByTradingCode.entries.forEach((entry) async {
                    final tradingCode = entry.key;
                    final transactions = entry.value;

                    final existingAssetIndex = assets.indexWhere((asset) =>
                        asset.ticker ==
                        tradingCode.replaceAllMapped(
                            RegExp(r'(\d+)F'), (match) => match.group(1)!));

                    if (existingAssetIndex != -1) {
                      final existingAsset = assets[existingAssetIndex];
                      existingAsset.transactions.addAll(transactions);

                      final totalAmount = transactions.fold(
                          0.0, (sum, transaction) => sum + transaction.amount);
                      final totalQuantity = transactions.fold(
                          0, (sum, transaction) => sum + transaction.quantity);
                      final averagePrice = totalAmount / totalQuantity;

                      if (totalQuantity > 0) {
                        existingAsset.averagePrice = averagePrice;
                      }

                      existingAsset.quantity += totalQuantity;

                      final assetDetails = await _apiService.getAssetDetails(
                          tradingCode.replaceAllMapped(
                              RegExp(r'(\d+)F'), (match) => match.group(1)!));

                      if (assetDetails != null) {
                        setState(() {
                          existingAsset.currentPrice =
                              assetDetails['currentPrice'].toDouble();
                          existingAsset.segment =
                              assetDetails['segment'].toString();
                        });
                      }

                      // Verificar se o ativo foi completamente liquidado
                      existingAsset.isFullyLiquidated =
                          isAssetFullyLiquidated(existingAsset);

                      // Atualizar o estado no Provider
                      context.read<AssetProvider>().updateAssets(assets);
                      _saveData();
                    } else {
                      final newAsset = Asset(
                        ticker: tradingCode.replaceAllMapped(
                            RegExp(r'(\d+)F'), (match) => match.group(1)!),
                        quantity: transactions.fold(0,
                            (sum, transaction) => sum + transaction.quantity),
                        averagePrice: transactions.fold(
                                0.0,
                                (sum, transaction) =>
                                    sum + transaction.amount) /
                            transactions.fold(
                                0,
                                (sum, transaction) =>
                                    sum + transaction.quantity),
                        transactions: transactions,
                        currentPrice: 0.0,
                        isFullyLiquidated: false,
                        segment: '',
                        activeType: '',
                      );

                      final assetDetails = await _apiService.getAssetDetails(
                          tradingCode.replaceAllMapped(
                              RegExp(r'(\d+)F'), (match) => match.group(1)!));

                      if (assetDetails != null) {
                        setState(() {
                          newAsset.currentPrice =
                              assetDetails['currentPrice'].toDouble();
                          newAsset.segment = assetDetails['segment'].toString();
                          newAsset.activeType =
                              assetDetails['activeType'].toString();
                        });
                      }

                      // Verificar se o ativo foi completamente liquidado
                      newAsset.isFullyLiquidated =
                          isAssetFullyLiquidated(newAsset);

                      assets.add(newAsset);

                      // Atualizar o estado no Provider
                      context.read<AssetProvider>().updateAssets(assets);
                      _saveData();
                    }
                  });
                  // setState(() {
                  //   // Não precisamos mais da lista newAssets
                  // });
                } catch (e) {
                  print("Erro ao processar o arquivo CSV: $e");
                }
              } else {
                // Usuário cancelou o seletor de arquivos
              }
            },
          ),
        ],
      ),
      body: Consumer<AssetProvider>(
        builder: (context, assetProvider, _) {
          // Ordena os ativos com base na data da transação mais recente
          assets.forEach((asset) {
            asset.transactions.sort((a, b) => b.maturityDate.compareTo(a.date));
          });

          assets.sort((a, b) {
            DateTime? lastTransactionDateA =
                a.transactions.isNotEmpty ? a.transactions.first.date : null;
            DateTime? lastTransactionDateB =
                b.transactions.isNotEmpty ? b.transactions.first.date : null;

            // Lida com ativos sem transações
            if (lastTransactionDateA == null && lastTransactionDateB == null) {
              return 0;
            } else if (lastTransactionDateA == null) {
              return 1;
            } else if (lastTransactionDateB == null) {
              return -1;
            }

            // Ordena com base na data mais recente
            return lastTransactionDateB.compareTo(lastTransactionDateA);
          });

          return ListView.builder(
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(12),
                          ),
                        ),
                        title: Text(
                          '${asset.ticker} - ${asset.quantity} Cotas',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text(
                              'Custo Médio: ${asset.averagePrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: asset.transactions.length > 1
                            ? 1
                            : asset.transactions.length,
                        itemBuilder: (context, transactionIndex) {
                          final transaction =
                              asset.transactions[transactionIndex];
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transação: ${transaction.quantity} unidades por ${(transaction.price * transaction.quantity.toDouble()).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Data: ${transaction.date.toString()}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mercado: ${transaction.market}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tipo: ${_getTypeString(transaction.type)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Instituição: ${transaction.institution}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (asset.transactions.length > 1 &&
                                    transactionIndex == 0)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AllTransactionsPage(asset: asset),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Ver mais transações...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      if (asset.isFullyLiquidated == true)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Ativo totalmente liquidado',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red, // ou outra cor de destaque
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getTypeString(TransactionType type) {
    switch (type) {
      case TransactionType.buy:
        return 'Compra';
      case TransactionType.sell:
        return 'Venda';
    }
  }

  TransactionType _getTypeFromString(String typeString) {
    try {
      final cleanedString = typeString.trim().toLowerCase();

      if (cleanedString.contains('compra')) {
        return TransactionType.buy;
      } else if (cleanedString.contains('venda')) {
        return TransactionType.sell;
      } else {
        throw ArgumentError('Tipo de transação desconhecido: $typeString');
      }
    } catch (e) {
      throw ArgumentError('Erro ao processar o tipo de transação: $e');
    }
  }
}
