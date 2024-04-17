import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/models/active_model.dart';
import 'package:flutter_investment_control/services/apis/api_stock_indicators.dart';
import 'package:flutter_investment_control/services/apis/api_stocks_dividends.dart';
import 'package:flutter_investment_control/services/apis/api_stocks_historicals.dart';
import 'package:flutter_investment_control/widgets/btc/chart_page.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ActiveDetailsPage extends StatefulWidget {
  final Active active;

  ActiveDetailsPage({Key? key, required this.active}) : super(key: key);

  @override
  _ActiveDetailsPageState createState() => _ActiveDetailsPageState();
}

class _ActiveDetailsPageState extends State<ActiveDetailsPage> {
  NumberFormat real = NumberFormat.currency(locale: 'pt-br', name: 'R\$');

  Map<String, dynamic>? _stockIndicators;
  List<Map<String, dynamic>> dividendDataList = [];
  List<int> availableYears = [];
  int selectedYear = DateTime.now().year;

  late Future<List<FlSpot>> _chartData;
  Key _chartKey = UniqueKey(); // Chave única para o FutureBuilder

  String formatCurrencyBRL(double value) {
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return format.format(value);
  }

  double _calculateFairValue() {
    if (_stockIndicators == null || _stockIndicators!['indicators'] == null) {
      return 0.0; // Valor padrão se os indicadores não estiverem disponíveis
    }

    final List<dynamic> indicators = _stockIndicators!['indicators'];

    if (indicators.isEmpty) {
      return 0.0; // Retorna valor padrão se a lista de indicadores estiver vazia
    }

    print('Dados recebidos _calculateFairValue: $indicators');

    // Encontra os indicadores necessários na lista
    final Map<String, dynamic> earningsPerShareIndicator =
        indicators.firstWhere(
      (indicator) => indicator.containsKey('earningsPerShare'),
      orElse: () => <String, dynamic>{
        'earningsPerShare': {'value': 0.0}
      }, // Retorna um mapa com valor padrão se não encontrar
    );

    final Map<String, dynamic> bookValuePerShareIndicator =
        indicators.firstWhere(
      (indicator) => indicator.containsKey('bookValuePerShare'),
      orElse: () => <String, dynamic>{
        'bookValuePerShare': {'value': 0.0}
      }, // Retorna um mapa com valor padrão se não encontrar
    );

    final double earningsPerShare =
        earningsPerShareIndicator['earningsPerShare']['value'] ?? 0.0;
    final double bookValuePerShare =
        bookValuePerShareIndicator['bookValuePerShare']['value'] ?? 0.0;

    // Fórmula de Valor Intrínseco de Benjamin Graham
    final double fairValue = sqrt(22.5 * earningsPerShare * bookValuePerShare);

    return fairValue;
  }

  @override
  void initState() {
    super.initState();
    _fetchStockIndicators();
    _chartData = _fetchChartData();
    fetchData();
  }

  Future<List<FlSpot>> _fetchChartData({int months = 3}) async {
    var stockData =
    await StocksHistoricals().getStockHistoricals(widget.active.symbol, months);
    List<dynamic> historicals = stockData?['historicals'] ?? [];

    if (historicals.isEmpty) {
      print("Nenhum dado histórico recebido para os últimos $months meses.");
      return [];
    }

    List<FlSpot> chartData = [];
    for (var i = 0; i < historicals.length; i++) {
      DateTime date = DateTime.parse(historicals[i]['date']);
      double close = (historicals[i]['close'] as num).toDouble();
      chartData.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), close));
    }

    print(
        "Recebidos ${historicals.length} pontos de dados da API para os últimos $months meses.");
    print(
        "Processados ${chartData.length} pontos de dados FlSpot para o gráfico.");
    return chartData;
  }

  Future<List<double>> _calculateReturns() async {
    try {
      // Get historical prices from the API response
      final response =
          await StocksHistoricals().getStockHistoricals(widget.active.symbol, 12);

      if (response != null) {
        List<dynamic> historicals = response['historicals'] as List<dynamic>;

        // Obter a data de hoje e o primeiro dia do mês passado
        DateTime now = DateTime.now();
        DateTime firstDayOfLastMonth = DateTime(now.year, now.month - 1, 1);

        // Filtrar os preços para o último d
        List<double> pricesLastMonth = historicals
            .where((historical) {
              DateTime date = DateTime.parse(historical['date']);
              return date.isAfter(
                      firstDayOfLastMonth.subtract(Duration(days: 1))) &&
                  date.isBefore(now);
            })
            .map<double>(
                (historical) => double.parse(historical['close'].toString()))
            .toList();

        // Verificar se há preços disponíveis para o último mês
        double returnLastMonth = 0.0;
        if (pricesLastMonth.isNotEmpty) {
          // Obter o primeiro e o último preço de fechamento disponíveis
          double firstDayClosingPrice = pricesLastMonth.first;
          double lastDayClosingPrice = pricesLastMonth.last;

          // Calcular a rentabilidade para o último mês
          returnLastMonth = ((lastDayClosingPrice - firstDayClosingPrice) /
                  firstDayClosingPrice) *
              100;
        }

        // Calcular a rentabilidade para os últimos 12 meses
        DateTime twelveMonthsAgo = DateTime.now().subtract(Duration(days: 365));
        List<double> pricesLast12Months = historicals
            .where((historical) {
              DateTime date = DateTime.parse(historical['date']);
              return date.isAfter(twelveMonthsAgo.subtract(Duration(days: 1)));
            })
            .map<double>(
                (historical) => double.parse(historical['close'].toString()))
            .toList();

        double returnLast12Months = 0.0;
        if (pricesLast12Months.isNotEmpty) {
          // Obter o primeiro e o último preço de fechamento dos últimos 12 meses
          double firstPriceLast12Months = pricesLast12Months.first;
          double lastPriceLast12Months = pricesLast12Months.last;

          // Calcular a rentabilidade dos últimos 12 meses
          returnLast12Months =
              ((lastPriceLast12Months - firstPriceLast12Months) /
                      firstPriceLast12Months) *
                  100;
        }

        return [returnLastMonth, returnLast12Months];
      } else {
        throw Exception('Failed to load historical prices');
      }
    } catch (e) {
      print('Error calculating returns: $e');
      throw Exception('Error calculating returns');
    }
  }

  Future<void> _fetchStockIndicators() async {
    try {
      // Chama a função para obter os indicadores da API
      final indicators =
          await StockIndicators().getStockIndicators(widget.active.symbol);
      setState(() {
        _stockIndicators = indicators;
      });
    } catch (e) {
      print('Error fetching stock indicators: $e');
      // Trate o erro conforme necessário
    }
  }

  void fetchData() async {
    StockDividends stockDividends = StockDividends();
    List<Map<String, dynamic>> data =
        await stockDividends.getStockDividends(widget.active.symbol);
    setState(() {
      if (data != null) {
        dividendDataList = data;
        availableYears = data
            .where((dividend) => dividend['date'] != null)
            .map((dividend) => DateTime.parse(dividend['date']).year)
            .toSet()
            .toList();
      } else {
        // Handle the case where data is null
        // For example, show an error message or retry fetching data
      }
    });
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
        title: Text(
          widget.active.symbol,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<List<double>>(
                    future: _calculateReturns(),
                    builder: (context, snapshot) {
                      double returnCurrentMonth = 0.0;
                      double returnLast12Months = 0.0;

                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        returnCurrentMonth = snapshot.data![0];
                        returnLast12Months = snapshot.data![1];
                      }

                      return _buildHeader(
                          returnLast12Months, returnCurrentMonth);
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildInfoSection(
                    title: 'Informações Gerais',
                    children: [
                      _buildGeneralInfoRow(
                        icon: Icons.monetization_on,
                        title: 'Preço Atual',
                        value: real.format(widget.active.lastPrice),
                      ),
                      _buildGeneralInfoRow(
                        icon: Icons.trending_up,
                        title: 'Dividend Yield',
                        value:
                            '${widget.active.dividendYield.toStringAsFixed(2)}%',
                      ),
                      _buildGeneralInfoRow(
                        icon: Icons.business,
                        title: 'Setor',
                        value: widget.active.sector,
                      ),
                      _buildGeneralInfoRow(
                        icon: Icons.work,
                        title: 'Segmento',
                        value: widget.active.segment,
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),
                  _buildInfoSection(
                    title: 'Desempenho Anual',
                    children: [
                      _buildPerformanceInfoRow(
                        icon: Icons.arrow_downward,
                        title: 'Último Ano Baixo',
                        value: real.format(widget.active.lastYearLow),
                      ),
                      _buildPerformanceInfoRow(
                        icon: Icons.arrow_upward,
                        title: 'Último Ano Alto',
                        value: real.format(widget.active.lastYearHigh),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft, // Ajusta o alinhamento para direita
                        child: const Text(
                          'Cotação',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildFilterButtons(),
                      FutureBuilder<List<FlSpot>>(
                        key: _chartKey, // Usa a chave que muda a cada novo futuro
                        future: _chartData,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                            return Center(child: CircularProgressIndicator(color: Colors.grey[900]));
                          } else if (snapshot.connectionState == ConnectionState.waiting) {
                            // Continua mostrando o gráfico antigo e adiciona uma mensagem de que está atualizando
                            return Stack(
                              children: [
                                _buildChart(snapshot.data!),
                                Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    color: Colors.black54,
                                    padding: EdgeInsets.all(8),
                                    child: Text('Atualizando...', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            );
                          } else if (snapshot.hasError) {
                            return Center(child: Text('Erro: ${snapshot.error}'));
                          } else {
                            return _buildChart(snapshot.data!);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildIndicatorsSection(),
                  const SizedBox(height: 15),
                  _buildFairValueSection(),
                  const SizedBox(height: 15),
                  _buildStockDividends(),
                  const SizedBox(
                    height: 15,
                  ),
                  _buildPriceCeilingSection(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showHistoryChart() {
    // Mock de dados fictícios para o gráfico de linhas
    List<double> values = [10, 20, 15, 25, 30, 35];

    // Criação do gráfico de linhas
    Widget chart = LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: values.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value);
            }).toList(),
            isCurved: true,
            colors: [Colors.blue],
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        minX: 0,
        maxX: values.length.toDouble() - 1,
        minY: 0,
        maxY: values
                .reduce((curr, next) => curr > next ? curr : next)
                .toDouble() +
            10,
      ),
    );

    // Mostra o modal com o gráfico de linhas
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Histórico do Indicador'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width - 100,
          height: MediaQuery.of(context).size.height - 200,
          child: chart,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o modal
            },
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showIndicatorDescription(String description, String name) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(double returnLast12Months, double returnCurrentMonth) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          _buildAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.active.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    // color: Colors.white
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rentabilidade (12M): ${returnLast12Months.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Último Mês: ${returnCurrentMonth.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    Widget avatar;
    if (widget.active.icon.toLowerCase().endsWith('.svg')) {
      avatar = SvgPicture.network(
        widget.active.icon,
        headers: {'Accept': 'image/svg+xml'},
        width: 80,
        height: 80,
      );
    } else {
      avatar = Image.asset(
        widget.active.icon,
        width: 80,
        height: 80,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: avatar,
    );
  }

  Widget _buildInfoSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: children.map((widget) {
              return widget;
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralInfoRow(
      {required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceInfoRow(
      {required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, bottom: 18.0),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsSection() {
    if (_stockIndicators == null || _stockIndicators!['indicators'] == null) {
      return Container();
    }

    final List<dynamic>? indicatorsDynamic = _stockIndicators!['indicators'];

    if (indicatorsDynamic == null) {
      return SizedBox(); // Ou algum outro widget de espaço reservado
    }

    final List<Map<String, dynamic>> indicators =
        indicatorsDynamic.cast<Map<String, dynamic>>();

    final Map<String, List<String>> sectionKeys = {
      'Indicadores de Valuation': [
        'priceToBookValue',
        'priceEarningsRatio',
        'enterpriseValueEbitda',
        'enterpriseValueEbit',
        'bookValuePerShare',
        'earningsPerShare',
        'priceToEbit',
        'priceToEbitda',
        'priceToAssets',
        'priceToNetNetWorkingCapital',
        'priceToNetCurrentAssets',
      ],
      'Indicadores de Endividamento': [
        'netDebtToAssets',
        'netDebtToEbitda',
        'netDebtToEbit',
        'equityToAssetsRatio',
        'liabilitiesToAssetsRatio',
        'currentLiquidity'
      ],
      'Indicadores de Eficiência': [
        'grossMargin',
        'ebitdaMargin',
        'ebitMargin',
        'netMargin'
      ],
      'Indicadores de Rentabilidade': [
        'returnOnEquity',
        'returnOnAssets',
        'returnOnInvestedCapital',
        'assetTurnoverRatio'
      ],
      'Indicadores de Crescimento': ['cagrProfitsFiveYears'],
    };

    List<Widget> cards = [];

    sectionKeys.forEach((sectionTitle, keys) {
      List<Widget> sectionCards = _buildIndicatorCards(indicators, keys);
      cards.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Text(
                sectionTitle,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: sectionCards,
              ),
            ),
          ],
        ),
      );
    });

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Indicadores',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          ...cards,
        ],
      ),
    );
  }

  Widget _buildIndicatorCard(
      {required String name,
      required String description,
      required IconData infoIcon,
      required IconData historyIcon,
      required String value}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      width: MediaQuery.of(context).size.width / 2 - 24,
      child: Card(
        elevation: 2,
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showIndicatorDescription(description, name);
                    },
                    child: Icon(
                      infoIcon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showHistoryChart,
                    child: Icon(
                      historyIcon,
                      color: Colors.white,
                      size: 20,
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

  Widget _buildFilterButtons() {
    final List<Map<String, dynamic>> filters = [
      {'label': '30D', 'months': 1},
      {'label': '6M', 'months': 6},
      {'label': '1A', 'months': 12},
      {'label': '5A', 'months': 60},
    ];

    void _applyFilter(int months) {
      print("Filtro Aplicado: $months meses");
      setState(() {
        _chartData = _fetchChartData(months: months);
        _chartKey = UniqueKey();  // Atualiza a chave para forçar reconstrução do FutureBuilder
      });
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: filters.map((filter) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8), // Adiciona espaço entre os botões
              child: ElevatedButton(
                onPressed: () => _applyFilter(filter['months']),
                child: Text(filter['label'], style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey[850],  // dark grey button background
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // rounded corners
                  ),
                  elevation: 3,  // subtle shadow
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChart(List<FlSpot> chartData) {
    return Container(
      height: 300, // Define a altura para metade da altura da tela
      padding:
      EdgeInsets.only(right: 20, left: 16), // Adicionado padding à esquerda
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false), // Desativa a grade
          titlesData: FlTitlesData(
            bottomTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTextStyles: (context, value) => const TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              getTitles: (value) {
                return getTitleForValue(value, chartData); // Usa a função personalizada para obter títulos
              },
              margin: 10,
            ),            leftTitles: SideTitles(
            showTitles: true,
            getTitles: (value) {
              return formatCurrencyBRL(value); // Formatação para BRL
            },
            getTextStyles: (context, value) => const TextStyle(
              color:
              Colors.blueGrey, // Cor azul-cinza para os títulos do eixo Y
              fontSize: 12, // Tamanho de fonte conforme sua especificação
            ),
            reservedSize: 40, // Espaço suficiente ajustado para legibilidade
            margin: 12,// Margem mantida
          ),
            rightTitles: SideTitles(showTitles: false),
            topTitles: SideTitles(showTitles: false),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xffe7e8ec), width: 1),
          ),
          minX: chartData.first.x,
          maxX: chartData.last.x,
          minY: chartData.map((spot) => spot.y).reduce(min) * 0.9,
          maxY: chartData.map((spot) => spot.y).reduce(max) * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: chartData,
              isCurved: true,
              colors: [
                Colors.grey[900]!
              ], // Utiliza uma lista de cores, e faz unwrap do opcional
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blueGrey, // Fundo do tooltip
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 5,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final textStyle = TextStyle(
                    color: Colors.white, // Cor do texto para branco
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  );
                  return LineTooltipItem(
                      formatCurrencyBRL(touchedSpot.y), textStyle);
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  String getTitleForValue(double value, List<FlSpot> chartData) {
    // Find the closest data point, because exact matches of timestamps might not be aligned.
    var closestSpot = chartData.reduce((a, b) => (value - a.x).abs() < (value - b.x).abs() ? a : b);
    var date = DateTime.fromMillisecondsSinceEpoch(closestSpot.x.toInt());
    return DateFormat('MMM dd').format(date); // You can adjust the date format here
  }

  List<Widget> _buildIndicatorCards(
      List<Map<String, dynamic>> indicators, List<String> keys) {
    List<Widget> cards = [];

    for (String key in keys) {
      for (Map<String, dynamic> indicator in indicators) {
        final dynamic value = indicator[key];
        if (value != null) {
          IconData infoIcon = Icons.info;
          IconData historyIcon = Icons.history; // Ícone para histórico

          cards.add(
            _buildIndicatorCard(
              name: value['name'],
              description: value['description'] ?? '',
              value: value['value'].toString() ?? '',
              infoIcon: infoIcon,
              historyIcon: historyIcon,
            ),
          );
        }
      }
    }

    return cards;
  }

  Widget _buildFairValueSection() {
    double fairValue = _calculateFairValue();
    String formattedFairValue = real.format(fairValue);

    double currentPrice = widget.active.lastPrice;
    double potentialReturn = ((fairValue - currentPrice) / currentPrice) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _showIndicatorDescription(
              'O Preço Justo é calculado utilizando a fórmula simplificada de Valor Intrínseco proposta por Benjamin Graham: VI = √(22,5 x LPA x VPA). Essa fórmula é uma estimativa do valor intrínseco por ação, considerando o Lucro por Ação (LPA) e o Valor Patrimonial por Ação (VPA). A constante 22,5 é uma simplificação para facilitar o cálculo, porém, é importante destacar que essa versão não considera fatores como taxa de crescimento esperada (g) ou taxa de rendimento do investimento sem risco (Y) presentes na fórmula original de Graham. Assim, enquanto o Preço Justo pode fornecer uma estimativa rápida do valor intrínseco, outras análises e considerações são necessárias para decisões de investimento informadas.',
              "Valor Intrínseco",
            );
          },
          child: const Row(
            children: [
              Text(
                'Valor Intrínseco por Benjamin Graham',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 110),
                child: Icon(Icons.info_outline, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preço Justo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formattedFairValue,
                  style: TextStyle(
                    fontSize: 14,
                    color: fairValue > currentPrice ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Potencial de Retorno',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${potentialReturn.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: fairValue > currentPrice ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStockDividends() {
    List<int> yearsWithInfo =
        availableYears.where((year) => _hasDataForYear(year)).toList();
    int? selectedYearToShow = selectedYear;

    if (!yearsWithInfo.contains(selectedYear)) {
      yearsWithInfo
          .sort();
      selectedYearToShow = yearsWithInfo.isNotEmpty ? yearsWithInfo.last : null;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Histórico de Remuneração',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<int>(
              value: selectedYearToShow,
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    selectedYear = value;
                  });
                }
              },
              style: TextStyle(fontSize: 16, color: Colors.black),
              itemHeight: 48,
              underline: Container(),
              icon: Icon(Icons.arrow_drop_down),
              iconSize: 32,
              elevation: 8,
              dropdownColor: Colors.white,
              isDense:
                  true,
              items: yearsWithInfo
                  .map<DropdownMenuItem<int>>(
                    (int year) => DropdownMenuItem<int>(
                      value: year,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          year.toString(),
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Padding(
            padding: const EdgeInsets.only(right: 32),
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(),
              series: <ChartSeries>[
                BarSeries<ChartData, String>(
                  dataSource: _createChartData('Dividendos'),
                  xValueMapper: (ChartData data, _) => data.xValue,
                  yValueMapper: (ChartData data, _) => data.yValue,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                    textStyle: TextStyle(fontSize: 10),
                  ),
                  width: 0.2,
                  isTrackVisible: true,
                  legendItemText: 'Dividendos',
                ),
                BarSeries<ChartData, String>(
                  dataSource: _createChartData('JCP'),
                  xValueMapper: (ChartData data, _) => data.xValue,
                  yValueMapper: (ChartData data, _) => data.yValue,
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                    textStyle: TextStyle(fontSize: 10),
                  ),
                  width: 0.2,
                  isTrackVisible: true,
                  legendItemText: 'JCP',
                ),
              ],
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _hasDataForYear(int year) {
    return dividendDataList.any((data) {
      final dateStr = data['date'] as String;
      final date = DateTime.tryParse(dateStr);
      return date != null && date.year == year;
    });
  }

  List<ChartData> _createChartData(String dataType) {
    // print('Erro ao obter detalhes do ativo: $dividendDataList');

    List<Map<String, dynamic>> filteredData = dividendDataList
        .where((element) => element['date'] != null)
        .where((element) {
      final dateStr = element['date'] as String;
      final date = DateTime.tryParse(dateStr);
      return date != null && date.year == selectedYear;
    }).toList();

    // Check if there are no dividends in the selected year
    if (filteredData.isEmpty && availableYears.isNotEmpty) {
      // Set selectedYear to the most recent year
      selectedYear = availableYears.first;
      // Filter data again with the most recent year
      filteredData = dividendDataList
          .where((element) => element['date'] != null)
          .where((element) {
        final dateStr = element['date'] as String;
        final date = DateTime.tryParse(dateStr);
        return date != null && date.year == selectedYear;
      }).toList();
    }

    List<ChartData> chartDataList = [];
    for (var i = 0; i < filteredData.length; i++) {
      if (dataType == 'Dividendos') {
        if (filteredData[i]['type'] == 'Dividendo') {
          chartDataList.add(ChartData(
            xValue:
                _getMonthName(DateTime.parse(filteredData[i]['date']).month),
            yValue: double.parse(filteredData[i]['value'].toString()),
          ));
        }
      } else if (dataType == 'JCP') {
        if (filteredData[i]['type'] == 'JCP') {
          chartDataList.add(ChartData(
            xValue:
                _getMonthName(DateTime.parse(filteredData[i]['date']).month),
            yValue: double.parse(filteredData[i]['value'].toString()),
          ));
        }
      }
    }

    return chartDataList;
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return 'Unknown Month';
    }
  }

  Widget _buildPriceCeilingSection() {
    double priceCeiling = calculatePriceCeiling(dividendDataList);
    String formattedPriceCeiling = real.format(priceCeiling);

    double currentPrice = widget.active.lastPrice;
    double potentialReturn = ((priceCeiling - currentPrice) / currentPrice) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            _showPriceCeilingDescription("Valor Intrínseco");
          },
          child: const Row(
            children: [
              Text(
                'Preço Teto pelo Método Barzim de Dividendos',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 60),
                child: Icon(Icons.info_outline, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preço Justo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formattedPriceCeiling,
                  style: TextStyle(
                    fontSize: 14,
                    color: priceCeiling > currentPrice ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Potencial de Retorno',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${potentialReturn.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: priceCeiling > currentPrice ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  double calculatePriceCeiling(List<Map<String, dynamic>> dividends) {
    double dividendYieldDesired =
        0.06;

    print('calculatePriceCeiling dividends: $dividends');

    double annualDividend =
    getAverageDividend(dividends);

    double priceCeiling = annualDividend / dividendYieldDesired;
    return priceCeiling;
  }

  double getAverageDividend(List<Map<String, dynamic>> dividends) {
    int currentYear = DateTime.now().year;

    List<Map<String, dynamic>> dividendsLastFiveYears = dividends.where((dividend) {
      DateTime date = DateTime.parse(dividend['date']);
      return date.year >= currentYear - 5;
    }).toList();

    print('dividendsLastFiveYears: $dividendsLastFiveYears');

    double totalDividends = 0.0;
    for (var dividend in dividendsLastFiveYears) {
      totalDividends += dividend['value'];
    }

    print('totalDividends: ${dividendsLastFiveYears.length}');

    double averageDividend = totalDividends / 5;

    print('averageDividend: $averageDividend');

    return averageDividend;
  }

  void _showPriceCeilingDescription(String name) {
    String calculationDescription =
    '''O preço teto é calculado utilizando o Método Barzim de Dividendos. Este método envolve calcular a média dos dividendos dos últimos 5 anos e usar um Dividend Yield desejado como base para determinar o preço teto. 
    
  Dividend Yield Desejado: 6%
  Média dos Dividendos dos Últimos 5 Anos: \$ ${getAverageDividend(dividendDataList).toStringAsFixed(2)}
    
  Preço Teto = Média dos Dividendos / Dividend Yield Desejado
  Preço Teto = \$ ${(calculatePriceCeiling(dividendDataList)).toStringAsFixed(2)}
  ''';
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 10),
              Text(
                calculationDescription,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChartData {
  final String xValue;
  final double yValue;

  ChartData({required this.xValue, required this.yValue});
}
