// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter_investment_control/services/apis/api_stocks_historicals.dart';
// import 'package:intl/intl.dart';
// import 'dart:math'; // Add this line to use min and max
//
// class ChartPage extends StatefulWidget {
//   final String ticker;
//
//   ChartPage({Key? key, required this.ticker}) : super(key: key);
//
//   @override
//   _ChartPageState createState() => _ChartPageState();
// }
//
// class _ChartPageState extends State<ChartPage> {
//   late Future<List<FlSpot>> _chartData;
//
//   String formatCurrencyBRL(double value) {
//     final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
//     return format.format(value);
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _chartData = _fetchChartData();
//   }
//
//   Future<List<FlSpot>> _fetchChartData() async {
//     var stockData = await StocksHistoricals().getStockHistoricals(widget.ticker);
//     List<dynamic> historicals = stockData?['historicals'] ?? [];
//
//     List<FlSpot> chartData = [];
//     for (var i = 0; i < historicals.length; i++) {
//       DateTime date = DateTime.parse(historicals[i]['date']);
//       double close = (historicals[i]['close'] as num).toDouble();
//       chartData.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), close));
//     }
//
//     return chartData;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Stock Price Chart'),
//       ),
//       body: FutureBuilder<List<FlSpot>>(
//         future: _chartData,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else {
//             return _buildChart(snapshot.data!);
//           }
//         },
//       ),
//     );
//   }
//
//   Widget _buildChart(List<FlSpot> chartData) {
//     return Container(
//       height: MediaQuery.of(context).size.height / 2, // Define a altura para metade da altura da tela
//       padding: EdgeInsets.only(right: 20),  // Reduz o espaço à direita do gráfico
//       child: LineChart(
//         LineChartData(
//           gridData: FlGridData(show: false), // Desativa a grade
//           titlesData: FlTitlesData(
//             bottomTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 22,
//               getTextStyles: (context, value) => const TextStyle(
//                 color: Colors.blueGrey, // Cor azul-cinza para os títulos do eixo X
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12, // Tamanho de fonte conforme sua especificação
//               ),
//               getTitles: (value) {
//                 DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
//                 return DateFormat('MMM d').format(date);  // Formato mais limpo e moderno para a data
//               },
//               margin: 10,  // Margem ajustada como no exemplo
//             ),
//             leftTitles: SideTitles(
//               showTitles: true,
//               getTitles: (value) {
//                 return '\$${value.toStringAsFixed(2)}';
//               },
//               getTextStyles: (context, value) => const TextStyle(
//                 color: Colors.blueGrey, // Cor azul-cinza para os títulos do eixo Y
//                 fontSize: 12, // Tamanho de fonte conforme sua especificação
//               ),
//               reservedSize: 40,  // Espaço suficiente ajustado para legibilidade
//               margin: 12,  // Margem mantida
//             ),
//             rightTitles: SideTitles(showTitles: false),
//             topTitles: SideTitles(showTitles: false),
//           ),
//           borderData: FlBorderData(
//             show: true,
//             border: Border.all(color: const Color(0xffe7e8ec), width: 1),
//           ),
//           minX: chartData.first.x,
//           maxX: chartData.last.x,
//           minY: chartData.map((spot) => spot.y).reduce(min) * 0.9,
//           maxY: chartData.map((spot) => spot.y).reduce(max) * 1.1,
//           lineBarsData: [
//             LineChartBarData(
//               spots: chartData,
//               isCurved: true,
//               colors: [Colors.grey[900]!], // Utiliza uma lista de cores, e faz unwrap do opcional
//               barWidth: 2,
//               isStrokeCapRound: true,
//               dotData: FlDotData(show: false),
//               belowBarData: BarAreaData(show: false),
//             ),
//           ],
//           lineTouchData: LineTouchData(
//             touchTooltipData: LineTouchTooltipData(
//               tooltipBgColor: Colors.blueGrey, // Fundo do tooltip
//               tooltipPadding: const EdgeInsets.all(8),
//               tooltipMargin: 5,
//               getTooltipItems: (List<LineBarSpot> touchedSpots) {
//                 return touchedSpots.map((touchedSpot) {
//                   final textStyle = TextStyle(
//                     color: Colors.white, // Cor do texto para branco
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   );
//                   return LineTooltipItem(
//                       '\$${touchedSpot.y.toStringAsFixed(2)}', textStyle
//                   );
//                 }).toList();
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_investment_control/services/apis/api_stocks_historicals.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // Add this line to use min and max

class ChartPage extends StatefulWidget {
  final String ticker;

  ChartPage({Key? key, required this.ticker}) : super(key: key);

  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  late Future<List<FlSpot>> _chartData;
  Key _chartKey = UniqueKey(); // Chave única para o FutureBuilder

  String formatCurrencyBRL(double value) {
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return format.format(value);
  }

  @override
  void initState() {
    super.initState();
    _chartData = _fetchChartData();
  }

  Future<List<FlSpot>> _fetchChartData({int months = 3}) async {
    var stockData = await StocksHistoricals().getStockHistoricals(widget.ticker, months);
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

    print("Recebidos ${historicals.length} pontos de dados da API para os últimos $months meses.");
    print("Processados ${chartData.length} pontos de dados FlSpot para o gráfico.");
    return chartData;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Price Chart'),
      ),
      body: Column(
        children: [
          _buildFilterButtons(), // Botões de filtro
          Expanded(
            child: FutureBuilder<List<FlSpot>>(
              key: _chartKey, // Usa a chave que muda a cada novo futuro
              future: _chartData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return _buildChart(snapshot.data!);
                }
              },
            ),
          ),        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    final List<Map<String, dynamic>> filters = [
      {'label': '1 MÊS', 'months': 1},
      {'label': '3 MESES', 'months': 3},
      {'label': '6 MESES', 'months': 6},
      {'label': '1 ANO', 'months': 12},
      {'label': '5 ANOS', 'months': 60},
    ];

    void _applyFilter(int months) {
      print("Filtro Aplicado: $months meses");
      setState(() {
        _chartData = _fetchChartData(months: months);
        _chartKey = UniqueKey(); // Atualiza a chave para forçar reconstrução do FutureBuilder
      });
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: filters.map((filter) {
          return ElevatedButton(
            onPressed: () => _applyFilter(filter['months']),
            child: Text(filter['label']),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(List<FlSpot> chartData) {
    return Container(
      height: MediaQuery.of(context).size.height /
          2, // Define a altura para metade da altura da tela
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
                color:
                    Colors.blueGrey, // Cor azul-cinza para os títulos do eixo X
                fontWeight: FontWeight.bold,
                fontSize: 12, // Tamanho de fonte conforme sua especificação
              ),
              getTitles: (value) {
                DateTime date =
                    DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return DateFormat('MMM d')
                    .format(date); // Formato mais limpo e moderno para a data
              },
              margin: 10, // Margem ajustada como no exemplo
            ),
            leftTitles: SideTitles(
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
              margin: 12, // Margem mantida
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
}
