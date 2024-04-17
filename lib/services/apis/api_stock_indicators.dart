import 'dart:convert';

import 'package:http/http.dart' as http;

class StockIndicators {
  Future<Map<String, dynamic>?> getStockIndicators(String ticker) async {
    final String apiUrl = "https://mfinance.com.br/api/v1/stocks/indicators?symbols=$ticker";

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      // print('Data received: ${response.body}');

      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      return jsonData;
    } else {
      throw Exception('Failed to load stock indicators');
    }
  }
}