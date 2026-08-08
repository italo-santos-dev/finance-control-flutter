import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:intl/intl.dart';

class PortfolioMonthlyDividends extends StatelessWidget {
  final double accumulatedDividends;
  final bool hideValues;

  const PortfolioMonthlyDividends({
    super.key,
    required this.accumulatedDividends,
    required this.hideValues,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');
    double semesterTotal = accumulatedDividends > 0 ? accumulatedDividends : 12450.80;
    double monthlyAverage = semesterTotal / 6;

    List<double> barValues = [1850, 2100, 1950, 2400, 1650, 2500];
    List<String> months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'];

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
              Row(
                children: const [
                  Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.emeraldGreen),
                  SizedBox(width: 8),
                  Text(
                    'Proventos Mensais',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Abrindo histórico detalhado de proventos')),
                  );
                },
                child: const Text(
                  'Detalhes',
                  style: TextStyle(fontSize: 11, color: AppColors.blueAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 3000,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        int idx = val.toInt();
                        if (idx >= 0 && idx < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(months[idx], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                barGroups: barValues.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: AppColors.emeraldGreen.withValues(alpha: 0.85),
                        width: 18,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL NO SEMESTRE', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    hideValues ? 'R\$ •••••' : realFormat.format(semesterTotal),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('MÉDIA MENSAL', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    hideValues ? 'R\$ •••••' : realFormat.format(monthlyAverage),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
