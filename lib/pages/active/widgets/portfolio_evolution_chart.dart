import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';

class PortfolioEvolutionChart extends StatefulWidget {
  final double totalEquity;
  final bool hideValues;

  const PortfolioEvolutionChart({
    super.key,
    required this.totalEquity,
    required this.hideValues,
  });

  @override
  State<PortfolioEvolutionChart> createState() => _PortfolioEvolutionChartState();
}

class _PortfolioEvolutionChartState extends State<PortfolioEvolutionChart> {
  String _selectedPeriod = '1Y';

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = _generateEvolutionSpots(widget.totalEquity);

    double minY = spots.map((s) => s.y).reduce(min);
    double maxY = spots.map((s) => s.y).reduce(max);
    double margin = (maxY - minY) * 0.15;
    if (margin <= 0) margin = 10000;

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
                  Icon(Icons.show_chart, size: 18, color: AppColors.blueAccent),
                  SizedBox(width: 8),
                  Text(
                    'Evolução Patrimonial',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              _buildPeriodSelector(),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: minY - margin,
                maxY: maxY + margin,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (val) => const FlLine(
                    color: AppColors.borderDark,
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: ((maxY - minY) / 3).clamp(1.0, 1000000.0),
                      getTitlesWidget: (val, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            widget.hideValues ? '•••' : _formatShortCurrency(val),
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        List<String> months = ['Jan', 'Mar', 'Mai', 'Jul', 'Set', 'Nov'];
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
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primaryBlue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryBlue.withValues(alpha: 0.4),
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

  Widget _buildPeriodSelector() {
    List<String> periods = ['1M', '6M', '1Y', 'ALL'];
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.inputDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: periods.map((p) {
          bool isSel = _selectedPeriod == p;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  List<FlSpot> _generateEvolutionSpots(double currentTotal) {
    double base = currentTotal > 0 ? currentTotal : 100000;
    return [
      FlSpot(0, base * 0.85),
      FlSpot(1, base * 0.88),
      FlSpot(2, base * 0.92),
      FlSpot(3, base * 0.95),
      FlSpot(4, base * 0.98),
      FlSpot(5, base),
    ];
  }

  String _formatShortCurrency(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    }
    return val.toStringAsFixed(0);
  }
}
