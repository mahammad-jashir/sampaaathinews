import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/widgets.dart';

class DistrictPage extends ConsumerWidget {
  final String districtSlug;
  final String districtName;

  const DistrictPage({
    super.key,
    required this.districtSlug,
    required this.districtName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final districtsAsync = ref.watch(districtsProvider);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: buildAppHeader(context),
      drawer: const MobileDrawer(),
      body: ResponsiveLayout(
        child: districtsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ...')),
          data: (districts) {
            final district = districts.firstWhere(
              (d) => d.slug == districtSlug,
              orElse: () => District(id: 101, name: districtName.isNotEmpty ? districtName : 'ಜಿಲ್ಲೆ ಸುದ್ದಿ', slug: districtSlug),
            );

            final newsAsync = ref.watch(districtNewsProvider(district.id));

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
                itemCount: 2,
                itemBuilder: (context, idx) => const ShimmerLoadingCard(),
              ),
              error: (err, stack) => const Center(child: Text('ಸುದ್ದಿ ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿಲ್ಲ...')),
              data: (articles) {
                if (articles.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Text('ಈ ಜಿಲ್ಲೆಯಲ್ಲಿ ಸದ್ಯಕ್ಕೆ ಯಾವುದೇ ಹೊಸ ಸುದ್ದಿಗಳು ವರದಿಯಾಗಿಲ್ಲ.', style: TextStyle(fontSize: 16)),
                    ),
                  );
                }
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
                    return _buildDistrictItem(context, article);
                  },
                );
              },
            );

            final sidebarAd = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ಸ್ಥಳೀಯ ಜಾಹೀರಾತು',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.greyColor),
                ),
                const Divider(height: 16),
                AdBanner(position: 'sidebar_banner', districtId: district.id),
              ],
            );

            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  ref.refresh(districtNewsProvider(district.id).future),
                  ref.refresh(districtsProvider.future),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                children: [
                  // District Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFEFF6FF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              '${district.name} ಸುದ್ದಿ',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${district.name} ಜಿಲ್ಲೆಯ ಸ್ಥಳೀಯ ಸುದ್ದಿ ವರದಿಗಳು, ವಿದ್ಯಮಾನಗಳು ಮತ್ತು ಲೈವ್ ಅಪ್ಡೇಟ್ಸ್.',
                          style: const TextStyle(fontSize: 14, color: AppTheme.greyColor),
                        ),
                      ],
                    ),
                  ),

                  // District Targeted Banner Ad
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AdBanner(position: 'header_banner', districtId: district.id),
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

  Widget _buildDistrictItem(BuildContext context, Article article) {
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
                      'ವರದಿಗಾರರು: ${article.reporter.name}',
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
}
