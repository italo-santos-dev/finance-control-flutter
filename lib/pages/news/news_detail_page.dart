import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_investment_control/core/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

/// Full In-App News Detail Page providing an immersive financial reading experience
class NewsDetailPage extends StatefulWidget {
  final Map<String, dynamic> newsItem;
  final List<Map<String, dynamic>>? allNews;

  const NewsDetailPage({
    Key? key,
    required this.newsItem,
    this.allNews,
  }) : super(key: key);

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  bool isBookmarked = false;
  late Map<String, dynamic> item;

  @override
  void initState() {
    super.initState();
    item = widget.newsItem;
  }

  void _toggleBookmark() {
    setState(() {
      isBookmarked = !isBookmarked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isBookmarked
              ? 'Notícia salva nos seus favoritos!'
              : 'Notícia removida dos favoritos.',
          style: const TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.cardDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyLink() {
    String url = item['url'] ?? 'https://worthy.app/news';
    Clipboard.setData(ClipboardData(text: url));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Link da matéria copiado para a área de transferência!',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  int _calculateReadingTime(String title, String content) {
    int words = (title.split(' ').length) + (content.split(' ').length);
    int minutes = (words / 150).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  List<Map<String, dynamic>> _getRelatedNews() {
    if (widget.allNews == null || widget.allNews!.isEmpty) return [];

    String currentBadge = item['badge'] ?? '';
    String currentTitle = item['title'] ?? '';

    List<Map<String, dynamic>> related = widget.allNews!.where((n) {
      return (n['title'] != currentTitle) && (n['badge'] == currentBadge);
    }).toList();

    if (related.isEmpty) {
      related = widget.allNews!.where((n) => n['title'] != currentTitle).toList();
    }

    return related.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    String title = item['title'] ?? 'Notícia Financeira';
    String source = item['source'] ?? 'Mercado Financeiro';
    String imageUrl = (item['image'] as String?)?.trim() ?? '';
    String badgeText = item['badge'] ?? 'NOTÍCIA';
    Color badgeColor = item['badgeColor'] as Color? ?? AppColors.primaryBlue;
    String rawContent = (item['description'] ?? item['content'] ?? title).toString();
    int readTime = _calculateReadingTime(title, rawContent);
    List<Map<String, dynamic>> relatedNews = _getRelatedNews();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Hero Image Header with Back Button
            SliverAppBar(
              expandedHeight: 320.0,
              pinned: true,
              backgroundColor: AppColors.backgroundDark,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  child: IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? AppColors.emeraldGreen : Colors.white,
                      size: 20,
                    ),
                    onPressed: _toggleBookmark,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                    onPressed: _copyLink,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.cardDark,
                              child: const Center(
                                child: Icon(Icons.newspaper_outlined, size: 60, color: Colors.white24),
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.cardDark,
                            child: const Center(
                              child: Icon(Icons.newspaper_outlined, size: 60, color: Colors.white24),
                            ),
                          ),

                    // Gradient Overlay for Readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.backgroundDark,
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Article Details Body
            SliverToBoxAdapter(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge & Reading Time Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '$readTime min de leitura',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Article Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          height: 1.3,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Source & Date Bar
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardDark,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.avatarDark,
                              radius: 16,
                              child: Icon(Icons.business_center_outlined, size: 16, color: AppColors.blueAccent),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    source,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.white,
                                    ),
                                  ),
                                  Text(
                                    'Publicado em ${DateFormat('dd/MM/yyyy • HH:mm').format(DateTime.now())}',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.content_copy_outlined, size: 18, color: Colors.grey),
                              onPressed: _copyLink,
                              tooltip: 'Copiar link',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Main Article Content
                      _buildArticleParagraphs(rawContent, title),

                      const SizedBox(height: 32),
                      const Divider(color: AppColors.borderDark),
                      const SizedBox(height: 24),

                      // Action Bar (Share & Bookmark)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _copyLink,
                            icon: const Icon(Icons.share_outlined, size: 16),
                            label: const Text('Compartilhar Matéria'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _toggleBookmark,
                            icon: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              size: 16,
                              color: isBookmarked ? AppColors.emeraldGreen : Colors.grey,
                            ),
                            label: Text(
                              isBookmarked ? 'Salvo' : 'Salvar',
                              style: TextStyle(color: isBookmarked ? AppColors.emeraldGreen : Colors.grey),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: isBookmarked ? AppColors.emeraldGreen : AppColors.borderDark),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),

                      // Related News Section
                      if (relatedNews.isNotEmpty) ...[
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            const Icon(Icons.newspaper, color: AppColors.blueAccent, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Notícias Relacionadas',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: relatedNews.map((relItem) {
                            return _buildRelatedNewsTile(relItem);
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds formatted paragraphs strictly from real API payload
  Widget _buildArticleParagraphs(String content, String title) {
    String cleanText = content.trim();
    if (cleanText.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: const Text(
          'Conteúdo adicional indisponível na resposta da fonte oficial no momento.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }

    // Split text into real paragraphs by newlines
    List<String> paragraphs = cleanText
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            paragraph,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[300],
              height: 1.65,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRelatedNewsTile(Map<String, dynamic> relItem) {
    String relImage = (relItem['image'] as String?)?.trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailPage(
                newsItem: relItem,
                allNews: widget.allNews,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 70,
                  height: 70,
                  color: AppColors.avatarDark,
                  child: relImage.isNotEmpty
                      ? Image.network(
                          relImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.newspaper_outlined, size: 24, color: Colors.white24),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.newspaper_outlined, size: 24, color: Colors.white24),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      relItem['badge'] ?? 'NOTÍCIA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: relItem['badgeColor'] as Color? ?? AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      relItem['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      relItem['source'] ?? '',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
