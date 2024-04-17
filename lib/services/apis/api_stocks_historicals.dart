import 'dart:convert';

import 'package:http/http.dart' as http;

class StocksHistoricals {
  Future<Map<String, dynamic>?> getStockHistoricals(String ticker, int months) async {
    final String apiUrl = "https://mfinance.com.br/api/v1/stocks/historicals/$ticker?months=$months";
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      print('Data received: ${response.body}');
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonData;
    } else {
      throw Exception('Failed to load stock historical data');
    }
  }
}


//
//
// import 'dart:convert';
//
// import 'package:http/http.dart' as http;
//
// class StocksHistoricals {
//   Future<Map<String, dynamic>?> getStockHistoricals(String ticker) async {
//     final String apiUrl =
//         "https://mfinance.com.br/api/v1/stocks/historicals/$ticker?months=60";
//
//     final response = await http.get(Uri.parse(apiUrl));
//
//     if (response.statusCode == 200) {
//       print('Data received: ${response.body}');
//
//       final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
//
//       return jsonData;
//     } else {
//       throw Exception('Failed to load stock indicators');
//     }
//   }
// }



