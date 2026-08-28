import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:universal_html/html.dart' as html;
import 'package:responsive_framework/responsive_framework.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../themes/app_theme.dart';
import '../services/api_client.dart';

// --- MOBILE DRAWER (hamburger menu) ---
// Relocates every function that doesn't fit in the compact mobile header
// (categories, districts, theme toggle, language, admin) into a drawer.
// Nothing here is new functionality — it's the same actions as the
// desktop header, just moved for the mobile layout.
class MobileDrawer extends ConsumerWidget {
  const MobileDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final districtsAsync = ref.watch(districtsProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final isAdminLoggedIn = ref.watch(adminAuthProvider);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: AppTheme.primaryColor,
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Text(
                      'ಸಂಪಾತಿ ನ್ಯೂಸ್',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('ವಿಭಾಗಗಳು (Categories)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.greyColor)),
            ),
            categoriesAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
              error: (_, __) => const SizedBox(),
              data: (categories) => Column(
                children: categories.map((cat) {
                  return ListTile(
                    title: Text(cat.name),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/category/${cat.slug}?name=${cat.name}');
                    },
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('ಜಿಲ್ಲೆಗಳು (Districts)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.greyColor)),
            ),
            districtsAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
              error: (_, __) => const SizedBox(),
              data: (districts) => Column(
                children: districts.map((d) {
                  return ListTile(
                    title: Text(d.name),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/district/${d.slug}?name=${d.name}');
                    },
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              title: Text(isDark ? 'ಲೈಟ್ ಮೋಡ್ (Light Mode)' : 'ಡಾರ್ಕ್ ಮೋಡ್ (Dark Mode)'),
              onTap: () => themeNotifier.toggleTheme(),
            ),
            const ListTile(
              leading: Icon(Icons.language),
              title: Text('ಕನ್ನಡ (Kannada)'),
            ),
            const Divider(),
            if (isAdminLoggedIn) ...[
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Publish News'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/admin/publish');
                },
              ),
              ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: const Text('Publish Advertisement'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/admin/publish-ad');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.errorColor),
                title: const Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(adminAuthProvider.notifier).logout();
                },
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Admin Login'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/admin');
                },
              ),
          ],
        ),
      ),
    );
  }
}

// --- SHARED APP HEADER HELPER ---
// GlassHeader's own preferredSize can't see BuildContext (needed to know
// mobile vs desktop), so each page wraps it with this helper instead, which
// picks the right height before Scaffold lays out the AppBar slot.
PreferredSizeWidget buildAppHeader(BuildContext context) {
  final isMobile = ResponsiveBreakpoints.of(context).isMobile;
  return PreferredSize(
    preferredSize: Size.fromHeight(isMobile ? 56 : 126),
    child: const GlassHeader(),
  );
}

// --- WEATHER WIDGET ---
class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.blueGrey.withOpacity(0.2) : Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wb_sunny_rounded, size: 14, color: AppTheme.warningColor),
          const SizedBox(width: 4),
          Text(
            'ಬೆಂಗಳೂರು: 24°C',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

// --- BREAKING NEWS TICKER ---
class BreakingNewsTicker extends ConsumerWidget {
  const BreakingNewsTicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakingNewsAsync = ref.watch(breakingNewsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 36,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: double.infinity,
            color: AppTheme.errorColor,
            alignment: Alignment.center,
            child: const Text(
              'ಪ್ರಮುಖ ಸುದ್ದಿ',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ).animate().fade(duration: 300.ms).slideX(begin: -0.2),
          Expanded(
            child: breakingNewsAsync.when(
              loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              error: (err, stack) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('ಸುದ್ದಿ ಲೋಡ್ ಮಾಡಲಾಗುತ್ತಿಲ್ಲ...', style: TextStyle(fontSize: 12)),
              ),
              data: (articles) {
                if (articles.isEmpty) return const SizedBox();
                final text = articles.map((a) => a.title).join('  |  ');
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[200] : Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .moveX(begin: 800, end: -1400, duration: 25.seconds),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- GLASS HEADER / APP BAR ---
class GlassHeader extends ConsumerWidget implements PreferredSizeWidget {
  const GlassHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(126);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoriesProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final searchController = TextEditingController();
    final isAdminLoggedIn = ref.watch(adminAuthProvider);

    // Compact style so the admin buttons don't blow past the header's fixed
    // height with their default (touch-friendly but tall) tap targets.
    final compactButtonStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    if (isMobile) {
      return Container(
        color: AppTheme.primaryColor,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.go('/'),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 32,
                        fit: BoxFit.contain,
                        color: Colors.white,
                        errorBuilder: (context, error, stackTrace) => const Text(
                          'ಸಂಪಾತಿ ನ್ಯೂಸ್',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.wb_sunny_outlined, color: Colors.white),
                  tooltip: 'ಬೆಂಗಳೂರು: 24°C',
                  onPressed: () => themeNotifier.toggleTheme(),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () => context.go('/search'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Top Ticker / Weather Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const WeatherWidget(),
              Row(
                children: [
                  if (isAdminLoggedIn) ...[
                    TextButton.icon(
                      style: compactButtonStyle,
                      onPressed: () => context.go('/admin/publish'),
                      icon: const Icon(Icons.edit_note, size: 16),
                      label: const Text('Publish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(
                      style: compactButtonStyle,
                      onPressed: () async {
                        await ref.read(adminAuthProvider.notifier).logout();
                      },
                      icon: const Icon(Icons.logout, size: 14, color: AppTheme.errorColor),
                      label: const Text('Logout', style: TextStyle(fontSize: 12, color: AppTheme.errorColor)),
                    ),
                  ] else
                    TextButton.icon(
                      style: compactButtonStyle,
                      onPressed: () => context.go('/admin'),
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                      label: const Text('Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  IconButton(
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18),
                    onPressed: () => themeNotifier.toggleTheme(),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: compactButtonStyle,
                    onPressed: () {},
                    icon: const Icon(Icons.language, size: 14),
                    label: const Text('ಕನ್ನಡ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        // Main Navbar
        Container(
          height: 90,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                offset: const Offset(0, 4),
                blurRadius: 10,
              )
            ],
          ),
          child: Row(
            children: [
              // Logo
              GestureDetector(
                onTap: () => context.go('/'),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'ಸಂಪಾತಿ ನ್ಯೂಸ್',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 32),
              // Category Navigation (Desktop)
              Expanded(
                child: categoriesAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                  data: (categories) {
                    return SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Center(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => context.go('/category/${cat.slug}?name=${cat.name}'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              // Search Input
              Container(
                width: 220,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextField(
                  controller: searchController,
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      context.go('/search?q=${Uri.encodeComponent(val)}');
                    }
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
                    hintText: 'ಹುಡುಕಿ...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- FOOTER ---
class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo/About
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'ಸಂಪಾತಿ ನ್ಯೂಸ್',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ಕರ್ನಾಟಕದ ಅತ್ಯಂತ ವಿಶ್ವಾಸಾರ್ಹ ಡಿಜಿಟಲ್ ಸುದ್ದಿ ಮಾಧ್ಯಮ. ನಿಖರ ಮಾಹಿತಿ ಮತ್ತು ಕ್ಷಿಪ್ರ ಸುದ್ದಿಗಳಿಗಾಗಿ ನಮ್ಮನ್ನು ಫಾಲೋ ಮಾಡಿ.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => html.window.open('https://www.instagram.com/sampaathi_news?igsh=Ynpvanc1ODZwNXB5', '_blank'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.pink.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Row(
                              children: [
                                Text('📸 ', style: TextStyle(fontSize: 12)),
                                Text(
                                  'Instagram',
                                  style: TextStyle(color: Colors.pinkAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () => html.window.open('https://www.facebook.com/sampaathinews', '_blank'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Row(
                              children: [
                                Text('📘 ', style: TextStyle(fontSize: 12)),
                                Text(
                                  'Facebook',
                                  style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              // Quick Links
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ವಿಭಾಗಗಳು',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    _footerLink('ಕರ್ನಾಟಕ'),
                    _footerLink('ಬೆಂಗಳೂರು'),
                    _footerLink('ರಾಜಕೀಯ'),
                    _footerLink('ಕ್ರೀಡೆ'),
                  ],
                ),
              ),
              // Contact / Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ಮಾಹಿತಿ',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    _footerLink('ನಮ್ಮ ಬಗ್ಗೆ'),
                    _footerLink('ಜಾಹೀರಾತು ಪ್ರಕಟಿಸಿ'),
                    _footerLink('ಗೌಪ್ಯತೆ ನೀತಿ'),
                    _footerLink('ಸಂಪರ್ಕಿಸಿ'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: Colors.grey, thickness: 0.2),
          const SizedBox(height: 16),
          Text(
            '© ${DateTime.now().year} ಸಂಪಾತಿ ನ್ಯೂಸ್. All rights reserved. Developed by Framesy.',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          text,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }
}

// --- ADVERTISEMENT BANNER WIDGET ---
class AdBanner extends ConsumerStatefulWidget {
  final String position;
  final int? categoryId;
  final int? districtId;
  // When true, renders full-bleed (no side margin, no rounded corners/border)
  // and stacks every active ad for this slot instead of just the top one —
  // matches the reference design's multiple stacked banners near the top.
  final bool edgeToEdge;

  const AdBanner({
    super.key,
    required this.position,
    this.categoryId,
    this.districtId,
    this.edgeToEdge = false,
  });

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  final Set<int> _loggedImpressions = {};

  @override
  Widget build(BuildContext context) {
    final query = AdQuery(
      position: widget.position,
      categoryId: widget.categoryId,
      districtId: widget.districtId,
    );
    final adsAsync = ref.watch(advertisementsProvider(query));

    return adsAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (ads) {
        if (ads.isEmpty) return const SizedBox();

        // Edge-to-edge mode stacks every active ad for this slot (matching
        // the reference's multiple banners); the default mode shows just
        // the single highest-priority ad, as before.
        final adsToShow = widget.edgeToEdge ? ads : [ads.first];

        return Column(
          children: adsToShow.map((ad) => _singleAdWidget(ad)).toList(),
        );
      },
    );
  }

  Widget _singleAdWidget(Advertisement ad) {
    if (!_loggedImpressions.contains(ad.id)) {
      _loggedImpressions.add(ad.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adRepositoryProvider).logImpression(ad.id);
      });
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ref.read(adRepositoryProvider).logClick(ad.id);
          if (ad.landingUrl.isNotEmpty) {
            html.window.open(ad.landingUrl, '_blank');
          }
        },
        child: Container(
          margin: widget.edgeToEdge ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 16),
          width: double.infinity,
          decoration: widget.edgeToEdge
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
          clipBehavior: widget.edgeToEdge ? Clip.none : Clip.antiAlias,
          child: Stack(
            children: [
              // A fixed, banner-like aspect ratio keeps every ad the same
              // clean shape regardless of the uploaded image's own
              // dimensions — avoids the "sometimes tall, sometimes short"
              // look from letting fitWidth set the height freely.
              AspectRatio(
                aspectRatio: 3.4,
                child: SampathiImage(
                  ad.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ಜಾಹೀರಾತು (Ad)',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Expand icon: shows the original image full-screen with
              // pinch-to-zoom. Nested inside the outer GestureDetector, so
              // tapping it does NOT also trigger the click-through above.
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showFullImage(ad.imageUrl),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fade(duration: 400.ms);
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: SampathiImage(imageUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SHIMMER LOADER ---
class ShimmerLoadingCard extends StatelessWidget {
  const ShimmerLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1E293B) : Colors.grey[200]!;
    final highlightColor = isDark ? const Color(0xFF334155) : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 20,
            width: 140,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Container(
            height: 24,
            width: double.infinity,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

// --- SOCIAL SHARE ROW ---
class SocialShareRow extends StatelessWidget {
  final String title;
  final String shareUrl;

  const SocialShareRow({
    super.key,
    required this.title,
    required this.shareUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _shareIcon(
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF25D366), // WhatsApp Green
          tooltip: 'WhatsApp ಹಂಚಿಕೊಳ್ಳಿ',
          onPressed: () => _openUrl('https://api.whatsapp.com/send?text=${Uri.encodeComponent('$title\n$shareUrl')}'),
        ),
        const SizedBox(width: 12),
        _shareIcon(
          icon: Icons.send_rounded,
          color: const Color(0xFF0088cc), // Telegram Blue
          tooltip: 'Telegram ಹಂಚಿಕೊಳ್ಳಿ',
          onPressed: () => _openUrl('https://t.me/share/url?url=${Uri.encodeComponent(shareUrl)}&text=${Uri.encodeComponent(title)}'),
        ),
        const SizedBox(width: 12),
        _shareIcon(
          icon: Icons.close_fullscreen_outlined,
          color: Colors.black, // X Logo Black
          tooltip: 'X ಹಂಚಿಕೊಳ್ಳಿ',
          onPressed: () => _openUrl('https://twitter.com/intent/tweet?url=${Uri.encodeComponent(shareUrl)}&text=${Uri.encodeComponent(title)}'),
        ),
        const SizedBox(width: 12),
        _shareIcon(
          icon: Icons.link_rounded,
          color: AppTheme.greyColor,
          tooltip: 'ಲಿಂಕ್ ಕಾಪಿ ಮಾಡಿ',
          onPressed: () {
            html.window.navigator.clipboard?.writeText(shareUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ಲಿಂಕ್ ಕಾಪಿ ಮಾಡಲಾಗಿದೆ!'), duration: Duration(seconds: 2)),
            );
          },
        ),
      ],
    );
  }

  void _openUrl(String url) {
    html.window.open(url, '_blank');
  }

  Widget _shareIcon({required IconData icon, required Color color, required String tooltip, required VoidCallback onPressed}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

/// Drop-in replacement for `Image.network(url, width: w, height: h, fit: f)`
/// that never shows a broken-image error box. While loading, shows a
/// shimmer placeholder; if the image fails (broken URL, CORS, 404, etc.),
/// shows a clean neutral placeholder icon instead of red debug error text.
class SampathiImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SampathiImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();

    return CachedNetworkImage(
      imageUrl: _resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(width: width, height: height, color: Colors.white),
      ),
      errorWidget: (context, url, error) => _placeholder(),
    );
  }

  // Images uploaded to our own WordPress site are routed through the
  // /sampathi/v1/image-proxy endpoint, which attaches a CORS header PHP-side
  // (needed for Flutter Web's default CanvasKit renderer to read the image
  // bytes cross-origin). External images (e.g. from unsplash or other public
  // CDNs, which already send their own CORS headers) are left untouched.
  String get _resolvedUrl {
    final restBase = ApiClient.baseUrl; // e.g. http://sampathi-news.local/wp-json
    final siteBase = restBase.replaceAll('/wp-json', '');
    if (!url.startsWith(siteBase)) return url;

    return '$restBase/sampathi/v1/image-proxy?url=${Uri.encodeQueryComponent(url)}';
  }

  Widget _placeholder() {
    // Icon sizes must always be finite — width can legitimately be
    // double.infinity (e.g. full-bleed images), which would otherwise make
    // the icon size infinite too and crash the renderer. Fall back to a
    // fixed, always-safe size whenever width isn't a normal finite number.
    final safeIconSize = (width != null && width!.isFinite) ? width! * 0.3 : 32.0;

    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: safeIconSize),
    );
  }
}
