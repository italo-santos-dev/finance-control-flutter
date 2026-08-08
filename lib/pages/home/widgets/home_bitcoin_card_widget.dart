import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

class StockDividends {
  Future<List<Map<String, dynamic>>> getStockDividends() async {
    const String apiUrl = "https://mfinance.com.br/api/v1/stocks/dividends/SANB11";
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> dividends = jsonData['dividends'] ?? [];
        return List<Map<String, dynamic>>.from(dividends);
      }
    } catch (_) {}
    return [];
  }
}

class DividendChart extends StatefulWidget {
  const DividendChart({super.key});

  @override
  State<DividendChart> createState() => _DividendChartState();
}

class _DividendChartState extends State<DividendChart> {
  List<Map<String, dynamic>> dividendDataList = [];
  int selectedYear = DateTime.now().year;
  List<int> availableYears = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    StockDividends stockDividends = StockDividends();
    List<Map<String, dynamic>> data = await stockDividends.getStockDividends();
    if (mounted) {
      setState(() {
        dividendDataList = data;
        availableYears = data
            .where((d) => d['date'] != null)
            .map((d) => DateTime.tryParse(d['date'])?.year ?? DateTime.now().year)
            .toSet()
            .toList();
      });
    }
  }

  List<ChartData> _createChartData(String dataType) {
    List<Map<String, dynamic>> filteredData = dividendDataList
        .where((element) => element['date'] != null)
        .where((element) {
      final date = DateTime.tryParse(element['date']);
      return date != null && date.year == selectedYear;
    }).toList();

    return filteredData.map((element) {
      final date = DateTime.tryParse(element['date']) ?? DateTime.now();
      final value = (element['value'] as num?)?.toDouble() ?? 0.0;
      return ChartData(date, value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                'Dividendos SANB11',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              if (availableYears.isNotEmpty)
                DropdownButton<int>(
                  value: availableYears.contains(selectedYear) ? selectedYear : availableYears.first,
                  dropdownColor: AppColors.inputDark,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: availableYears.map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (newYear) {
                    if (newYear != null) setState(() => selectedYear = newYear);
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: const MajorGridLines(color: AppColors.borderDark, width: 0.5),
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
              series: <CartesianSeries>[
                ColumnSeries<ChartData, DateTime>(
                  dataSource: _createChartData('rendimento'),
                  xValueMapper: (ChartData data, _) => data.date,
                  yValueMapper: (ChartData data, _) => data.value,
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final DateTime date;
  final double value;
  ChartData(this.date, this.value);
}
