import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/asset_model.dart';
import 'package:flutter_investment_control/models/transaction_model.dart';
import 'package:intl/intl.dart';

class PortfolioPerformanceChart extends StatefulWidget {
  final List<Asset> assets;

  const PortfolioPerformanceChart({super.key, required this.assets});

  @override
  State<PortfolioPerformanceChart> createState() => _PortfolioPerformanceChartState();
}

class _PortfolioPerformanceChartState extends State<PortfolioPerformanceChart> {
  bool _isLoading = true;
  double _returnPercentage = 0.0;
  List<String> transactionDates = [];

  @override
  void initState() {
    super.initState();
    transactionDates = getTransactionDates();
    Future.delayed(const Duration(milliseconds: 300), () {
      final portfolioValues = calculatePortfolioValues(widget.assets);
      if (mounted) {
        setState(() {
          _returnPercentage = portfolioValues['returnPercentage'] ?? 0.0;
          _isLoading = false;
        });
      }
    });
  }

  Map<String, double> calculatePortfolioValues(List<Asset> assets) {
    double totalInvested = 0;
    double currentPortfolioValue = 0;

    for (var asset in assets) {
      double invested = asset.averagePrice * asset.quantity;
      double currentValue = asset.currentPrice * asset.quantity;
      totalInvested += invested;
      currentPortfolioValue += currentValue;
    }

    double returnPercentage = totalInvested > 0 ? ((currentPortfolioValue - totalInvested) / totalInvested) * 100 : 0.0;

    return {
      'totalInvested': totalInvested,
      'currentPortfolioValue': currentPortfolioValue,
      'returnPercentage': returnPercentage
    };
  }

  List<String> getTransactionDates() {
    List<Transaction> transactions = widget.assets.expand((asset) => asset.transactions).toList();
    transactions.sort((a, b) => a.date.compareTo(b.date));
    return transactions.map((t) => DateFormat('dd/MM').format(t.date)).toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isPos = _returnPercentage >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Desempenho da Carteira',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPos ? AppColors.emeraldGreen : AppColors.redLoss).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isPos ? '+' : ''}${_returnPercentage.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPos ? AppColors.emeraldGreen : AppColors.redLoss,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: const FlTitlesData(
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 1.0),
                            FlSpot(1, 1.1),
                            FlSpot(2, 1.05),
                            FlSpot(3, 1.2),
                            FlSpot(4, 1.18),
                            FlSpot(5, 1.25),
                          ],
                          isCurved: true,
                          color: AppColors.primaryBlue,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryBlue.withValues(alpha: 0.3),
                                AppColors.primaryBlue.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
