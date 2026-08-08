import 'package:flutter/material.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:flutter_investment_control/pages/news/news_detail_page.dart';

class ActiveDetailsRelatedNews extends StatelessWidget {
  final List<dynamic> newsList;

  const ActiveDetailsRelatedNews({super.key, required this.newsList});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notícias e Fatos Relevantes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 14),
          if (newsList.isEmpty)
            const Text(
              'Nenhuma notícia recente disponível para este ticker.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            )
          else
            Column(
              children: newsList.take(3).map((item) {
                String title = item['title'] ?? 'Fato Relevante B3';
                String publisher = item['publisher']?['name'] ?? 'MFinance / InfoMoney';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.inputDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.newspaper, size: 18, color: AppColors.blueAccent),
                  ),
                  title: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  subtitle: Text(
                    publisher,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewsDetailPage(newsItem: Map<String, dynamic>.from(item)),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
