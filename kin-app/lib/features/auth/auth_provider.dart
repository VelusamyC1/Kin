import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_client.dart';

const _storage = FlutterSecureStorage();

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(ref),
);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(dioProvider);
      final res = await dio.post('/auth/login', data: {'email': email, 'password': password});
      await _saveTokens(res.data);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> signup(String email, String password, String firstName, String lastName) async {
    state = const AsyncValue.loading();
    try {
      final dio = _ref.read(dioProvider);
      final res = await dio.post('/auth/signup', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      });
      await _saveTokens(res.data);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final dio = _ref.read(dioProvider);
      final refresh = await _storage.read(key: 'refresh_token');
      if (refresh != null) {
        await dio.post('/auth/logout', data: {'refreshToken': refresh});
      }
    } finally {
      await _storage.deleteAll();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _storage.write(key: 'access_token', value: data['accessToken']);
    await _storage.write(key: 'refresh_token', value: data['refreshToken']);
  }
}
