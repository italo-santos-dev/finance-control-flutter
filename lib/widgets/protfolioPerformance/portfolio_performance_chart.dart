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
  List<String> transactionDates = [];

  @override
  void initState() {
    super.initState();
    transactionDates = getTransactionDates(); // Carrega as datas das transações
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

  List<String> getTransactionDates() {
    List<Transaction> transactions = widget.assets.expand((asset) => asset.transactions).toList();
    // Ordenar transações por data
    transactions.sort((a, b) => a.date.compareTo(b.date));

    // Extrair datas únicas e formatar
    Set<String> uniqueDates = transactions.map((t) => DateFormat('MM/yyyy').format(t.date)).toSet();

    // Converter em lista e ordenar novamente (para segurança)
    List<String> sortedUniqueDates = uniqueDates.toList();
    sortedUniqueDates.sort((a, b) => DateFormat('MM/yyyy').parse(a).compareTo(DateFormat('MM/yyyy').parse(b)));

    return sortedUniqueDates;
  }

  List<double> simulateCDIData(int length) {
    double annualReturn = 0.04; // 4% ao ano
    double monthlyReturn = pow(1 + annualReturn, 1/12) - 1; // Conversão para retorno mensal
    List<double> cdiData = [];
    double value = 9;  // Valor inicial arbitrário

    for (int i = 0; i < length; i++) {
      value *= (1 + monthlyReturn);
      cdiData.add(value);
    }

    return cdiData;
  }

LineChartData mainData(List<String> dates) {
    // Definir o intervalo com base no número de datas para evitar superlotação no eixo X
    int interval = max(1, dates.length ~/ 4); // Por exemplo, exibir uma etiqueta a cada 1/6 das datas

    List<double> cdiData = simulateCDIData(dates.length);  // Gera dados simulados do CDI para o período

    List<FlSpot> portfolioSpots = List.generate(dates.length, (index) =>
        FlSpot(index.toDouble(), _returnPercentage * (index / (dates.length - 1))));

    List<FlSpot> cdiSpots = List.generate(dates.length, (index) =>
        FlSpot(index.toDouble(), cdiData[index]));

    return LineChartData(
      gridData: const FlGridData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          // Mudou de tooltipBgColor para getTooltipColor
          getTooltipColor: (LineBarSpot touchedSpot) => Colors.blueGrey,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((touchedSpot) {
              final TextStyle textStyle;
              if (touchedSpot.barIndex == 0) {
                // Estilo para a carteira
                textStyle = const TextStyle(
                  color: Colors.black,  // Cor preta para a carteira
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                );
              } else {
                // Estilo para o CDI
                textStyle = const TextStyle(
                  color: Colors.green,  // Cor verde para o CDI
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                );
              }
              return LineTooltipItem(
                '${touchedSpot.y.toStringAsFixed(2)}%', textStyle,
              );
            }).toList();
          },
        ),
      ),
      titlesData: FlTitlesData(
        // EIXO X (Embaixo)
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1, // O intervalo do componente fica em 1 para passar por todos
            reservedSize: 32, // Espaço para não cortar o texto
            getTitlesWidget: (double value, TitleMeta meta) {
              int index = value.toInt();
              String texto = '';
              // Mostra a etiqueta apenas a cada 'interval' índices e garante que não ultrapassa a lista
              if (index >= 0 && index < dates.length && index % interval == 0) {
                texto = dates[index];
              }
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 8, // Antigo margin
                child: Text(
                  texto,
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
        // Desativa topo e direita
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        // EIXO Y (Esquerda)
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (double value, TitleMeta meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 12, // Antigo margin
                child: Text(
                  '${value.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (dates.length - 1).toDouble(), // Convertido para double para evitar erro de tipo
      minY: 0,
      maxY: max(_returnPercentage + 5, cdiData.isNotEmpty ? cdiData.last + 5 : 5),
      lineBarsData: [
        // LINHA DA CARTEIRA
        LineChartBarData(
          spots: portfolioSpots,
          isCurved: true,
          color: Theme.of(context).colorScheme.secondary, // Singular (color)
          barWidth: 5,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3), // Singular (color)
          ),
        ),
        // LINHA DO CDI
        LineChartBarData(
          spots: cdiSpots,
          isCurved: true,
          color: Colors.green, // Singular (color)
          barWidth: 5,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withOpacity(0.3), // Singular (color)
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<double> cdiData = simulateCDIData(transactionDates.length);
    double cdiReturnPercentage = ((cdiData.last - cdiData.first) / cdiData.first) * 100;

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // This makes the whole column scrollable
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Text(
                  "Rentabilidade comparada com índices",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                height: 300,
                padding: const EdgeInsets.only(left: 8.0, right: 24.0), // Adjusted padding to shift the chart to the left
                child: LineChart(
                  mainData(getTransactionDates()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Retorno Acumulado: ${_returnPercentage.toStringAsFixed(2)}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Retorno Acumulado do CDI: ${cdiReturnPercentage.toStringAsFixed(2)}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              SizedBox(height: 24,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Rentabilidade comparada com índices",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              buildRecentTransactionsList()
            ],
          ),
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

  Widget buildRecentTransactionsList() {
    List<Transaction> recentTransactions = widget.assets.expand((asset) => asset.transactions).toList();
    recentTransactions.sort((a, b) => b.date.compareTo(a.date));
    recentTransactions = recentTransactions.take(5).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // Prevents the ListView from scrolling independently
      itemCount: recentTransactions.length,
      itemBuilder: (context, index) {
        Transaction transaction = recentTransactions[index];
        return ListTile(
          leading: Icon(transaction.type == TransactionType.buy ? Icons.arrow_upward : Icons.arrow_downward),
          title: Text("${transaction.ticker} - ${transaction.quantity} units"),
          subtitle: Text("${DateFormat.yMd().format(transaction.date)} at \$${transaction.price.toStringAsFixed(2)}"),
        );
      },
    );
  }
}
