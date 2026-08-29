import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/widgets.dart';
import '../../widgets/app_bottom_nav.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestNewsAsync = ref.watch(latestNewsProvider);
    final breakingNewsAsync = ref.watch(breakingNewsProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: buildAppHeader(context),
      drawer: const MobileDrawer(),
      bottomNavigationBar: isMobile ? const AppBottomNav(currentPath: '/') : null,
      body: ResponsiveLayout(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.refresh(latestNewsProvider.future),
              ref.refresh(breakingNewsProvider.future),
              ref.refresh(categoriesProvider.future),
              ref.refresh(districtsProvider.future),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // needed so pull-to-refresh works even when content is short
            child: isMobile
                ? _buildMobileBody(context, ref, latestNewsAsync, breakingNewsAsync)
                : _buildDesktopBody(context, ref, isDark, latestNewsAsync, breakingNewsAsync, districtsAsync),
          ),
        ),
      ),
    );
  }

  // --- MOBILE LAYOUT (matches the reference design) ---
  Widget _buildMobileBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Article>> latestNewsAsync,
    AsyncValue<List<Article>> breakingNewsAsync,
  ) {
    return Column(
      children: [
        const BreakingNewsTicker(),
        // Stacked, full-bleed ad banners right at the top, edge to edge
        // like the reference (every active ad for this slot, not just one).
        const AdBanner(position: 'header_banner', edgeToEdge: true),

        // Featured article: big image, tag pills over the image, headline +
        // byline row below — matches the big lead story in the reference.
        breakingNewsAsync.when(
          loading: () => const ShimmerLoadingCard(),
          error: (err, stack) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ...'),
          ),
          data: (breakingArticles) {
            if (breakingArticles.isEmpty) return const SizedBox();
            final featured = breakingArticles.first;
            final restOfBreaking = breakingArticles.skip(1).take(4).toList();

            return Column(
              children: [
                _buildMobileFeaturedCard(context, featured),
                // Short list right under the featured headline, exactly like
                // the reference (small thumbnail + byline + read time + bookmark).
                if (restOfBreaking.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: restOfBreaking.map((a) => _buildMobileListRow(context, a)).toList(),
                    ),
                  ),
              ],
            );
          },
        ),

        // Category-grouped sections, each with a "View More Posts" link and
        // a 2-column grid — matches the repeating ಕರಾವಳಿ / ರಾಜ್ಯ sections.
        latestNewsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $err'),
          ),
          data: (articles) => _buildCategorySections(context, articles),
        ),
        const SizedBox(height: 12),
        const Footer(),
      ],
    );
  }

  // Groups the article feed by each article's primary category and renders
  // a "<category name> — View More Posts →" section header followed by a
  // 2-column grid, one section per category (same underlying data/feed,
  // just grouped for display — no new fetches or categories introduced).
  Widget _buildCategorySections(BuildContext context, List<Article> articles) {
    final Map<String, List<Article>> grouped = {};
    for (final article in articles) {
      final categoryName = article.categories.isNotEmpty ? article.categories.first.name : 'ಸುದ್ದಿ';
      grouped.putIfAbsent(categoryName, () => []).add(article);
    }

    final sections = grouped.entries.where((e) => e.value.length >= 2).take(4).toList();

    return Column(
      children: sections.map((entry) {
        final categoryName = entry.key;
        final categoryArticles = entry.value.take(6).toList();
        final categorySlug = categoryArticles.first.categories.isNotEmpty
            ? categoryArticles.first.categories.first.slug
            : '';

        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: () => context.go('/category/$categorySlug?name=$categoryName'),
                      child: Row(
                        children: [
                          Text(
                            'View More Posts',
                            style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                          ),
                          Icon(Icons.arrow_forward, size: 14, color: AppTheme.primaryColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: categoryArticles.length,
                  itemBuilder: (context, idx) => _buildMobileGridCard(context, categoryArticles[idx]),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileFeaturedCard(BuildContext context, Article article) {
    return InkWell(
      onTap: () => context.go('/article/${article.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: SampathiImage(article.featuredImageUrl, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: _tagPillsRow(article),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              article.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.person, size: 12, color: AppTheme.greyColor),
                const SizedBox(width: 4),
                Text(
                  article.reporter.name.isNotEmpty ? article.reporter.name : 'editor',
                  style: const TextStyle(fontSize: 11, color: AppTheme.greyColor),
                ),
                const SizedBox(width: 8),
                Text(
                  '${article.readingTime} Min Read',
                  style: const TextStyle(fontSize: 11, color: AppTheme.greyColor),
                ),
                const Spacer(),
                const Icon(Icons.bookmark_border, size: 16, color: AppTheme.greyColor),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms);
  }

  Widget _buildMobileGridCard(BuildContext context, Article article) {
    return InkWell(
      onTap: () => context.go('/article/${article.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SampathiImage(article.featuredImageUrl, width: double.infinity, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                left: 4,
                bottom: 4,
                child: _tagPillsRow(article, compact: true),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              article.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person, size: 12, color: AppTheme.greyColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${article.readingTime} Min Read',
                  style: const TextStyle(fontSize: 10, color: AppTheme.greyColor),
                ),
              ),
              const Icon(Icons.bookmark_border, size: 14, color: AppTheme.greyColor),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildMobileListRow(BuildContext context, Article article) {
    return InkWell(
      onTap: () => context.go('/article/${article.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SampathiImage(
                article.featuredImageUrl,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _categoryPill(article.categories.isNotEmpty ? article.categories.first.name : 'ಸುದ್ದಿ'),
                  const SizedBox(height: 4),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 12, color: AppTheme.greyColor),
                      const SizedBox(width: 4),
                      Text(
                        article.reporter.name.isNotEmpty ? article.reporter.name : 'editor',
                        style: const TextStyle(fontSize: 11, color: AppTheme.greyColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${article.readingTime} Min Read',
                        style: const TextStyle(fontSize: 11, color: AppTheme.greyColor),
                      ),
                      const Spacer(),
                      const Icon(Icons.bookmark_border, size: 16, color: AppTheme.greyColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Two-tone tag row like the reference: an orange "ಜಸ್ಟ್ ಸುದ್ದಿಗಳು" (Just
  // News/breaking) pill plus a teal category pill. Uses the same article
  // data already available (categories, isBreaking) — no new fields.
  Widget _tagPillsRow(Article article, {bool compact = false}) {
    final categoryName = article.categories.isNotEmpty ? article.categories.first.name : 'ಸುದ್ದಿ';
    return Wrap(
      spacing: compact ? 4 : 6,
      children: [
        _breakingPill(),
        _categoryPill(categoryName),
      ],
    );
  }

  Widget _breakingPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.warningColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'ಜಸ್ಟ್ ಸುದ್ದಿಗಳು',
        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _categoryPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- DESKTOP LAYOUT (unchanged) ---
  Widget _buildDesktopBody(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    AsyncValue<List<Article>> latestNewsAsync,
    AsyncValue<List<Article>> breakingNewsAsync,
    AsyncValue<List<District>> districtsAsync,
  ) {
    return Column(
      children: [
        const BreakingNewsTicker(),
        // Header Advertisement
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: AdBanner(position: 'header_banner'),
        ),

        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- LEFT MAIN GRID COLUMN (70%) ---
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title: Editor's picks
                    _sectionTitle(context, 'ಪ್ರಮುಖ ಸುದ್ದಿಗಳು (Featured News)'),
                    const SizedBox(height: 16),

                    // Hero Slider / Showcase
                    breakingNewsAsync.when(
                      loading: () => const ShimmerLoadingCard(),
                      error: (err, stack) => const Text('ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ...'),
                      data: (articles) {
                        if (articles.isEmpty) return const SizedBox();
                        final heroArticle = articles.first;
                        return _buildHeroShowcase(context, heroArticle);
                      },
                    ),
                    const SizedBox(height: 32),

                    // District Filters Chips Section
                    _sectionTitle(context, 'ಜಿಲ್ಲಾವಾರು ಸುದ್ದಿಗಳು (District News)'),
                    const SizedBox(height: 12),
                    districtsAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (districts) {
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: districts.map((d) {
                            return ActionChip(
                              label: Text(d.name),
                              onPressed: () => context.go('/district/${d.slug}?name=${d.name}'),
                              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Latest Stories Grid
                    _sectionTitle(context, 'ತಾಜಾ ಸುದ್ದಿಗಳು (Latest News)'),
                    const SizedBox(height: 16),
                    latestNewsAsync.when(
                      loading: () => GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, idx) => const ShimmerLoadingCard(),
                      ),
                      error: (err, stack) => Text('Error: $err'),
                      data: (articles) {
                        final gridArticles = articles.skip(1).toList();
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: gridArticles.length,
                          itemBuilder: (context, idx) {
                            final article = gridArticles[idx];
                            return _buildGridCard(context, article);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),

              // --- RIGHT SIDEBAR COLUMN (30%) ---
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'ಜಾಹೀರಾತು (Advertisement)'),
                    const AdBanner(position: 'sidebar_banner'),
                    const SizedBox(height: 32),

                    _sectionTitle(context, 'ಟ್ರೆಂಡಿಂಗ್ ಸುದ್ದಿಗಳು (Trending Stories)'),
                    const SizedBox(height: 16),
                    latestNewsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox(),
                      data: (articles) {
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: articles.length,
                          separatorBuilder: (context, index) => const Divider(height: 24),
                          itemBuilder: (context, index) {
                            final article = articles[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              title: Text(
                                article.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () => context.go('/article/${article.id}'),
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
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 48,
          height: 3,
          color: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildHeroShowcase(BuildContext context, Article article) {
    return InkWell(
      onTap: () => context.go('/article/${article.id}'),
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(article.featuredImageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ಪ್ರಮುಖ ಸುದ್ದಿ',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[200],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 500.ms).scale(begin: const Offset(0.98, 0.98));
  }

  Widget _buildGridCard(BuildContext context, Article article) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: () => context.go('/article/${article.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: SampathiImage(
                article.featuredImageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          article.reporter.name,
                          style: const TextStyle(fontSize: 11, color: AppTheme.greyColor),
                        ),
                        Text(
                          '${article.readingTime} min read',
                          style: const TextStyle(fontSize: 11, color: AppTheme.greyColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms);
  }
}
