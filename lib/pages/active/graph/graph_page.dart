import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_investment_control/models/asset_model.dart';
import 'package:flutter_investment_control/models/transaction_model.dart';
import 'package:flutter_investment_control/widgets/protfolioPerformance/portfolio_performance_chart.dart';
import 'package:intl/intl.dart';

class GraphPage extends StatefulWidget {
  final List<Asset> assetList;

  const GraphPage({Key? key, required this.assetList}) : super(key: key);

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  late int? touchedIndex = -1;
  String currentFilter = 'type of assets'; // Opções: 'all', 'stocks', 'fiis'

  @override
  Widget build(BuildContext context) {

    final List<Asset> assetsTest = widget.assetList.toList();


    return DefaultTabController(
      length: 4, // Mantendo o número de Tabs original
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
            color: Colors.white,
          ),
          title: const Text(
            'Gráficos',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          actions: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: PopupMenuButton<String>(
                icon: Icon(Icons.filter_list, color: Colors.white),
                onSelected: (String value) {
                  setState(() {
                    currentFilter = value;
                  });
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'type of assets',
                    child: Text('TYPE ASSETS'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'all',
                    child: Text('ALL'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'stocks',
                    child: Text('STOCKS'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'fiis',
                    child: Text('FIIS'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'sectors',
                    child: Text('SECTORS'),
                  ),
                ],
              ),
            )
          ],
          backgroundColor: Colors.black,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Composição'),
              Tab(text: 'Patrimônio'),
              Tab(text: 'Rentabilidade'),
              Tab(text: 'Proventos'),
            ],
            labelColor: Colors.white,
            indicatorColor: Colors.white,
          ),
        ),
        body: TabBarView(
          children: [
            _buildDistributionChart1(),
            Container(
              alignment: Alignment.topCenter,
              child: _buildMonthlyEvolutionChart(),
            ),
            PortfolioPerformanceChart(assets: assetsTest),
            _buildProfitabilityChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionChart() {
    List<Asset> filteredAssets = [];
    switch (currentFilter) {
      case 'all': // Nova opção para visualizar a distribuição de ações e FIIs
        filteredAssets = widget.assetList
            .where((asset) => !asset.isFullyLiquidated)
            .toList();
        break;
      case 'stocks':
        filteredAssets = widget.assetList
            .where((asset) =>
                asset.activeType == 'stocks' && !asset.isFullyLiquidated)
            .toList();
        break;
      case 'fiis':
        filteredAssets = widget.assetList
            .where((asset) =>
                asset.activeType == 'fiis' && !asset.isFullyLiquidated)
            .toList();
        break;
      default:
        filteredAssets = widget.assetList
            .where((asset) => !asset.isFullyLiquidated)
            .toList();
        break;
    }
    return _buildSectorDistributionChart(filteredAssets);
  }

  Widget _buildDistributionChart1() {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _buildDistributionChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorDistributionChart(List<Asset> assets) {
    if (assets.isEmpty) {
      return Center(child: Text('Nenhuma ação encontrada.'));
    }

    Map<String, double> typeMap = {};

    Map<String, String> filterTitles = {
      'all': 'Distribuição por Ativo',
      'sectors': 'Posição Atual por Setor',
      'fiis': 'Distribuição por Fiis',
      'stocks': 'Distribuição por Ações'
    };

    String title = filterTitles[currentFilter] ?? 'Filtro Desconhecido';
    Map<String, double> fiisMap = {};
    Map<String, double> stocksMap = {};

    // Calcula a distribuição para o caso de 'stocks_fiis'
    if (currentFilter == 'type of assets') {
      for (var asset in assets) {
        String typeKey = asset.activeType; // 'stocks' ou 'fiis'
        typeMap.update(typeKey, (value) => value + asset.totalAmount,
            ifAbsent: () => asset.totalAmount);
      }
      double totalValue = typeMap.values.fold(0, (sum, asset) => sum + asset);
      List<Color> colors = _getColors(typeMap.length);
      return _buildPieChart(
          typeMap, totalValue, colors, "Distribuição Total por Tipo de Ativo");
    }

    for (var asset in assets) {
      if (currentFilter == 'sectors') {
        if (asset.activeType == 'fiis') {
          fiisMap.update(asset.segment, (value) => value + asset.totalAmount,
              ifAbsent: () => asset.totalAmount);
        } else if (asset.activeType == 'stocks') {
          stocksMap.update(asset.segment, (value) => value + asset.totalAmount,
              ifAbsent: () => asset.totalAmount);
        }
      } else {
        String key = asset.ticker;
        fiisMap.update(key, (value) => value + asset.totalAmount,
            ifAbsent: () => asset.totalAmount);
      }
    }

    List<Widget> charts = [];
    if (currentFilter == 'sectors') {
      double totalFiisValue =
          fiisMap.values.fold(0, (sum, asset) => sum + asset);
      double totalStocksValue =
          stocksMap.values.fold(0, (sum, asset) => sum + asset);
      List<Color> fiisColors = _getColors(fiisMap.length);
      List<Color> stocksColors = _getColors(stocksMap.length);

      Widget fiisChart = _buildPieChart(fiisMap, totalFiisValue, fiisColors,
          'Distribuição por Setor de FIIs');
      Widget stocksChart = _buildPieChart(stocksMap, totalStocksValue,
          stocksColors, 'Distribuição por Setor de Ações');

      charts.add(fiisChart);
      charts.add(stocksChart);
    } else {
      // Mantenha a lógica atual para outros filtros
      double totalValue = fiisMap.values.fold(0, (sum, asset) => sum + asset);
      List<Color> colors = _getColors(fiisMap.length);
      Widget chart = _buildPieChart(fiisMap, totalValue, colors, title);
      charts.add(chart);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: charts,
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> assetMap, double totalValue,
      List<Color> colors, String chartTitle) {
    List<PieChartSectionData> sections =
        assetMap.keys.toList().asMap().entries.map((entry) {
      bool isTouched = entry.key == touchedIndex;
      return PieChartSectionData(
        color: colors[entry.key],
        value: assetMap[entry.value],
        title:
            '${(assetMap[entry.value]! / totalValue * 100).toStringAsFixed(2)}%',
        radius: isTouched ? 100 : 80,
        titleStyle: TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        titlePositionPercentageOffset: 0.5,
      );
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Text(
            chartTitle,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
              left: 16.0, right: 16.0), // Espaçamento em todas as direções
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 12.0, // Espaçamento horizontal entre os botões
              runSpacing:
                  12.0, // Espaçamento vertical entre as linhas de botões
              alignment: WrapAlignment.start,
              children: assetMap.keys.toList().asMap().entries.map((entry) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      touchedIndex =
                          touchedIndex == entry.key ? null : entry.key;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(colors[entry.key]),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                    ),
                    padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0)),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SingleChildScrollView(
          child: Container(
            height: 300,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = null;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                }),
                borderData: FlBorderData(show: false),
                sectionsSpace: 5,
                centerSpaceRadius: 50,
                sections: sections,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Color> _getColors(int count) {
    List<Color> palette = [
      Color(0xFF4FC3F7),
      Color(0xFF81C784),
      Color(0xFFFFB74D),
      Color(0xFF9575CD),
      Color(0xFFFF867C),
      Color(0xFF616161),
      Color(0xFF7E57C2),
      Color(0xFF26A69A),
      Color(0xFFF06292),
      Color(0xFF8D6E63),
      Color(0xFF78909C),
    ];
    return List.generate(count, (index) => palette[index % palette.length]);
  }

  Color _getColor(int index) {
    final List<Color> colors = [
      Color(0xFF4FC3F7),
      Color(0xFF81C784),
      Color(0xFFFFB74D),
      Color(0xFF9575CD),
      Color(0xFFFF867C),
      Color(0xFF616161),
      Color(0xFF7E57C2),
      Color(0xFF26A69A),
      Color(0xFFF06292),
      Color(0xFF8D6E63),
      Color(0xFF78909C),
    ];

    return colors[index % colors.length];
  }

  Widget _buildProfitabilityChart() {
    // Simulação de dados para a rentabilidade da carteira e do CDI
    List<Map<String, dynamic>> data = [
      {'label': 'Out', 'carteira': -0.40, 'cdi': 1.01},
      {'label': 'Nov', 'carteira': 6.345, 'cdi': 1.01},
      {'label': 'Dez', 'carteira': 1.105, 'cdi': 1.01},
      // Adicione mais pontos de dados conforme necessário
    ];

    return Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 400,
          height: 300,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: true),
              minX: 0,
              maxX: data.length.toDouble() - 1,
              minY: -1,
              maxY: 8,
              lineBarsData: [
                _buildLineChartBarData(data, 'carteira', _getColor(0)),
                _buildLineChartBarData(data, 'cdi', _getColor(1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Função auxiliar para calcular o patrimônio em uma data específica
  double getBalanceByDate(List<Transaction> transactions, DateTime targetDate) {
    double balance = 0.0;
    for (var transaction in transactions) {
      if (transaction.date.isBefore(targetDate.add(Duration(days: 1)))) {
        balance += transaction.amount!;
      }
    }
    return balance;
  }

  LineChartBarData _buildLineChartBarData(
      List<Map<String, dynamic>> data, String key, Color color) {
    return LineChartBarData(
      spots: _getDataSpots(data, key),
      isCurved: true,
      colors: [color],
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _buildMonthlyEvolutionChart() {
    // Filtra apenas os ativos não liquidados
    final List<Asset> nonLiquidatedAssets =
        widget.assetList.where((asset) => !asset.isFullyLiquidated).toList();

    // Extrai todas as transações desses ativos não liquidados
    final List<Transaction> allTransactions =
        nonLiquidatedAssets.expand((asset) => asset.transactions).toList();

    // Ordenação das transações por data
    allTransactions.sort((a, b) {
      if (a.date.year != b.date.year) {
        return a.date.year.compareTo(b.date.year);
      }
      return a.date.month.compareTo(b.date.month);
    });

    // Calcula os saldos mensais acumulados usando as transações
    final Map<String, double> monthlyBalances = {};
    double cumulativeBalance = 0; // Inicializa saldo acumulado
    for (var transaction in allTransactions) {
      final String monthYear =
          '${transaction.date.month.toString().padLeft(2, '0')}-${transaction.date.year}';
      cumulativeBalance += transaction.amount ?? 0; // Acumula o saldo
      monthlyBalances[monthYear] =
          cumulativeBalance; // Atualiza o saldo para o mês
    }

    // Lista de meses únicos em ordem
    final List<String> uniqueMonths = monthlyBalances.keys.toList();
    uniqueMonths.sort((a, b) {
      var partsA = a.split('-');
      var partsB = b.split('-');
      int yearA = int.parse(partsA[1]);
      int yearB = int.parse(partsB[1]);
      int monthA = int.parse(partsA[0]);
      int monthB = int.parse(partsB[0]);

      if (yearA != yearB) {
        return yearA.compareTo(yearB);
      }
      return monthA.compareTo(monthB);
    });

    // Mapeia os dados para os pontos do gráfico
    final List<FlSpot> lineSpots = uniqueMonths.map((monthYear) {
      final index = uniqueMonths.indexOf(monthYear);
      return FlSpot(index.toDouble(), monthlyBalances[monthYear]!);
    }).toList();

    String simplifiedCurrencyFormat(double value) {
      final currencyFormatter = NumberFormat.currency(
          locale: 'pt_BR', symbol: 'R\$', decimalDigits: 1);

      if (value >= 1000) {
        return currencyFormatter.format(value / 1000) + 'k';
      }
      return currencyFormatter.format(value);
    }

    // Data de hoje
    DateTime today = DateTime.now();

    double currentBalance = getBalanceByDate(allTransactions, today);

    // Encontrar datas anteriores válidas para cálculo do patrimônio
    DateTime date6MonthsAgo =
        findValidPreviousDate(allTransactions, today, 180);
    DateTime date12MonthsAgo =
        findValidPreviousDate(allTransactions, today, 365);
    DateTime date24MonthsAgo =
        findValidPreviousDate(allTransactions, today, 730);

    // Calcular o patrimônio nessas datas
    double balance6MonthsAgo =
        getBalanceByDate(allTransactions, date6MonthsAgo);
    double balance12MonthsAgo =
        getBalanceByDate(allTransactions, date12MonthsAgo);
    double balance24MonthsAgo =
        getBalanceByDate(allTransactions, date24MonthsAgo);

    // Calcular crescimento percentual usando a função auxiliar
    double growth6Months = calculateGrowth(currentBalance, balance6MonthsAgo);
    double growth12Months = calculateGrowth(currentBalance, balance12MonthsAgo);
    double growth24Months = calculateGrowth(currentBalance, balance24MonthsAgo);


    // Formatar valores para exibição
    NumberFormat currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final Map<String, double> categoryTotals =
    calculateTotalByCategory(nonLiquidatedAssets);

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Text(
              "Evolução do Patrimônio",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Container(
            height: 300,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 24.0,
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: false,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: SideTitles(
                      showTitles: true,
                      getTextStyles: (context, value) => const TextStyle(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      margin: 10,
                      rotateAngle: 0,
                      getTitles: (double value) {
                        final index = value.toInt();
                        if (index >= 0 && index < uniqueMonths.length) {
                          var parts = uniqueMonths[index].split('-');
                          return '${parts[0]}/${parts[1].substring(2)}'; // Display as MM/YY
                        }
                        return '';
                      },
                    ),
                    leftTitles: SideTitles(
                      showTitles: true,
                      getTextStyles: (context, value) => const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                      reservedSize: 40,
                      margin: 12,
                      interval: 500,
                      getTitles: (value) => simplifiedCurrencyFormat(value),
                    ),
                    topTitles: SideTitles(showTitles: false),
                    rightTitles: SideTitles(showTitles: false),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: lineSpots,
                      isCurved: true,
                      colors: [Theme.of(context).colorScheme.secondary],
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.3)
                        ],
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final textStyle = TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          );
                          return LineTooltipItem(
                            simplifiedCurrencyFormat(touchedSpot.y),
                            textStyle,
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                  child: ListTile(
                    leading:
                        Icon(Icons.account_balance_wallet, color: Colors.grey),
                    title: Text(
                      'Valor Aplicado',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16.0),
                    ),
                    subtitle: Text(
                      '${currencyFormat.format(currentBalance)}',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Card(
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crescimento Patrimonial',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            _buildGrowthTile('6 MESES', growth6Months),
                            _buildGrowthTile('12 MESES', growth12Months),
                            _buildGrowthTile('24 MESES', growth24Months),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            "Patrimônio Total por Categoria",
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 300, // Specify a height for the container
              child: buildCategoryTotals(categoryTotals),
            ),
          )
        ],
      ),
    );
  }

  Map<String, double> calculateTotalByCategory(List<Asset> assets) {
    Map<String, double> categoryTotals = {};
    for (Asset asset in assets) {
      double total = asset.transactions
          .fold(0, (sum, transaction) => sum + (transaction.amount ?? 0));
      String key = asset.activeType ??
          "Unknown"; // Assuming a default category "Unknown" for null types

      // Here we ensure that categoryTotals[key] returns a non-null value using ?? 0
      categoryTotals[key] = (categoryTotals[key] ?? 0) + total;
    }
    return categoryTotals;
  }

  Widget buildCategoryTotals(Map<String, double> categoryTotals) {

    // Formatar valores para exibição
    NumberFormat currencyFormat =
    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    // Generate DataRow list from the map entries
    List<DataRow> rows = categoryTotals.entries.map((entry) {
      return DataRow(cells: [
        DataCell(SizedBox(width: 200, child: Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)))),
        DataCell(SizedBox(width: 200, child: Text(currencyFormat.format(entry.value), style: TextStyle(fontSize: 16, color: Colors.white)))),
      ]);
    }).toList();

    // Return DataTable widget wrapped in SingleChildScrollView to ensure scrolling
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Use vertical if you prefer
      child: DataTable(
        columnSpacing: 48.0,
        headingRowHeight: 56.0,
        dataRowHeight: 48.0,
        headingRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
          return Colors.grey[900] ?? Colors.black; // Ensure non-null value
        }),
        dataRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
          return Colors.grey[850] ?? Colors.black; // Slightly lighter for data rows
        }),
        columns: [
          DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white))),
          DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white))),
        ],
        rows: rows,
        border: TableBorder.all(color: Colors.grey[200] ?? Colors.grey, width: 1.5),
      ),
    );
  }

  Widget _buildGrowthTile(String period, double growth) {
    return Expanded(
      child: Column(
        children: [
          Text(period, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          SizedBox(height: 4),
          Text(
            '${growth.toStringAsFixed(2)} %',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: growth >= 0 ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }

  // Função auxiliar para calcular o crescimento percentual
  double calculateGrowth(double currentBalance, double previousBalance) {
    if (previousBalance == 0) {
      if (currentBalance == 0) {
        return 0.0; // Se ambos são zero, considera-se estabilidade (sem crescimento)
      }
      return double
          .infinity; // Se o saldo anterior é zero e o atual não, indica crescimento infinito
    }
    return ((currentBalance - previousBalance) / previousBalance) * 100;
  }

// Função para encontrar uma data anterior válida com saldo não-zero
  DateTime findValidPreviousDate(
      List<Transaction> transactions, DateTime startDate, int daysBack) {
    DateTime targetDate = startDate.subtract(Duration(days: daysBack));
    while (getBalanceByDate(transactions, targetDate) == 0 &&
        targetDate.isBefore(startDate)) {
      targetDate = targetDate.add(Duration(
          days: 1)); // Move um dia para frente até encontrar um saldo não-zero
    }
    return targetDate;
  }

  List<FlSpot> _getDataSpots(List<Map<String, dynamic>> data, String key) {
    return List.generate(data.length, (index) {
      return FlSpot(index.toDouble(), data[index][key]);
    });
  }
}
