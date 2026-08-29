import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_page.dart';
import '../features/news/article_page.dart';
import '../features/category/category_page.dart';
import '../features/district/district_page.dart';
import '../features/search/search_page.dart';
import '../features/admin/admin_login_page.dart';
import '../features/admin/admin_publish_page.dart';
import '../features/admin/admin_publish_ad_page.dart';
import '../features/latest/latest_news_page.dart';
import '../features/profile/profile_page.dart';
import '../providers/providers.dart';

/// Built once via Provider (not rebuilt on every widget rebuild); the
/// [redirect] callback still reads the *live* admin auth state on every
/// navigation attempt via `ref.read`, so login/logout guarding stays correct.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAdminRoute = state.matchedLocation.startsWith('/admin');
      final isLoginRoute = state.matchedLocation == '/admin';
      final isLoggedIn = ref.read(adminAuthProvider);

      if (isAdminRoute && !isLoginRoute && !isLoggedIn) {
        return '/admin'; // Bounce to login if trying to reach a guarded admin page
      }
      return null;
    },
    errorPageBuilder: (context, state) => MaterialPage(
      key: state.pageKey,
      child: const Scaffold(
        body: Center(
          child: Text('ಪುಟ ಕಂಡುಬಂದಿಲ್ಲ (Page Not Found) \n 404 - ಪುಟ ಸಿಗಲಿಲ್ಲ'),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/article/:id',
        name: 'article',
        builder: (context, state) {
          final articleId = state.pathParameters['id'] ?? '';
          return ArticlePage(articleId: articleId);
        },
      ),
      GoRoute(
        path: '/category/:slug',
        name: 'category',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          final name = state.uri.queryParameters['name'] ?? '';
          return CategoryPage(categorySlug: slug, categoryName: name);
        },
      ),
      GoRoute(
        path: '/district/:slug',
        name: 'district',
        builder: (context, state) {
          final slug = state.pathParameters['slug'] ?? '';
          final name = state.uri.queryParameters['name'] ?? '';
          return DistrictPage(districtSlug: slug, districtName: name);
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return SearchPage(initialQuery: query);
        },
      ),
      GoRoute(
        path: '/latest',
        name: 'latest_news',
        builder: (context, state) => const LatestNewsPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin_login',
        builder: (context, state) => const AdminLoginPage(),
      ),
      GoRoute(
        path: '/admin/publish',
        name: 'admin_publish',
        builder: (context, state) => const AdminPublishPage(),
      ),
      GoRoute(
        path: '/admin/publish-ad',
        name: 'admin_publish_ad',
        builder: (context, state) => const AdminPublishAdPage(),
      ),
    ],
  );
});
