import '../models/models.dart';
import '../services/api_client.dart';

abstract class NewsRepository {
  Future<List<Article>> fetchArticles({int? categoryId, int? districtId, String? search});
  Future<Article> fetchArticleDetails(int id);
  Future<List<Category>> fetchCategories();
  Future<List<District>> fetchDistricts();
}

abstract class AdRepository {
  Future<List<Advertisement>> fetchAds({String? position, int? categoryId, int? districtId});
  Future<void> logImpression(int adId);
  Future<void> logClick(int adId);
}

class WordPressNewsRepository implements NewsRepository {
  final ApiClient apiClient;
  WordPressNewsRepository(this.apiClient);

  @override
  Future<List<Article>> fetchArticles({int? categoryId, int? districtId, String? search}) async {
    final queryParameters = <String, dynamic>{};
    if (categoryId != null) queryParameters['category'] = categoryId;
    if (districtId != null) queryParameters['district'] = districtId;
    if (search != null) queryParameters['search'] = search;

    final response = await apiClient.dio.get('/sampathi/v1/news', queryParameters: queryParameters);
    return (response.data as List).map((json) => Article.fromJson(json)).toList();
  }

  @override
  Future<Article> fetchArticleDetails(int id) async {
    final response = await apiClient.dio.get('/sampathi/v1/news/$id');
    return Article.fromJson(response.data);
  }

  @override
  Future<List<Category>> fetchCategories() async {
    final response = await apiClient.dio.get('/sampathi/v1/categories');
    return (response.data as List).map((json) => Category.fromJson(json)).toList();
  }

  @override
  Future<List<District>> fetchDistricts() async {
    final response = await apiClient.dio.get('/sampathi/v1/districts');
    return (response.data as List).map((json) => District.fromJson(json)).toList();
  }
}

class WordPressAdRepository implements AdRepository {
  final ApiClient apiClient;
  WordPressAdRepository(this.apiClient);

  @override
  Future<List<Advertisement>> fetchAds({String? position, int? categoryId, int? districtId}) async {
    final queryParams = <String, dynamic>{};
    if (position != null) queryParams['position'] = position;
    if (categoryId != null) queryParams['category'] = categoryId;
    if (districtId != null) queryParams['district'] = districtId;

    final response = await apiClient.dio.get('/sampathi/v1/ads', queryParameters: queryParams);
    return (response.data as List).map((json) => Advertisement.fromJson(json)).toList();
  }

  @override
  Future<void> logImpression(int adId) async {
    try {
      await apiClient.dio.post('/sampathi/v1/ads/track', data: {
        'ad_id': adId,
        'action': 'impression',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Analytics logging is fire-and-forget; a failed impression ping shouldn't
      // break the reading experience, so we swallow this specific error only.
      print('Failed to log impression: $e');
    }
  }

  @override
  Future<void> logClick(int adId) async {
    try {
      await apiClient.dio.post('/sampathi/v1/ads/track', data: {
        'ad_id': adId,
        'action': 'click',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Failed to log click: $e');
    }
  }
}
