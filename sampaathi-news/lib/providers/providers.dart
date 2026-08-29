import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../repositories/repositories.dart';
import '../models/models.dart';

// --- Services & Repositories Providers ---

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WordPressNewsRepository(apiClient);
});

final adRepositoryProvider = Provider<AdRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WordPressAdRepository(apiClient);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthService(apiClient);
});

// --- Admin Auth State ---

class AdminAuthNotifier extends StateNotifier<bool> {
  final AuthService authService;
  AdminAuthNotifier(this.authService) : super(false) {
    _restore();
  }

  Future<void> _restore() async {
    state = await authService.isLoggedIn();
  }

  Future<String?> login(String username, String password) async {
    final error = await authService.login(username, password);
    if (error == null) state = true;
    return error;
  }

  Future<void> logout() async {
    await authService.logout();
    state = false;
  }
}

final adminAuthProvider = StateNotifierProvider<AdminAuthNotifier, bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AdminAuthNotifier(authService);
});

// --- Theme & Configuration Providers ---

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light);

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

// --- Metadata Providers ---

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.fetchCategories();
});

final districtsProvider = FutureProvider<List<District>>((ref) async {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.fetchDistricts();
});

// --- News & Content Providers ---

final breakingNewsProvider = FutureProvider<List<Article>>((ref) async {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.fetchArticles(categoryId: 1); // Category ID 1 is "ಪ್ರಮುಖ ಸುದ್ದಿ" (Breaking/Top stories)
});

final latestNewsProvider = FutureProvider<List<Article>>((ref) async {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.fetchArticles();
});

final categoryNewsProvider = FutureProviderFamily<List<Article>, int>((ref, categoryId) async {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.fetchArticles(categoryId: categoryId);
});

final districtNewsProvider = FutureProviderFamily<List<Article>, int>((ref, districtId) async {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.fetchArticles(districtId: districtId);
});

final articleDetailsProvider = FutureProviderFamily<Article, int>((ref, articleId) async {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.fetchArticleDetails(articleId);
});

// --- Advertisement Providers ---

class AdQuery {
  final String position;
  final int? categoryId;
  final int? districtId;

  AdQuery({required this.position, this.categoryId, this.districtId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdQuery &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          categoryId == other.categoryId &&
          districtId == other.districtId;

  @override
  int get hashCode => position.hashCode ^ categoryId.hashCode ^ districtId.hashCode;
}

final advertisementsProvider = FutureProviderFamily<List<Advertisement>, AdQuery>((ref, query) async {
  final repo = ref.watch(adRepositoryProvider);
  return repo.fetchAds(
    position: query.position,
    categoryId: query.categoryId,
    districtId: query.districtId,
  );
});

// --- Search Providers ---

class SearchParams {
  final String query;
  final int? categoryId;
  final int? districtId;

  SearchParams({required this.query, this.categoryId, this.districtId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          categoryId == other.categoryId &&
          districtId == other.districtId;

  @override
  int get hashCode => query.hashCode ^ categoryId.hashCode ^ districtId.hashCode;
}

final searchProvider = FutureProviderFamily<List<Article>, SearchParams>((ref, params) async {
  final repo = ref.watch(newsRepositoryProvider);
  return repo.fetchArticles(
    search: params.query.isEmpty ? null : params.query,
    categoryId: params.categoryId,
    districtId: params.districtId,
  );
});
