import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient apiClient;
  AuthService(this.apiClient);

  /// Logs in with a real WordPress username + password. Returns null on
  /// success, or an error message on failure. The user must be able to
  /// publish posts in WordPress (Author role or above).
  Future<String?> login(String username, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/sampathi/v1/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token'] as String;
        await apiClient.saveToken(token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_admin', true);
        return null;
      }
      return 'Invalid username or password';
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) return 'Invalid username or password';
      if (status == 403) return 'This account cannot publish content in WordPress';
      return 'Could not reach WordPress. Check the site is running and the URL in api_client.dart is correct.';
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> logout() async {
    await apiClient.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin', false);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_admin') ?? false;
  }
}
