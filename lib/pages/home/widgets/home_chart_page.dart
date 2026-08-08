import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartPage extends StatefulWidget {
  final String ticker;

  const ChartPage({super.key, required this.ticker});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<Map<String, dynamic>> dividendDataList = [];
  int selectedYear = DateTime.now().year;
  List<int> availableYears = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    final String apiUrl = "https://mfinance.com.br/api/v1/stocks/dividends/${widget.ticker}";
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> dividends = jsonData['dividends'] ?? [];
        if (mounted) {
          setState(() {
            dividendDataList = List<Map<String, dynamic>>.from(dividends);
            availableYears = dividendDataList
                .where((d) => d['date'] != null)
                .map((d) => DateTime.tryParse(d['date'])?.year ?? DateTime.now().year)
                .toSet()
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  List<ChartData> _createChartData() {
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.cardDark,
        title: Text('Dividendos ${widget.ticker}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (availableYears.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ano de Referência', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
            const SizedBox(height: 16),
            Expanded(
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
                    dataSource: _createChartData(),
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
      ),
    );
  }
}

class ChartData {
  final DateTime date;
  final double value;
  ChartData(this.date, this.value);
}
