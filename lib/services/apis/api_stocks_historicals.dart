import 'dart:convert';

import 'package:http/http.dart' as http;

class StocksHistoricals {
  Future<Map<String, dynamic>?> getStockHistoricals(String ticker, int months) async {
    // Primeira tentativa com a API principal
    String apiUrl = "https://mfinance.com.br/api/v1/stocks/historicals/$ticker?months=$months";
    var response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      print('Data received from primary API');
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      print('Failed to load stock historical data from primary API for $ticker, trying secondary API...');

      // Fallback para a API secundária
      apiUrl = "https://mfinance.com.br/api/v1/fiis/historicals/$ticker?months=$months";
      response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        print('Data received from secondary API');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to load stock historical data from secondary API for $ticker');
        return null;  // Retorne null ou lance uma exceção conforme sua lógica de erro
      }
    }
  }
}



