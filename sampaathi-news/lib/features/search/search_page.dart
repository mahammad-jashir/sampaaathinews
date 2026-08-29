import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../themes/app_theme.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/widgets.dart';

class SearchPage extends ConsumerStatefulWidget {
  final String initialQuery;

  const SearchPage({
    super.key,
    required this.initialQuery,
  });

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late TextEditingController _searchController;
  int? _selectedCategoryId;
  int? _selectedDistrictId;

  @override
  void initState() {
    _searchController = TextEditingController(text: widget.initialQuery);
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchResultsList(List<Article> articles, bool isMobile) {
    if (articles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('ಯಾವುದೇ ಫಲಿತಾಂಶಗಳು ಕಂಡುಬಂದಿಲ್ಲ.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: articles.length,
      separatorBuilder: (_, __) => const Divider(height: 24),
      itemBuilder: (context, idx) {
        final article = articles[idx];
        return InkWell(
          onTap: () => context.go('/article/${article.id}'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SampathiImage(
                  article.featuredImageUrl,
                  width: isMobile ? 100 : 160,
                  height: isMobile ? 80 : 120,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(height: 8),
                      Text(
                        article.excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppTheme.greyColor),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          article.reporter.name.isNotEmpty ? article.reporter.name : 'editor',
                          style: const TextStyle(fontSize: 11, color: AppTheme.greyColor),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${article.readingTime} min read',
                          style: const TextStyle(fontSize: 11, color: AppTheme.greyColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    
    final searchParams = SearchParams(
      query: _searchController.text,
      categoryId: _selectedCategoryId,
      districtId: _selectedDistrictId,
    );
    final searchResultsAsync = ref.watch(searchProvider(searchParams));

    return Scaffold(
      appBar: buildAppHeader(context),
      drawer: const MobileDrawer(),
      body: ResponsiveLayout(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Search Header Form
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFEFF6FF),
                child: Column(
                  children: [
                    // Search Bar
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (val) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                          hintText: 'ಸುದ್ದಿ ಶೀರ್ಷಿಕೆ ಅಥವಾ ಪದಗಳನ್ನು ಹುಡುಕಿ...',
                          hintStyle: const TextStyle(fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Filter Chips Bar
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        // Category Dropdown Filter
                        categoriesAsync.when(
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                          data: (categories) {
                            return DropdownButton<int?>(
                              value: _selectedCategoryId,
                              hint: const Text('ಎಲ್ಲಾ ವಿಭಾಗಗಳು (All Categories)', style: TextStyle(fontSize: 12)),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('ಎಲ್ಲಾ ವಿಭಾಗಗಳು', style: TextStyle(fontSize: 12)),
                                ),
                                ...categories.map((c) {
                                  return DropdownMenuItem<int?>(
                                    value: c.id,
                                    child: Text(c.name, style: const TextStyle(fontSize: 12)),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedCategoryId = val);
                              },
                            );
                          },
                        ),
                        
                        // District Dropdown Filter
                        districtsAsync.when(
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                          data: (districts) {
                            return DropdownButton<int?>(
                              value: _selectedDistrictId,
                              hint: const Text('ಎಲ್ಲಾ ಜಿಲ್ಲೆಗಳು (All Districts)', style: TextStyle(fontSize: 12)),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('ಎಲ್ಲಾ ಜಿಲ್ಲೆಗಳು', style: TextStyle(fontSize: 12)),
                                ),
                                ...districts.map((d) {
                                  return DropdownMenuItem<int?>(
                                    value: d.id,
                                    child: Text(d.name, style: const TextStyle(fontSize: 12)),
                                  );
                                }),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedDistrictId = val);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search results list
              Padding(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ಹುಡುಕಾಟದ ಫಲಿತಾಂಶಗಳು (${_searchController.text.isNotEmpty ? '"${_searchController.text}"' : 'ಎಲ್ಲಾ ಸುದ್ದಿಗಳು'})',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Divider(height: 24),
                          searchResultsAsync.when(
                            loading: () => const ShimmerLoadingCard(),
                            error: (err, stack) => const Text('ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ...'),
                            data: (articles) => _buildSearchResultsList(articles, isMobile),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'ಪ್ರಾಯೋಜಿತ ಜಾಹೀರಾತು',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.greyColor),
                          ),
                          const Divider(height: 16),
                          AdBanner(
                            position: 'sidebar_banner',
                            categoryId: _selectedCategoryId,
                            districtId: _selectedDistrictId,
                          ),
                          const SizedBox(height: 16),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ಹುಡುಕಾಟದ ಫಲಿತಾಂಶಗಳು (${_searchController.text.isNotEmpty ? '"${_searchController.text}"' : 'ಎಲ್ಲಾ ಸುದ್ದಿಗಳು'})',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const Divider(height: 32),
                                searchResultsAsync.when(
                                  loading: () => const ShimmerLoadingCard(),
                                  error: (err, stack) => const Text('ಲೋಡ್ ಮಾಡಲು ಸಾಧ್ಯವಾಗುತ್ತಿಲ್ಲ...'),
                                  data: (articles) => _buildSearchResultsList(articles, isMobile),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                const Text(
                                  'ಪ್ರಾಯೋಜಿತ ಜಾಹೀರಾತು',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.greyColor),
                                ),
                                const Divider(height: 16),
                                AdBanner(
                                  position: 'sidebar_banner',
                                  categoryId: _selectedCategoryId,
                                  districtId: _selectedDistrictId,
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
      ),
    );
  }
}
