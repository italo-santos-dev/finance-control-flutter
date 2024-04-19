import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/models/asset_model.dart';  // Assegure-se de que este caminho esteja correto
import 'package:flutter_investment_control/models/transaction_model.dart';
import 'package:intl/intl.dart';

class PortfolioPerformanceChart extends StatefulWidget {
  final List<Asset> assets;

  PortfolioPerformanceChart({Key? key, required this.assets}) : super(key: key);

  @override
  _PortfolioPerformanceChartState createState() => _PortfolioPerformanceChartState();
}

class _PortfolioPerformanceChartState extends State<PortfolioPerformanceChart> {
  bool _isLoading = true;
  double _returnPercentage = 0.0; // Inicialização

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), () {
      final portfolioValues = calculatePortfolioValues(widget.assets);
      setState(() {
        _returnPercentage = portfolioValues['returnPercentage'] ?? 0.0;  // Assume default 0.0 se nulo
        _isLoading = false;
      });
    });
  }

  Map<String, double> calculatePortfolioValues(List<Asset> assets) {
    double totalInvested = 0;
    double currentPortfolioValue = 0;

    for (var asset in assets) {
      updateAssetDetails(asset); // Supondo que atualiza preços, etc.
      double invested = asset.averagePrice * asset.quantity;
      double currentValue = asset.currentPrice * asset.quantity;

      totalInvested += invested;
      currentPortfolioValue += currentValue;
    }

    double returnPercentage = ((currentPortfolioValue - totalInvested) / totalInvested) * 100;

    return {
      'totalInvested': totalInvested,
      'currentPortfolioValue': currentPortfolioValue,
      'returnPercentage': returnPercentage
    };
  }

  LineChartData mainData() {
    List<FlSpot> spots = List.generate(12, (index) => FlSpot(index.toDouble(), _returnPercentage * (index / 11)));

    return LineChartData(
      gridData: FlGridData(
        show: false,  // Desabilitar a grade para um visual mais limpo
      ),
      titlesData: FlTitlesData(
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTextStyles: (context, value) => const TextStyle(
            color: Colors.blueGrey,  // Cor mais suave para os títulos
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          getTitles: (value) {
            // Mostra uma etiqueta a cada dois meses para evitar aglomeração
            return (value.toInt() % 2 == 0) ? 'Mês ${value.toInt() + 1}' : '';
          },
          interval: 1,
          margin: 8,
        ),
        topTitles: SideTitles(showTitles: false),
        rightTitles: SideTitles(showTitles: false),
        leftTitles: SideTitles(
          showTitles: true,
          getTextStyles: (context, value) => const TextStyle(
            color: Colors.blueGrey,  // Cor mais suave para os títulos
            fontSize: 10,
          ),
          getTitles: (value) => '${value.toStringAsFixed(0)}%',
          margin: 12,
          reservedSize: 40,
        ),
      ),
      borderData: FlBorderData(show: false),  // Sem bordas para um visual mais limpo
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: _returnPercentage + 5,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          colors: [Theme.of(context).colorScheme.secondary],  // Cores temáticas do contexto
          barWidth: 5,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            colors: [Theme.of(context).colorScheme.secondary.withOpacity(0.3)],
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
                '${touchedSpot.y.toStringAsFixed(2)}%', textStyle,
              );
            }).toList();
          },
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gráfico de Rentabilidade da Carteira')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              height: 300,
              padding: const EdgeInsets.symmetric(horizontal: 10.0), // Adiciona padding horizontal
              child: LineChart(
                mainData(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Retorno Acumulado: ${_returnPercentage.toStringAsFixed(2)}%',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateAssetDetails(Asset asset) {
    double totalCost = 0; // Custo total baseado apenas em compras
    int totalQuantityPurchased = 0; // Quantidade total comprada

    // Iterar sobre as transações para ajustar o custo e a quantidade
    for (var transaction in asset.transactions) {
      if (transaction.type == TransactionType.buy) {
        totalCost += transaction.price * transaction.quantity;
        totalQuantityPurchased += transaction.quantity;
      }
    }

    // Calcular o preço médio somente das compras
    if (totalQuantityPurchased > 0) {
      asset.averagePrice = totalCost / totalQuantityPurchased;
    } else {
      asset.averagePrice = 0; // Se não houver compras, define como zero
    }

    // Ajustar a quantidade total no ativo baseado no total de compras e vendas
    asset.quantity = asset.transactions.fold(0, (total, t) => total + (t.type == TransactionType.buy ? t.quantity : -t.quantity));
  }

}
