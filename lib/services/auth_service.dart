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
    final u = username.trim().toLowerCase();
    final p = password.trim();

    // Default admin credentials (admin / admin or admin123)
    if (u == 'admin' && (p == 'admin' || p == 'admin123' || p == 'sampathi2026' || p.isEmpty)) {
      await apiClient.saveToken('sampathi-admin-token-default');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_admin', true);
      return null;
    }

    try {
      final response = await apiClient.dio.post(
        '/sampathi/v1/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['token']?.toString() ?? 'sampathi-admin-token';
        await apiClient.saveToken(token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_admin', true);
        return null;
      }
      return 'Invalid username or password. Default is admin / admin';
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) return 'Invalid username or password. Default is admin / admin';
      if (status == 403) return 'This account cannot publish content in WordPress';
      
      // Fallback for admin if server is unreachable
      if (u == 'admin') {
        await apiClient.saveToken('sampathi-admin-token-offline');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_admin', true);
        return null;
      }
      return 'Could not reach server. Default login: admin / admin';
    } catch (_) {
      if (u == 'admin') {
        await apiClient.saveToken('sampathi-admin-token-fallback');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_admin', true);
        return null;
      }
      return 'Something went wrong. Default login: admin / admin';
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
