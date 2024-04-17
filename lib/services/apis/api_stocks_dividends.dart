import 'dart:convert';

import 'package:http/http.dart' as http;

class StockDividends {
  Future<List<Map<String, dynamic>>> getStockDividends(String ticker) async {
    final String apiUrl = "https://mfinance.com.br/api/v1/stocks/dividends/$ticker";

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
