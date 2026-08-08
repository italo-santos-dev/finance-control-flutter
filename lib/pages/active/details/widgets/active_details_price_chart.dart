import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:intl/intl.dart';

class ActiveDetailsPriceChart extends StatelessWidget {
  final List<FlSpot> priceSpots;
  final List<dynamic> rawHistoricalItems;
  final String selectedPeriod;
  final bool isLoadingChart;
  final Function(String) onPeriodSelected;

  const ActiveDetailsPriceChart({
    super.key,
    required this.priceSpots,
    required this.rawHistoricalItems,
    required this.selectedPeriod,
    required this.isLoadingChart,
    required this.onPeriodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');

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
                'Cotação Histórica',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              _buildPeriodSelectorPills(
                ['1D', '5D', '1M', '6M', 'YTD', '1A', '5A', 'MÁX'],
                selectedPeriod,
                onPeriodSelected,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: isLoadingChart
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : priceSpots.isEmpty
                    ? const Center(
                        child: Text(
                          'Cotação histórica indisponível no momento.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      )
                    : LineChart(_buildChartDataConfig(realFormat)),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartDataConfig(NumberFormat realFormat) {
    double minY = priceSpots.map((s) => s.y).reduce(min);
    double maxY = priceSpots.map((s) => s.y).reduce(max);
    double margin = (maxY - minY) * 0.15;
    if (margin == 0) margin = 1.0;

    int totalSpots = priceSpots.length;
    double xInterval = (totalSpots / 5).floorToDouble().clamp(1.0, 500.0);
    double yInterval = ((maxY - minY) / 4).clamp(0.01, 1000.0);

    return LineChartData(
      minY: minY - margin,
      maxY: maxY + margin,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.borderDark, strokeWidth: 0.8),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 55,
            interval: yInterval,
            getTitlesWidget: (val, meta) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                realFormat.format(val).replaceAll('R\$', '').trim(),
                style: const TextStyle(fontSize: 9, color: Colors.grey),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: xInterval,
            reservedSize: 22,
            getTitlesWidget: (val, meta) {
              int index = val.toInt();
              if (index < 0 || index >= priceSpots.length) return const SizedBox.shrink();

              String label = 'Mês ${(index % 12) + 1}';
              if (rawHistoricalItems.isNotEmpty && index < rawHistoricalItems.length) {
                var item = rawHistoricalItems[index];
                if (item['date'] != null) {
                  try {
                    DateTime dt = DateTime.parse(item['date'].toString().split('T')[0]);
                    label = DateFormat('MMM/yy', 'pt_BR').format(dt);
                  } catch (_) {}
                }
              }

              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: priceSpots,
          isCurved: true,
          color: AppColors.primaryBlue,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue.withValues(alpha: 0.35),
                AppColors.primaryBlue.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelectorPills(List<String> periods, String selected, Function(String) onSelect) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.inputDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map((p) {
          bool isSel = selected == p;
          return GestureDetector(
            onTap: () => onSelect(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSel ? AppColors.primaryBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSel ? Colors.white : Colors.grey,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
