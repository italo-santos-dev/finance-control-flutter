import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiBrapiGetLogo {
  Future<List<Map<String, dynamic>>> fetchLogoUrls() async {
    final apiUrl = 'https://brapi.dev/api/quote/list?token=eJGEyu8vVHctULdVdHYzQd';

    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData != null && jsonData['stocks'] != null && jsonData['stocks'].isNotEmpty) {
          final List<Map<String, dynamic>> logoUrls = [];

          for (var stockData in jsonData['stocks']) {
            final logoUrl = stockData['logo'] != null && stockData['logo'] != ''
                ? stockData['logo'].toString()
                : '';

            final ticker = stockData['stock'] != null ? stockData['stock'].toString() : '';

            if (logoUrl.isNotEmpty && ticker.isNotEmpty) {
              logoUrls.add({
                'ticker': ticker,
                'logoUrl': logoUrl,
              });
            }
          }

          return logoUrls;
        }
      }
    } catch (e) {
      debugPrint('Error fetching BRAPI logos: $e');
    }

    return [];
  }
}
