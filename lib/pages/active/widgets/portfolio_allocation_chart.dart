import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/asset_model.dart';

class PortfolioAllocationChart extends StatelessWidget {
  final List<Asset> assets;
  final double totalPortfolioValue;
  final bool hideValues;

  const PortfolioAllocationChart({
    super.key,
    required this.assets,
    required this.totalPortfolioValue,
    this.hideValues = false,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, double> classTotals = _calculateAllocationByClass();

    List<PieChartSectionData> sections = [];
    List<Map<String, dynamic>> legendItems = [];

    List<Color> palette = [
      AppColors.primaryBlue,
      AppColors.emeraldGreen,
      Colors.amber,
      Colors.purpleAccent,
      AppColors.redLoss,
    ];

    int colorIdx = 0;
    classTotals.forEach((className, amount) {
      double pct = totalPortfolioValue > 0 ? (amount / totalPortfolioValue) * 100 : 0.0;
      Color color = palette[colorIdx % palette.length];
      colorIdx++;

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount > 0 ? amount : 1,
          radius: 18,
          showTitle: false,
        ),
      );

      legendItems.add({
        'name': className,
        'pct': pct,
        'color': color,
      });
    });

    if (sections.isEmpty) {
      sections = [
        PieChartSectionData(color: AppColors.chipDark, value: 100, radius: 18, showTitle: false),
      ];
      legendItems = [
        {'name': 'Sem Ativos', 'pct': 100.0, 'color': Colors.grey},
      ];
    }

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
            children: const [
              Icon(Icons.pie_chart_outline, size: 18, color: AppColors.blueAccent),
              SizedBox(width: 8),
              Text(
                'Alocação',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Donut Chart with Center Text
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 55,
                    startDegreeOffset: -90,
                    sections: sections,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hideValues ? '••••' : '100%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Allocation Legend List
          Column(
            children: legendItems.map((item) {
              Color color = item['color'] as Color;
              String name = item['name'] as String;
              double pct = item['pct'] as double;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                    Text(
                      hideValues ? '••%' : '${pct.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateAllocationByClass() {
    Map<String, double> map = {};
    if (assets.isEmpty) {
      return {'Ações': 45.0, 'FIIs': 30.0, 'Renda Fixa': 20.0, 'Cripto': 5.0};
    }
    for (var a in assets) {
      String cat = a.activeType.toUpperCase();
      if (cat.contains('FII')) {
        cat = 'FIIs';
      } else if (cat.contains('AÇÃO') || cat.contains('ACAO')) {
        cat = 'Ações';
      } else if (cat.contains('CRIPTO')) {
        cat = 'Cripto';
      } else if (cat.contains('RENDA')) {
        cat = 'Renda Fixa';
      } else {
        cat = 'Outros';
      }

      map[cat] = (map[cat] ?? 0.0) + a.totalAmount;
    }
    return map;
  }
}
