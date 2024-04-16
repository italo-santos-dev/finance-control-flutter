import 'package:flutter/material.dart';
import 'package:flutter_investment_control/models/asset_model.dart';
import 'package:flutter_investment_control/models/transaction_model.dart';
import 'package:flutter_investment_control/pages/active/extract/extract_page.dart';
import 'package:flutter_investment_control/pages/active/graph/graph_page.dart';
import 'package:flutter_investment_control/pages/home_page.dart';
import 'package:flutter_investment_control/services/api_service.dart';
import 'package:flutter_investment_control/services/asset_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

class AssetList extends StatefulWidget {
  const AssetList({Key? key}) : super(key: key);

  @override
  State<AssetList> createState() => _AssetListState();
}

class _AssetListState extends State<AssetList> {
  List<Asset> assets = [];
  List<String> availableAssetCodes =
      []; // Adicione esta linha para rastrear os códigos de ativos disponíveis
  Asset? selectedAsset; // Alteração para armazenar apenas um ativo selecionado
  NumberFormat real = NumberFormat.currency(locale: 'pt-br', name: 'R\$');
  Color? selectedBackgroundColor = Colors.grey[900];
  String? selectedAssetCode;
  String? selectedLiquidationCode;
  bool isAddAssetDialogOpen = false;
  bool _hideValues = false;
  bool isLoading =
      true; // Adicione esta linha para controlar o estado de carregamento

  final ApiService _apiService = ApiService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController tickerController = TextEditingController();
  final TextEditingController segmentController = TextEditingController();
  final TextEditingController activeTypeController = TextEditingController();
  final TextEditingController averagePriceController = TextEditingController();
  final TextEditingController currentPriceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController liquidationCodeController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedAssetCode = null;
    _loadAssets();
  }

  appBarDynamics() {
    if (selectedAsset == null) {
      return AppBar(
        automaticallyImplyLeading:
            false, // Configura para não mostrar a seta de volta
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Carteira de Ativos',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(
                _hideValues ? Icons.visibility_off : Icons.visibility,
                color: Colors.white,
                size: 20.0,
              ),
              onPressed: () {
                setState(() {
                  _hideValues = !_hideValues;
                });
              },
            ),
          ],
        ),
        backgroundColor: Colors.black,
      );
    } else {
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: Text(
          '${selectedAsset!.ticker} selecionado',
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              _showEditAssetDialog(context, selectedAsset!);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              _showDeleteAssetDialog(context, selectedAsset!);
            },
          ),
        ]
            .where((_) => selectedAsset != null)
            .toList(), // Adiciona a verificação condicional aqui
      );
    }
  }

  void _showEditAssetDialog(BuildContext context, Asset asset) {
    // Inicialize os controladores com os valores do ativo selecionado
    tickerController.text = asset.ticker;
    segmentController.text = asset.segment.toString();
    activeTypeController.text = asset.activeType.toString();
    averagePriceController.text = asset.averagePrice.toString();
    currentPriceController.text = asset.currentPrice.toString();
    quantityController.text = asset.quantity.toString();
    liquidationCodeController.text = asset.isFullyLiquidated.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Ativo'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: tickerController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Ticker'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor, insira um Ticker';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: averagePriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Preço Médio'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor, insira o Preço Médio';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: currentPriceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Preço Atual'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor, insira o Preço Atual';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: quantityController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Por favor, insira a Quantidade';
                      }
                      return null;
                    },
                  ),
                  // Adicione os novos campos aqui
                  // Exemplo:
                  DropdownButtonFormField<String>(
                    value: selectedLiquidationCode,
                    onChanged: (value) {
                      setState(() {
                        selectedLiquidationCode = value as String?;
                      });
                    },
                    items: [
                      DropdownMenuItem(
                        value: 'true',
                        child: Text('Sim'),
                      ),
                      DropdownMenuItem(
                        value: 'false',
                        child: Text('Não'),
                      ),
                    ],
                    decoration:
                        InputDecoration(labelText: 'Código de Liquidação'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, selecione uma opção para a flag de liquidação';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                tickerController.clear();
                averagePriceController.clear();
                currentPriceController.clear();
                quantityController.clear();
                // Limpe os novos controladores aqui
                Navigator.of(context).pop();

                setState(() {
                  selectedAsset = null;
                });
              },
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final ticker = tickerController.text.toUpperCase();
                  final segment = segmentController.text.toString();
                  final activeType = activeTypeController.text.toString();
                  final averagePrice =
                      double.tryParse(averagePriceController.text) ?? 0.0;
                  final currentPrice =
                      double.tryParse(currentPriceController.text) ?? 0.0;
                  final quantity = int.tryParse(quantityController.text) ?? 0;

                  // Ao salvar os dados, converta o valor selecionado para booleano
                  bool liquidationCode = selectedLiquidationCode == 'true';

                  if (ticker.isNotEmpty &&
                      averagePrice > 0 &&
                      currentPrice > 0 &&
                      quantity > 0) {
                    // Crie um novo objeto Asset com as informações editadas
                    final editedAsset = Asset(
                        ticker: ticker,
                        averagePrice: averagePrice,
                        currentPrice: currentPrice,
                        quantity: quantity,
                        transactions:
                            List<Transaction>.from(asset.transactions),
                        isFullyLiquidated: liquidationCode,
                        segment: segment,
                        activeType: activeType);

                    // Encontre o índice do ativo na lista
                    final index = assets.indexOf(asset);

                    // Atualize as informações do ativo na lista
                    assets[index] = editedAsset;

                    // Salve as alterações
                    _saveAssets();

                    // Use o provider para atualizar a lista de ativos
                    context.read<AssetProvider>().updateAssets(assets);

                    // Limpe os controladores
                    tickerController.clear();
                    averagePriceController.clear();
                    currentPriceController.clear();
                    quantityController.clear();

                    // Volte para a tela principal
                    setState(() {
                      selectedAsset = null;
                    });

                    // Recarregue os ativos
                    _loadAssets();

                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text(
                'Salvar',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAssetDialog(BuildContext context, Asset asset) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Excluir Ativo'),
          content: const Text('Tem certeza que deseja excluir este ativo?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Adicione a lógica para excluir o ativo aqui
                // Você pode acessar as propriedades do ativo usando a instância 'asset'
                // Remova o ativo da lista e salve as alterações
                assets.remove(asset);
                _saveAssets();

                // Use o provider para atualizar a lista de ativos
                context.read<AssetProvider>().updateAssets(assets);

                // Limpe o ativo selecionado
                setState(() {
                  selectedAsset = null;
                });

                Navigator.of(context).pop();
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadAssets() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Obtenha os ativos diretamente do Provider
      final List<Asset> loadedAssets = context.read<AssetProvider>().assets;

      // Obtenha os ativos salvos no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
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

      setState(() {
        isLoading = false;
      });

      // Imprima os ativos para análise
      print('Ativos carregados:');
      for (final asset in loadedAssets) {
        print(
          'Ticker: ${asset.ticker}, Quantidade: ${asset.quantity},'
          ' Preço Médio: ${asset.averagePrice}, Liquidada: ${asset.isFullyLiquidated},'
          ' Segment: ${asset.segment}, Type: ${asset.activeType}',
        );
        for (final transaction in asset.transactions) {
          print(
              '   Transação: ${transaction.type}, Quantidade: ${transaction.quantity}, Preço: ${transaction.price}');
        }
      }
      _saveAssets();
    } catch (e) {
      print("Erro ao carregar ativos: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveAssets() async {
    final prefs = await SharedPreferences.getInstance();
    final assetList = assets.map((asset) {
      final assetMap = asset.toJson();
      assetMap['transactions'] = asset.transactions
          .map((transaction) => {
                'date': transaction.date.toIso8601String(),
                'ticker': transaction.ticker,
                'type':
                    transaction.type.toString(), // ou 'buy' conforme necessário
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
    await prefs.setStringList('assets', assetList);
  }

  void _addAsset(Asset newAsset) {
    // Verifica se o ativo já existe na lista
    final existingAsset =
        assets.firstWhereOrNull((asset) => asset.ticker == newAsset.ticker);

    if (existingAsset != null) {
      // Atualiza as informações do ativo existente
      final totalQuantity = existingAsset.quantity + newAsset.quantity;
      final totalInvested =
          (existingAsset.averagePrice * existingAsset.quantity) +
              (newAsset.averagePrice * newAsset.quantity);
      final updatedAveragePrice = totalInvested / totalQuantity;

      existingAsset.averagePrice = updatedAveragePrice;
      existingAsset.quantity = totalQuantity;

      // Adiciona novas transações sem duplicatas
      for (Transaction newTransaction in newAsset.transactions) {
        final existingTransactionIndex = existingAsset.transactions.indexWhere(
            (transaction) => transaction.date == newTransaction.date);

        if (existingTransactionIndex != -1) {
          // Atualiza a transação existente
          final existingTransaction =
              existingAsset.transactions[existingTransactionIndex];

          existingTransaction.amount += newTransaction.amount;
        } else {
          // Adiciona uma nova transação
          existingAsset.transactions.add(newTransaction);
        }
      }
    } else {
      // Adiciona um novo ativo se ele não existir
      assets.add(newAsset);
    }

    setState(() {
      selectedAsset = null;
    });

    _saveAssets();
  }

  void _showAddAssetDialog(BuildContext context) async {
    setState(() {
      isAddAssetDialogOpen = true;
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Adicionar Ativo'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: tickerController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Ticker'),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Por favor, insira um Ticker';
                        }
                        return null;
                      },
                      onChanged: (ticker) async {
                        if (ticker.isNotEmpty) {
                          final assetDetails =
                              await _apiService.getAssetDetails(ticker);

                          if (assetDetails != null) {
                            setState(() {
                              currentPriceController.text =
                                  assetDetails['currentPrice'].toString();
                            });
                          } else {
                            // Tratar caso não encontre os detalhes do ativo
                          }
                        }
                      },
                    ),
                    TextFormField(
                      controller: currentPriceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Preço Atual'),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Por favor, insira o Preço Atual';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: quantityController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Quantidade'),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Por favor, insira a Quantidade';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    tickerController.clear();
                    averagePriceController.clear();
                    currentPriceController.clear();
                    quantityController.clear();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final ticker = tickerController.text.toUpperCase();
                      final segment = segmentController.text.toString();
                      final activeType = activeTypeController.text.toString();
                      final currentPrice =
                          double.tryParse(currentPriceController.text) ?? 0.0;
                      final quantity =
                          int.tryParse(quantityController.text) ?? 0;

                      if (ticker.isNotEmpty &&
                          currentPrice > 0 &&
                          quantity > 0) {
                        // Verifica se o ativo já existe na lista
                        final existingAsset = assets.firstWhereOrNull(
                            (asset) => asset.ticker == ticker);

                        if (existingAsset != null) {
                          // Atualiza as informações do ativo existente
                          final totalQuantity =
                              existingAsset.quantity + quantity;
                          final totalInvested = (existingAsset.averagePrice *
                                  existingAsset.quantity) +
                              (currentPrice * quantity);
                          final updatedAveragePrice =
                              totalInvested / totalQuantity;

                          existingAsset.averagePrice = updatedAveragePrice;
                          existingAsset.quantity = totalQuantity;

                          // Adiciona uma nova transação ao ativo existente
                          existingAsset.addTransaction(Transaction(
                            date: DateTime.now(),
                            ticker: existingAsset.ticker,
                            type: TransactionType
                                .buy, // Ajuste conforme necessário
                            market: 'Bovespa', // Ajuste conforme necessário
                            maturityDate: DateTime.now().add(
                              const Duration(days: 30),
                            ), // Ajuste conforme necessário
                            institution:
                                'Sua Instituição', // Ajuste conforme necessário
                            tradingCode: 'ABC123', // Ajuste conforme necessário
                            quantity: existingAsset.quantity,
                            price: existingAsset.currentPrice,
                            amount: existingAsset.currentPrice *
                                existingAsset.quantity,
                          ));
                        } else {
                          // Adiciona um novo ativo se ele não existir
                          final newAsset = Asset(
                              ticker: ticker,
                              averagePrice: currentPrice,
                              currentPrice: currentPrice,
                              quantity: quantity,
                              transactions: [],
                              isFullyLiquidated: false,
                              segment: segment,
                              activeType: activeType);

                          // Adiciona uma nova transação ao novo ativo
                          newAsset.addTransaction(Transaction(
                            date: DateTime.now(),
                            ticker: newAsset.ticker,
                            type: TransactionType
                                .buy, // Ajuste conforme necessário
                            market: 'Bovespa', // Ajuste conforme necessário
                            maturityDate: DateTime.now().add(
                              const Duration(days: 30),
                            ), // Ajuste conforme necessário
                            institution:
                                'Sua Instituição', // Ajuste conforme necessário
                            tradingCode: 'ABC123', // Ajuste conforme necessário
                            quantity: newAsset.quantity,
                            price: newAsset.currentPrice,
                            amount: newAsset.currentPrice * newAsset.quantity,
                          ));

                          _addAsset(newAsset);
                        }

                        tickerController.clear();
                        averagePriceController.clear();
                        currentPriceController.clear();
                        quantityController.clear();
                        selectedAssetCode = null;

                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    ).then((value) {
      setState(() {
        isAddAssetDialogOpen = false;
      });
    });
  }

  Widget _bottomAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          color: Colors.grey[900],
          size: 20.0,
        ),
      ),
    );
  }

  Widget _totalInfoCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _infoRow(
              title: 'Total Investido',
              value: real.format(_calculateTotalInvested()),
            ),
            const SizedBox(height: 16),
            _infoRow(
              title: 'Total Atual',
              value: real.format(_calculateTotalCurrent()),
            ),
            const SizedBox(height: 16),
            _infoRow(
              title: 'Total Gained/Lost',
              value: real.format(totalGainedOrLost),
              valueColor: totalGainedOrLost >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required String title,
    required String value,
    Color? valueColor,
  }) {
    if (_hideValues &&
        ['Custo Médio', 'Preço Médio', 'Rentabilidade'].contains(title)) {
      return const SizedBox
          .shrink(); // Oculta os valores numéricos quando _hideValues for verdadeiro
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        !_hideValues
            ? Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.white,
                ),
              )
            : Text(
                "R\$",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.white,
                ),
              ),
      ],
    );
  }

  double _calculateTotalInvested() {
    double totalInvested = 0.0;
    for (final asset in assets) {
      if (!asset.isFullyLiquidated) {
        totalInvested += asset.averagePrice * asset.quantity;
      }
    }
    return totalInvested;
  }

  double _calculateTotalCurrent() {
    double totalCurrent = 0.0;
    for (final asset in assets) {
      if (!asset.isFullyLiquidated) {
        totalCurrent += asset.currentPrice * asset.quantity;
      }
    }
    return totalCurrent;
  }

  double get totalGainedOrLost {
    double totalVariation = 0.0;
    for (final asset in assets) {
      if (!asset.isFullyLiquidated) {
        totalVariation += asset.totalVariation;
      }
    }
    return totalVariation;
  }

  navigateToGraphPage(List<Asset> assetList) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GraphPage(assetList: assetList),
      ),
    );
    // Adicione aqui a lógica para navegar para outra tela específica
  }

  void returnToHomePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarDynamics(),
      body: Consumer<AssetProvider>(builder: (context, assetProvider, _) {
        return isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  _totalInfoCard(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: assets.length,
                      itemBuilder: (context, index) {
                        final asset = assets[index];
                        final isSelected = selectedAsset == asset;

                        // Filtra os ativos que não estão totalmente liquidados
                        if (!asset.isFullyLiquidated) {
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? selectedBackgroundColor
                                    : Colors.grey[
                                        900], // Alterado para usar a variável selectedBackgroundColor
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${asset.ticker} - ${asset.quantity} Cotas',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              '${((asset.totalAmount / _calculateTotalCurrent()) * 100).toStringAsFixed(2)}%',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.black
                                                    : Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            !_hideValues
                                                ? Text(
                                                    real.format(
                                                        asset.totalAmount),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isSelected
                                                          ? Colors.black
                                                          : Colors.white,
                                                    ),
                                                  )
                                                : Text(
                                                    'R\$',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isSelected
                                                          ? Colors.black
                                                          : Colors.white,
                                                    ),
                                                  )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Custo Médio',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        !_hideValues
                                            ? Text(
                                                real.format(asset.averagePrice *
                                                    asset.quantity),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            : Text(
                                                'R\$',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isSelected
                                                      ? Colors.black
                                                      : Colors.grey,
                                                ),
                                              )
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Preço Médio',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        !_hideValues
                                            ? Text(
                                                real.format(asset.averagePrice),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            : Text(
                                                'R\$',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isSelected
                                                      ? Colors.black
                                                      : Colors.grey,
                                                ),
                                              )
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Última Cotação',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          real.format(asset.currentPrice),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        const Text(
                                          'Rentabilidade',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Row(
                                          children: <Widget>[
                                            Text(
                                              '${asset.profitability.toStringAsFixed(2)}%',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: asset.profitability >= 0
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            !_hideValues
                                                ? Text(
                                                    real.format(
                                                        asset.totalVariation),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color:
                                                          asset.totalVariation >=
                                                                  0
                                                              ? Colors.grey
                                                              : Colors.red,
                                                    ),
                                                  )
                                                : Text(
                                                    'R\$',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: isSelected
                                                          ? Colors.black
                                                          : Colors.grey,
                                                    ),
                                                  )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                selected: isSelected,
                                onTap: () {
                                  setState(() {
                                    selectedAsset = isSelected
                                        ? null
                                        : asset; // Seleciona ou deseleciona o ativo
                                  });
                                  selectedBackgroundColor = (isSelected
                                      ? Colors.grey[900]
                                      : Colors.white)!; // Define a cor desejada
                                },
                              ),
                            ),
                          );
                        }
                        // Retorna um Container vazio para ativos totalmente liquidados
                        return Container();
                      },
                    ),
                  ),
                ],
              );
      }),
      bottomNavigationBar: SizedBox(
        height: 70.0,
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomAction(FontAwesomeIcons.clockRotateLeft, () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExtratoPage(),
                  ),
                );

                _loadAssets();
              }),
              _bottomAction(
                  FontAwesomeIcons.house, () => returnToHomePage(context)),
              const SizedBox(width: 48.0),
              _bottomAction(
                  FontAwesomeIcons.chartPie, () => navigateToGraphPage(assets)),
              _bottomAction(FontAwesomeIcons.bars, () => navigateToGraphPage),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: !isAddAssetDialogOpen && selectedAsset == null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton(
                backgroundColor: Colors.grey,
                child: const Icon(Icons.add, color: Colors.black),
                shape: const CircleBorder(),
                onPressed: () {
                  _showAddAssetDialog(context);
                },
                elevation: 0.0,
              ),
            )
          : null,
    );
  }
}
