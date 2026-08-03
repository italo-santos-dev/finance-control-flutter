import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StockIbovespaApi {
  final String apiUrl = "https://mfinance.com.br/api/v1/stocks";

  Future<List<dynamic>> fetchStockIndicators() async {
    try {
      var response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData != null && jsonData['stocks'] != null) {
          List<dynamic> stocks = jsonData['stocks'];
          return stocks;
        }
      }
    } catch (e) {
      debugPrint('Error fetching stock indicators: $e');
    }

    return [];
  }
}