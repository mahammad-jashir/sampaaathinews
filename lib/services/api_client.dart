import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final Dio _dio;
  // Points at your local WordPress site's REST API. Replace "sampathi-news.local"
  // with your actual Local by Flywheel site domain if different. All content
  // (news + ads) is now managed via wp-admin -> "Publish News" / "Ad Dashboard".
  static const String baseUrl = 'http://sampathi-news.local/wp-json';

  ApiClient()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    _initializeInterceptors();
  }

  Dio get dio => _dio;

  void _initializeInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Uses a custom header (not "Authorization") so it isn't stripped
          // by local dev servers (e.g. Local by Flywheel's Nginx) before
          // reaching WordPress. See sampathi_authenticate_via_token() in
          // the plugin's sampathi-news-core.php.
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('sampathi_admin_token');
          if (token != null) {
            options.headers['X-Sampathi-Token'] = token;
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Log or process API errors globally
          print('API ERROR [${error.response?.statusCode}]: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  // Helper method to set the admin token after login
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sampathi_admin_token', token);
  }

  // Helper method to clear the admin token on logout
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sampathi_admin_token');
  }
}
