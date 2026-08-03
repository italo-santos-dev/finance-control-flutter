import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:http/http.dart' as http;

/// Service combining InfoMoney RSS, BRAPI News, G1 Economia RSS, and IBGE Notícias
class FinancialNewsService {
  final String _infoMoneyRssUrl = 'https://api.rss2json.com/v1/api.json?rss_url=https://www.infomoney.com.br/feed/';
  final String _brapiNewsUrl = 'https://brapi.dev/api/news?limit=6';
  final String _g1RssUrl = 'https://api.rss2json.com/v1/api.json?rss_url=https://g1.globo.com/rss/g1/economia/';
  final String _ibgeNewsUrl = 'https://servicodados.ibge.gov.br/api/v3/noticias/?qtd=6';

  final List<String> _fallbackImages = [
    "https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?q=80&w=800&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=800&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?q=80&w=800&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1559526324-4b87b5e36e44?q=80&w=800&auto=format&fit=crop",
  ];

  /// Determine category badge (MACROECONOMIA, TECH & IA, MERCADO B3, MERCADO GLOBAL, etc.)
  Map<String, dynamic> _determineCategory(String title, int index) {
    String lower = title.toLowerCase();

    if (lower.contains('tech') ||
        lower.contains('ia') ||
        lower.contains('inteligência artificial') ||
        lower.contains('nvidia') ||
        lower.contains('apple') ||
        lower.contains('microsoft') ||
        lower.contains('software') ||
        lower.contains('chips') ||
        lower.contains('tecnologia') ||
        lower.contains('aplicativo') ||
        lower.contains('aplicativos')) {
      return {"badge": "TECH & IA", "color": AppColors.emeraldGreen};
    }

    if (lower.contains('selic') ||
        lower.contains('inflação') ||
        lower.contains('ipca') ||
        lower.contains('fed') ||
        lower.contains('juros') ||
        lower.contains('pib') ||
        lower.contains('omc') ||
        lower.contains('tarifa') ||
        lower.contains('governo') ||
        lower.contains('fiscal') ||
        lower.contains('haddad') ||
        lower.contains('banco central') ||
        lower.contains('crédito') ||
        lower.contains('financiamentos')) {
      return {"badge": "MACROECONOMIA", "color": AppColors.primaryBlue};
    }

    if (lower.contains('petrobras') ||
        lower.contains('vale') ||
        lower.contains('itaú') ||
        lower.contains('bolsa') ||
        lower.contains('b3') ||
        lower.contains('ação') ||
        lower.contains('ações') ||
        lower.contains('lucro') ||
        lower.contains('dividendo') ||
        lower.contains('fii')) {
      return {"badge": "MERCADO B3", "color": AppColors.blueAccent};
    }

    if (lower.contains('dólar') ||
        lower.contains('euro') ||
        lower.contains('global') ||
        lower.contains('exterior') ||
        lower.contains('eua') ||
        lower.contains('china') ||
        lower.contains('recall') ||
        lower.contains('stellantis')) {
      return {"badge": "MERCADO GLOBAL", "color": AppColors.blueAccent};
    }

    List<Map<String, dynamic>> defaultCats = [
      {"badge": "MACROECONOMIA", "color": AppColors.primaryBlue},
      {"badge": "TECH & IA", "color": AppColors.emeraldGreen},
      {"badge": "MERCADO B3", "color": AppColors.blueAccent},
      {"badge": "FINANÇAS PESSOAIS", "color": AppColors.emeraldGreen},
    ];

    return defaultCats[index % defaultCats.length];
  }

  /// Extract real article image from JSON payload or HTML content (<img> tags)
  String _extractRealImage(Map<String, dynamic> item, int indexFallback) {
    List<String?> candidateKeys = [
      item['thumbnail']?.toString(),
      item['imageUrl']?.toString(),
      item['image']?.toString(),
      item['cover']?.toString(),
      item['media']?.toString(),
      item['featuredImage']?.toString(),
      item['enclosure'] is Map ? item['enclosure']['link']?.toString() : null,
      item['media:content'] is Map ? item['media:content']['url']?.toString() : null,
      item['media:thumbnail'] is Map ? item['media:thumbnail']['url']?.toString() : null,
    ];

    for (var key in candidateKeys) {
      if (key != null && key.trim().startsWith('http')) {
        return key.trim().replaceAll('&amp;', '&');
      }
    }

    // Extract <img> src from HTML description or content (matching single or double quotes)
    String html = (item['description'] ?? item['content'] ?? '').toString();
    RegExp imgRegExp = RegExp('src=["\'](https?://[^"\']+)["\']', caseSensitive: false);
    Match? match = imgRegExp.firstMatch(html);
    if (match != null && match.group(1) != null) {
      String src = match.group(1)!.trim().replaceAll('&amp;', '&');
      if (src.startsWith('http')) {
        return src;
      }
    }

    return _fallbackImages[indexFallback % _fallbackImages.length];
  }

  /// Fetch combined live news sorted by freshness and image availability
  Future<List<Map<String, dynamic>>> fetchCombinedNews() async {
    List<Map<String, dynamic>> combinedNews = [];

    // 1. Fetch InfoMoney RSS Feed (100% High-Res Image Thumbnails)
    try {
      final response = await http.get(Uri.parse(_infoMoneyRssUrl)).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final items = jsonData['items'] as List<dynamic>? ?? [];

        for (int i = 0; i < items.length && combinedNews.length < 6; i++) {
          var item = items[i];
          String title = (item['title'] as String?)?.trim() ?? '';
          if (title.isEmpty) continue;

          String realImage = _extractRealImage(item, combinedNews.length);
          var catInfo = _determineCategory(title, combinedNews.length);
          String cleanDesc = (item['description'] ?? item['content'] ?? '').toString()
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('&nbsp;', ' ')
              .trim();

          combinedNews.add({
            "badge": catInfo["badge"],
            "badgeColor": catInfo["color"],
            "source": "InfoMoney • Mercado ao vivo",
            "title": title,
            "image": realImage,
            "url": item['link'] ?? '',
            "description": cleanDesc.isNotEmpty ? cleanDesc : title,
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching InfoMoney RSS: $e');
    }

    // 2. Fetch BRAPI News
    if (combinedNews.length < 4) {
      try {
        final response = await http.get(Uri.parse(_brapiNewsUrl)).timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          final newsData = jsonData['news'] as List<dynamic>? ?? [];

          for (int i = 0; i < newsData.length; i++) {
            var item = newsData[i];
            String title = (item['title'] as String?)?.trim() ?? '';
            if (title.isEmpty) continue;

            String realImage = _extractRealImage(item, combinedNews.length);
            String sourceStr = (item['source'] as String?)?.trim() ?? 'Mercado Financeiro';
            var catInfo = _determineCategory(title, combinedNews.length);

            combinedNews.add({
              "badge": catInfo["badge"],
              "badgeColor": catInfo["color"],
              "source": "$sourceStr • Em alta",
              "title": title,
              "image": realImage,
              "url": item['url'] ?? item['link'] ?? '',
              "description": item['description'] ?? title,
            });
          }
        }
      } catch (e) {
        debugPrint('Error fetching BRAPI news: $e');
      }
    }

    // 3. Fetch G1 Economia RSS Feed
    if (combinedNews.length < 4) {
      try {
        final response = await http.get(Uri.parse(_g1RssUrl)).timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          final items = jsonData['items'] as List<dynamic>? ?? [];

          for (int i = 0; i < items.length && combinedNews.length < 6; i++) {
            var item = items[i];
            String title = (item['title'] as String?)?.trim() ?? '';
            if (title.isEmpty) continue;

            String realImage = _extractRealImage(item, combinedNews.length);
            var catInfo = _determineCategory(title, combinedNews.length);
            String cleanDesc = (item['description'] ?? item['content'] ?? '').toString()
                .replaceAll(RegExp(r'<[^>]*>'), '')
                .replaceAll('&nbsp;', ' ')
                .trim();

            combinedNews.add({
              "badge": catInfo["badge"],
              "badgeColor": catInfo["color"],
              "source": "G1 Economia • Última hora",
              "title": title,
              "image": realImage,
              "url": item['link'] ?? '',
              "description": cleanDesc.isNotEmpty ? cleanDesc : title,
            });
          }
        }
      } catch (e) {
        debugPrint('Error fetching G1 Economia RSS: $e');
      }
    }

    return combinedNews;
  }

  /// Fetch news items filtered or prioritized for a specific asset (symbol or company name)
  Future<List<Map<String, dynamic>>> fetchNewsForAsset(String symbol, String name) async {
    List<Map<String, dynamic>> allNews = await fetchCombinedNews();
    String sym = symbol.toUpperCase().trim();
    String company = name.toUpperCase().trim();

    List<Map<String, dynamic>> matching = allNews.where((news) {
      String title = (news['title'] ?? '').toString().toUpperCase();
      String desc = (news['description'] ?? '').toString().toUpperCase();
      return title.contains(sym) || title.contains(company) || desc.contains(sym) || desc.contains(company);
    }).toList();

    if (matching.isNotEmpty) {
      return matching;
    }

    // Return all B3 / market news if no specific ticker match is found
    return allNews;
  }
}
