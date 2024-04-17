import 'dart:convert';
import 'package:http/http.dart' as http;

class StockIbovespaApi {
  // final String apiUrl = "https://mfinance.com.br/api/v1/stocks/indicators";
  final String apiUrl = "https://mfinance.com.br/api/v1/stocks";

  Future<List<dynamic>> fetchStockIndicators() async {
    var response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      // Print para mostrar os dados recebidos quando o status code for 200
      print('Data received: ${response.body}');

      // If the call to the server was successful, parse the JSON
      var jsonData = json.decode(response.body);
      var indicators = jsonData['stocks'];
      return indicators;
    } else {
      // If that call was not successful, throw an error.
      throw Exception('Failed to load stock indicators');
    }
  }
}