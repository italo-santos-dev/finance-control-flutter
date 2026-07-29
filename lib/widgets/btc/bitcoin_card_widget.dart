import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

class StockDividends {
  Future<List<Map<String, dynamic>>> getStockDividends() async {
    final String apiUrl = "https://mfinance.com.br/api/v1/stocks/dividends/SANB11";

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> dividends = jsonData['dividends'];

      return List<Map<String, dynamic>>.from(dividends);
    } else {
      throw Exception('Failed to load stock dividends');
    }
  }
}

class DividendChart extends StatefulWidget {
  @override
  _DividendChartState createState() => _DividendChartState();
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
    setState(() {
      if (data != null) {
        dividendDataList = data;
        availableYears = data
            .where((dividend) => dividend['date'] != null)
            .map((dividend) => DateTime.parse(dividend['date']).year)
            .toSet()
            .toList();
      } else {
        // Handle the case where data is null
        // For example, show an error message or retry fetching data
      }
    });
  }

  List<ChartData> _createChartData(String dataType) {
    List<Map<String, dynamic>> filteredData = dividendDataList
        .where((element) => element['date'] != null)
        .where((element) {
      final dateStr = element['date'] as String;
      final date = DateTime.tryParse(dateStr);
      return date != null && date.year == selectedYear;
    }).toList();

    List<ChartData> chartDataList = [];
    for (var i = 0; i < filteredData.length; i++) {
      if (dataType == 'Dividendos') {
        if (filteredData[i]['type'] == 'Dividendo') {
          chartDataList.add(ChartData(
            xValue: _getMonthName(DateTime.parse(filteredData[i]['date']).month),
            yValue: double.parse(filteredData[i]['value'].toString()),
          ));
        }
      } else if (dataType == 'JCP') {
        if (filteredData[i]['type'] == 'JCP') {
          chartDataList.add(ChartData(
            xValue: _getMonthName(DateTime.parse(filteredData[i]['date']).month),
            yValue: double.parse(filteredData[i]['value'].toString()),
          ));
        }
      }
    }

    return chartDataList;
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Apr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
      default:
        return 'Unknown Month';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Remuneração'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 52.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Histórico de Remuneração',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  value: selectedYear,
                  onChanged: (int? value) {
                    if (value != null) {
                      setState(() {
                        selectedYear = value;
                      });
                    }
                  },
                  style: TextStyle(fontSize: 16, color: Colors.blueAccent), // Estilo do texto
                  itemHeight: 48, // Altura do botão
                  underline: Container(), // Remove a linha abaixo do botão
                  icon: Icon(Icons.arrow_drop_down), // Ícone do botão dropdown
                  iconSize: 32, // Tamanho do ícone do botão dropdown
                  elevation: 8, // Elevação do dropdown
                  dropdownColor: Colors.white, // Cor do dropdown
                  items: availableYears.map<DropdownMenuItem<int>>(
                        (int year) => DropdownMenuItem<int>(
                      value: year,
                      child: Text(
                        year.toString(),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: SfCartesianChart(
                  primaryXAxis: const CategoryAxis(),
                  primaryYAxis: const NumericAxis(),
                  // A MUDANÇA PRINCIPAL ESTÁ AQUI NA LINHA ABAIXO:
                  series: <CartesianSeries>[
                    BarSeries<ChartData, String>(
                      dataSource: _createChartData('Dividendos'),
                      xValueMapper: (ChartData data, _) => data.xValue,
                      yValueMapper: (ChartData data, _) => data.yValue,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside,
                        textStyle: TextStyle(fontSize: 10),
                      ),
                      width: 0.2,
                      isTrackVisible: true,
                      legendItemText: 'Dividendos',
                    ),
                    BarSeries<ChartData, String>(
                      dataSource: _createChartData('JCP'),
                      xValueMapper: (ChartData data, _) => data.xValue,
                      yValueMapper: (ChartData data, _) => data.yValue,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelPosition: ChartDataLabelPosition.outside,
                        textStyle: TextStyle(fontSize: 10),
                      ),
                      width: 0.2,
                      isTrackVisible: true,
                      legendItemText: 'JCP',
                    ),
                  ],
                  legend: const Legend(
                    isVisible: true,
                    position: LegendPosition.bottom, // Posição da legenda
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String xValue;
  final double yValue;

  ChartData({required this.xValue, required this.yValue});
}

void main() {
  runApp(MaterialApp(
    title: 'Dividend Chart Example',
    home: DividendChart(),
  ));
}




