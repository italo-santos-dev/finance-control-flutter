import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiBrapiGetLogo {
  Future<List<Map<String, dynamic>>> fetchLogoUrls() async {
    final apiUrl = 'https://brapi.dev/api/quote/list?token=eJGEyu8vVHctULdVdHYzQd';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData != null && jsonData['stocks'] != null && jsonData['stocks'].isNotEmpty) {
        final List<Map<String, dynamic>> logoUrls = [];

        for (var stockData in jsonData['stocks']) {
          final logoUrl = stockData['logo'] != null && stockData['logo'] != '' ? stockData['logo'].toString() : '';

          final ticker = stockData['stock'] != null ? stockData['stock'].toString() : '';

          if (logoUrl.isNotEmpty && ticker.isNotEmpty) {
            logoUrls.add({
              'ticker': ticker,
              'logoUrl': logoUrl,
            });
          }
        }

        print('Data received: ${logoUrls}');


        return logoUrls;
      }
    }

    // Se não houver resultados válidos ou campos necessários estiverem ausentes, retornar uma lista vazia
    return [];
  }
}
