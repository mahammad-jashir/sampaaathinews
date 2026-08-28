import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/widgets.dart';
import '../../utils/seo_helper.dart';

class ArticlePage extends ConsumerStatefulWidget {
  final String articleId;

  const ArticlePage({
    super.key,
    required this.articleId,
  });

  @override
  ConsumerState<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends ConsumerState<ArticlePage> {
  double _textSizeMultiplier = 1.0;
  double _scrollProgress = 0.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.position.pixels;
      setState(() {
        _scrollProgress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(widget.articleId) ?? 0;
    final articleAsync = ref.watch(articleDetailsProvider(id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: buildAppHeader(context),
      drawer: const MobileDrawer(),
      body: ResponsiveLayout(
        child: articleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Center(child: Text('ಸುದ್ದಿ ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿಲ್ಲ...')),
          data: (article) {
            // Trigger dynamic SEO Tags update
            SeoHelper.updateMetadata(
              title: article.title,
              description: article.excerpt,
              url: article.shareUrl,
              imageUrl: article.featuredImageUrl,
              jsonLdSchema: SeoHelper.buildArticleSchema(
                headline: article.title,
                description: article.excerpt,
                url: article.shareUrl,
                datePublished: article.datePublished,
                dateModified: article.dateModified,
                authorName: article.reporter.name,
                authorPhoto: article.reporter.photoUrl,
                imageUrl: article.featuredImageUrl,
              ),
            );

            return Stack(
              children: [
                // Scrollable Content
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      // Reading progress bar
                      Container(
                        height: 4,
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        color: isDark ? Colors.blueGrey[900] : Colors.grey[200],
                        child: FractionallySizedBox(
                          widthFactor: _scrollProgress,
                          child: Container(color: AppTheme.primaryColor),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Article Content
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Category Tags & Text Size adjustment
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (article.categories.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            article.categories.first.name,
                                            style: const TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      Row(
                                        children: [
                                          const Text('ಅಕ್ಷರ ಗಾತ್ರ: ', style: TextStyle(fontSize: 12, color: AppTheme.greyColor)),
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 16),
                                            visualDensity: VisualDensity.compact,
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            onPressed: () {
                                              if (_textSizeMultiplier > 0.8) {
                                                setState(() => _textSizeMultiplier -= 0.1);
                                              }
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 16),
                                            visualDensity: VisualDensity.compact,
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            onPressed: () {
                                              if (_textSizeMultiplier < 1.6) {
                                                setState(() => _textSizeMultiplier += 0.1);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Title
                                  Text(
                                    article.title,
                                    style: TextStyle(
                                      fontSize: 26 * _textSizeMultiplier,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                    ),
                                  ).animate().fade(duration: 300.ms),
                                  const SizedBox(height: 12),

                                  // Subtitle
                                  if (article.subtitle.isNotEmpty)
                                    Text(
                                      article.subtitle,
                                      style: TextStyle(
                                        fontSize: 16 * _textSizeMultiplier,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  const SizedBox(height: 24),

                                  // Reporter / Views Header info
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(article.reporter.photoUrl),
                                        radius: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            article.reporter.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            article.reporter.designation,
                                            style: const TextStyle(color: AppTheme.greyColor, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppTheme.greyColor),
                                          const SizedBox(width: 4),
                                          Text('${article.viewCount} views', style: const TextStyle(fontSize: 12, color: AppTheme.greyColor)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 32),

                                  // High-res Media Banner
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SampathiImage(
                                      article.featuredImageUrl,
                                      width: double.infinity,
                                      height: 400,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Article Content (rendered HTML or standard text fallback)
                                  // For presentation clarity in Flutter Web template, we parse standard HTML tags in a styled text block
                                  _renderHtmlBody(article.content),

                                  const SizedBox(height: 24),
                                  
                                  // In-feed Targeted Advertisement banner
                                  AdBanner(
                                    position: 'article_banner',
                                    categoryId: article.categories.isNotEmpty ? article.categories.first.id : null,
                                    districtId: article.districts.isNotEmpty ? article.districts.first.id : null,
                                  ),

                                  const Divider(height: 48),

                                  // Share triggers
                                  const Text(
                                    'ಈ ಸುದ್ದಿಯನ್ನು ಶೇರ್ ಮಾಡಿ (Share this story)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 12),
                                  SocialShareRow(title: article.title, shareUrl: article.shareUrl),
                                  const SizedBox(height: 48),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            
                            // Related Sidebar column
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ಸಂಬಂಧಿತ ಸುದ್ದಿಗಳು (Related News)',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const Divider(height: 24),
                                  // Simple listing
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final latestNews = ref.watch(latestNewsProvider);
                                      return latestNews.when(
                                        loading: () => const Center(child: CircularProgressIndicator()),
                                        error: (_, __) => const SizedBox(),
                                        data: (articles) {
                                          final filtered = articles.where((a) => a.id != article.id).toList();
                                          return ListView.separated(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: filtered.length.clamp(0, 3),
                                            separatorBuilder: (_, __) => const Divider(height: 16),
                                            itemBuilder: (context, idx) {
                                              final a = filtered[idx];
                                              return InkWell(
                                                onTap: () => context.go('/article/${a.id}'),
                                                child: Row(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(6),
                                                      child: SampathiImage(a.featuredImageUrl, width: 80, height: 60, fit: BoxFit.cover),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        a.title,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Footer(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _renderHtmlBody(String htmlContent) {
    // Custom robust paragraph splitter to render clean paragraphs in Flutter without package complexity
    final cleaned = htmlContent
        .replaceAll('<p>', '')
        .replaceAll('<strong>', '')
        .replaceAll('</strong>', '')
        .split('</p>');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cleaned.where((p) => p.trim().isNotEmpty).map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            p.replaceAll('<b>', '').replaceAll('</b>', ''),
            style: TextStyle(
              fontSize: 16 * _textSizeMultiplier,
              height: 1.6,
            ),
          ),
        );
      }).toList(),
    );
  }
}
