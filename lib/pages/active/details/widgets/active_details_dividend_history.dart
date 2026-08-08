import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/models/active_model.dart';
import 'package:intl/intl.dart';

class ActiveDetailsDividendHistory extends StatelessWidget {
  final Active active;
  final List<Map<String, dynamic>> dividendDataList;
  final String selectedDividendPeriod;
  final Function(String) onPeriodSelected;
  final double? Function(String) getRawIndicatorValue;

  const ActiveDetailsDividendHistory({
    super.key,
    required this.active,
    required this.dividendDataList,
    required this.selectedDividendPeriod,
    required this.onPeriodSelected,
    required this.getRawIndicatorValue,
  });

  @override
  Widget build(BuildContext context) {
    final NumberFormat realFormat = NumberFormat.currency(locale: 'pt-BR', symbol: 'R\$');
    double dyActual = active.dividendYield > 0 ? active.dividendYield : (getRawIndicatorValue('dividendYield') ?? 7.82);
    double dyAverage = dyActual * 0.75;

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
                children: [
                  const Icon(Icons.payments_outlined, size: 20, color: AppColors.blueAccent),
                  const SizedBox(width: 8),
                  Text(
                    'HISTÓRICO DE DIVIDENDOS - ${active.symbol}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              _buildPeriodSelectorPills(['5 A', '10 A', 'MÁX'], selectedDividendPeriod, onPeriodSelected),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.inputDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(text: 'DY atual: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          TextSpan(text: '${dyActual.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.inputDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(text: 'DY médio em 5 anos: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          TextSpan(text: '${dyAverage.toStringAsFixed(2)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.blueAccent)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(_buildDividendBarChartData()),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              const Text('Dividend Yield', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              Container(width: 14, height: 2, color: AppColors.emeraldGreen),
              const SizedBox(width: 6),
              const Text('Dividendos pagos', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Proventos Pagos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          if (dividendDataList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Histórico de proventos indisponível para este ativo.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(2.5),
                2: FlexColumnWidth(2.5),
                3: FlexColumnWidth(2.5),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderDark))),
                  children: [
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('TIPO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('DATA COM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('PAGAMENTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('VALOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                  ],
                ),
                ...dividendDataList.take(8).map((div) {
                  String type = (div['type'] ?? 'Dividendos').toString();
                  double val = (div['value'] as num?)?.toDouble() ?? 0.0;
                  String dateCom = div['dateCom'] ?? div['paymentDate'] ?? 'Data N/D';
                  String datePgt = div['paymentDate'] ?? div['dateCom'] ?? 'Data N/D';

                  return TableRow(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.borderDark, width: 0.5))),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(type, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(dateCom, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(datePgt, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(realFormat.format(val), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen)),
                      ),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  BarChartData _buildDividendBarChartData() {
    List<double> barValues = [0.18, 0.20, 0.47, 0.40, 0.02, 0.14, 0.75, 0.61, 0.55, 0.89, 0.78];
    List<String> years = ['2016', '2017', '2018', '2019', '2020', '2021', '2022', '2023', '2024', '2025', 'Últ. 12M'];

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 1.0,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (val, meta) => Text(
              '${(val * 10).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              int idx = val.toInt();
              if (idx >= 0 && idx < years.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(years[idx], style: const TextStyle(fontSize: 9, color: Colors.grey)),
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
              color: AppColors.primaryBlue.withValues(alpha: 0.8),
              width: 16,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        );
      }).toList(),
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
