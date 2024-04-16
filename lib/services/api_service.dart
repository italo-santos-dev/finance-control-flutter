import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, dynamic>?> getAssetDetails(String ticker) async {
    final apiUrl1 = 'https://mfinance.com.br/api/v1/stocks?symbols=$ticker';
    final apiUrl2 = 'https://mfinance.com.br/api/v1/fiis?symbols=$ticker';
    final apiUrl3 = 'https://brapi.dev/api/quote/$ticker?token=m2VDSqSjN5diYAp5VjZSNv';

    try {
      // Tentar obter detalhes do ativo da primeira API

      final response1 = await http.get(Uri.parse(apiUrl1));

      if (response1.statusCode == 200) {
        final jsonData1 = jsonDecode(response1.body);

        if (jsonData1 != null &&
            jsonData1['stocks'] != null &&
            jsonData1['stocks'] is List &&
            jsonData1['stocks'].isNotEmpty) {
          final stockDetails = jsonData1['stocks'][0];
          final assetDetails1 = {
            'currentPrice': stockDetails['lastPrice'] ?? 0.0,
            'name': stockDetails['name'] ?? '',
            'segment': stockDetails['segment'] ?? '',
            'activeType': 'stocks',
            // Adicione outros campos conforme necessário
          };

          return assetDetails1;
        }
      }

      // Se não houver resultados da primeira API, tentar obter da segunda API
      final response2 = await http.get(Uri.parse(apiUrl2));

      if (response2.statusCode == 200) {
        final jsonData2 = jsonDecode(response2.body);

        if (jsonData2 != null &&
            jsonData2['fiis'] != null &&
            jsonData2['fiis'] is List &&
            jsonData2['fiis'].isNotEmpty) {
          final stockDetails = jsonData2['fiis'][0];
          final assetDetails2 = {
            'currentPrice': stockDetails['lastPrice'] ?? 0.0,
            'name': stockDetails['name'] ?? '',
            'segment': stockDetails['segment'] ?? '',
            'activeType': 'fiis',
            // Adicione outros campos conforme necessário
          };

          return assetDetails2;
        }
      }

      final response3= await http.get(Uri.parse(apiUrl3));

      if (response3.statusCode == 200) {
        final jsonData3 = jsonDecode(response3.body);

        if (jsonData3 != null) {
          final assetDetails3 = {
            'currentPrice': jsonData3['results'][0]['regularMarketPrice'] ?? 0.0,
            // Adicione outros campos conforme necessário
          };

          return assetDetails3;
        }
      }

      // Se não houver resultados de ambas as APIs, retornar null
      return null;
    } catch (error) {
      print('Erro ao obter detalhes do ativo: $error');
      // Adicione lógica para lidar com exceções durante a solicitação HTTP
      throw error;
    }
  }
}
