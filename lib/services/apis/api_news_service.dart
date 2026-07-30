import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:http/http.dart' as http;

/// Service combining BRAPI News and G1 Economia/InfoMoney RSS Feeds
class FinancialNewsService {
  final String _brapiNewsUrl = 'https://brapi.dev/api/news?limit=4';
  final String _g1RssUrl = 'https://api.rss2json.com/v1/api.json?rss_url=https://g1.globo.com/rss/g1/economia/';
  final String _infoMoneyRssUrl = 'https://api.rss2json.com/v1/api.json?rss_url=https://www.infomoney.com.br/feed/';

  final List<String> _fallbackImages = [
    "https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?q=80&w=800&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=800&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?q=80&w=800&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1559526324-4b87b5e36e44?q=80&w=800&auto=format&fit=crop",
  ];

  Future<List<Map<String, dynamic>>> fetchCombinedNews() async {
    List<Map<String, dynamic>> combinedNews = [];

    // 1. Fetch BRAPI News
    try {
      final response = await http.get(Uri.parse(_brapiNewsUrl)).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final newsData = jsonData['news'] as List<dynamic>? ?? [];

        for (int i = 0; i < newsData.length; i++) {
          var item = newsData[i];
          String title = (item['title'] as String?)?.trim() ?? '';
          if (title.isEmpty) continue;

          String imageUrl = (item['imageUrl'] as String?) ?? '';
          if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
            imageUrl = _fallbackImages[i % _fallbackImages.length];
          }

          String sourceStr = (item['source'] as String?) ?? 'Mercado Financeiro';

          combinedNews.add({
            "badge": i % 2 == 0 ? "MACROECONOMIA" : "TECH & IA",
            "badgeColor": i % 2 == 0 ? AppColors.primaryBlue : AppColors.emeraldGreen,
            "source": "$sourceStr • Em alta",
            "title": title,
            "image": imageUrl,
            "url": item['url'] ?? item['link'] ?? '',
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching BRAPI news: $e');
    }

    // 2. Fetch G1 Economia RSS Feed if more news needed
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

            String thumbnail = (item['thumbnail'] as String?) ?? '';
            if (thumbnail.isEmpty || !thumbnail.startsWith('http')) {
              thumbnail = _fallbackImages[(combinedNews.length + i) % _fallbackImages.length];
            }

            combinedNews.add({
              "badge": "ÚLTIMAS NOTÍCIAS",
              "badgeColor": AppColors.fireRed,
              "source": "G1 Economia • Há poucas horas",
              "title": title,
              "image": thumbnail,
              "url": item['link'] ?? '',
            });
          }
        }
      } catch (e) {
        debugPrint('Error fetching G1 Economia RSS: $e');
      }
    }

    // 3. Fetch InfoMoney RSS Feed as secondary fallback
    if (combinedNews.length < 4) {
      try {
        final response = await http.get(Uri.parse(_infoMoneyRssUrl)).timeout(const Duration(seconds: 6));
        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          final items = jsonData['items'] as List<dynamic>? ?? [];

          for (int i = 0; i < items.length && combinedNews.length < 6; i++) {
            var item = items[i];
            String title = (item['title'] as String?)?.trim() ?? '';
            if (title.isEmpty) continue;

            String thumbnail = (item['thumbnail'] as String?) ?? '';
            if (thumbnail.isEmpty) {
              thumbnail = _fallbackImages[i % _fallbackImages.length];
            }

            combinedNews.add({
              "badge": "MERCADO B3",
              "badgeColor": AppColors.primaryBlue,
              "source": "InfoMoney • Mercado ao vivo",
              "title": title,
              "image": thumbnail,
              "url": item['link'] ?? '',
            });
          }
        }
      } catch (e) {
        debugPrint('Error fetching InfoMoney RSS: $e');
      }
    }

    return combinedNews;
  }
}
