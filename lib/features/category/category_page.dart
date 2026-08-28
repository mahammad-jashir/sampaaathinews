import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/widgets.dart';

class CategoryPage extends ConsumerWidget {
  final String categorySlug;
  final String categoryName;

  const CategoryPage({
    super.key,
    required this.categorySlug,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Find active category ID by slug
    final categoriesAsync = ref.watch(categoriesProvider);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: buildAppHeader(context),
      drawer: const MobileDrawer(),
      body: ResponsiveLayout(
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ...')),
          data: (categories) {
            final category = categories.firstWhere(
              (c) => c.slug == categorySlug,
              orElse: () => Category(id: 2, name: categoryName.isNotEmpty ? categoryName : 'ಸುದ್ದಿ', slug: categorySlug),
            );

            final newsAsync = ref.watch(categoryNewsProvider(category.id));

            final grid = newsAsync.when(
              loading: () => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: isMobile ? 10 : 16,
                  mainAxisSpacing: isMobile ? 10 : 16,
                  childAspectRatio: isMobile ? 0.72 : 1.2,
                ),
                itemCount: 4,
                itemBuilder: (context, idx) => const ShimmerLoadingCard(),
              ),
              error: (err, stack) => const Center(child: Text('ಸುದ್ದಿ ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿಲ್ಲ...')),
              data: (articles) {
                if (articles.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Text('ಈ ವಿಭಾಗದಲ್ಲಿ ಯಾವುದೇ ಸುದ್ದಿಗಳು ಪ್ರಕಟವಾಗಿಲ್ಲ.', style: TextStyle(fontSize: 16)),
                    ),
                  );
                }
                // Mobile gets extra vertical room per card (lower aspect ratio)
                // so the title + date never gets squeezed into overflow —
                // this was the direct cause of the "BOTTOM OVERFLOWED" error.
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: isMobile ? 10 : 20,
                    mainAxisSpacing: isMobile ? 10 : 20,
                    childAspectRatio: isMobile ? 0.72 : 1.1,
                  ),
                  itemCount: articles.length,
                  itemBuilder: (context, idx) {
                    final article = articles[idx];
                    return _buildCategoryItem(context, article);
                  },
                );
              },
            );

            final sidebarAd = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ಪ್ರಾಯೋಜಿತ ಜಾಹೀರಾತು',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.greyColor),
                ),
                const Divider(height: 16),
                AdBanner(position: 'sidebar_banner', categoryId: category.id),
              ],
            );

            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  ref.refresh(categoryNewsProvider(category.id).future),
                  ref.refresh(categoriesProvider.future),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                children: [
                  // Category Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFEFF6FF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${category.name} ವಿಭಾಗದ ಪ್ರಮುಖ ವಿದ್ಯಮಾನಗಳು ಮತ್ತು ಲೇಟೆಸ್ಟ್ ಸುದ್ದಿಗಳು.',
                          style: const TextStyle(fontSize: 14, color: AppTheme.greyColor),
                        ),
                      ],
                    ),
                  ),

                  // Category Advertisement
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AdBanner(position: 'header_banner', categoryId: category.id),
                  ),

                  // Mobile: single column, main content then ad below.
                  // Desktop: side-by-side 7:3 split, unchanged from before.
                  if (isMobile)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          grid,
                          const SizedBox(height: 24),
                          sidebarAd,
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: grid),
                          const SizedBox(width: 32),
                          Expanded(flex: 3, child: sidebarAd),
                        ],
                      ),
                    ),
                  const Footer(),
                ],
              ),
            ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, Article article) {
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
                    Text(
                      'Published on: ${_formatDate(article.datePublished)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.greyColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}-${date.month}-${date.year}';
    } catch (_) {
      return '';
    }
  }
}
