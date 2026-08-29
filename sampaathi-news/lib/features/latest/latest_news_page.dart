import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/widgets.dart';
import '../../widgets/app_bottom_nav.dart';

class LatestNewsPage extends ConsumerWidget {
  const LatestNewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestNewsAsync = ref.watch(latestNewsProvider);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return Scaffold(
      appBar: buildAppHeader(context),
      drawer: const MobileDrawer(),
      bottomNavigationBar: isMobile ? const AppBottomNav(currentPath: '/latest') : null,
      body: ResponsiveLayout(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(latestNewsProvider.future),
          child: latestNewsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Center(child: Text('ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ...: $err')),
                ),
              ],
            ),
            data: (articles) {
              if (articles.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: Text('ಯಾವುದೇ ಸುದ್ದಿ ಪ್ರಕಟವಾಗಿಲ್ಲ.')),
                    ),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 12),
                itemCount: articles.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, idx) => _buildRow(context, articles[idx]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, Article article) {
    return InkWell(
      onTap: () => context.go('/article/${article.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SampathiImage(article.featuredImageUrl, width: 100, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article.categories.isNotEmpty)
                  Text(
                    article.categories.first.name,
                    style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
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
                    const Icon(Icons.access_time, size: 11, color: AppTheme.greyColor),
                    const SizedBox(width: 4),
                    Text('${article.readingTime} Min Read', style: const TextStyle(fontSize: 11, color: AppTheme.greyColor)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
