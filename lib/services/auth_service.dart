import '../models/app_user.dart';
import 'api_client.dart';
import 'api_data.dart';

class AuthService {
  final ApiClient api;
  AuthService(this.api);

  Future<AppUser?> restore() async {
    await api.restore();
    if (!api.hasSession) return null;
    try {
      return AppUser.fromApi(ApiData.object(await api.get('auth/me'))['user']);
    } on ApiException catch (error) {
      if (error.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<AppUser> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    final response = ApiData.object(await api.request('POST', 'auth/register', authenticated: false, body: {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'password': password,
      'password_confirmation': password,
    }));
    final user = AppUser.fromApi(response['user']);
    await api.setSession(response);
    return user;
  }

  Future<AppUser> login(String email, String password) async {
    final response = ApiData.object(await api.request('POST', 'auth/login', authenticated: false, body: {
      'email': email.trim().toLowerCase(),
      'password': password,
    }));
    final user = AppUser.fromApi(response['user']);
    await api.setSession(response);
    return user;
  }

  Future<void> logout() async {
    final refresh = await api.credentials.refresh;
    if (refresh != null) await api.post('auth/logout', {'refresh_token': refresh});
    await api.clearSession();
  }
}
