import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _baseUrl = 'http://10.0.2.2:8080'; // Android emulator → localhost
const _storage = FlutterSecureStorage();

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: 'access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        // Try token refresh
        final refreshed = await _tryRefresh(error.requestOptions);
        if (refreshed != null) return handler.resolve(refreshed);
      }
      return handler.next(error);
    },
  ));

  return dio;
});

Future<Response?> _tryRefresh(RequestOptions original) async {
  final refreshToken = await _storage.read(key: 'refresh_token');
  if (refreshToken == null) return null;

  try {
    final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
    final res = await refreshDio.post('/auth/refresh', data: {'refreshToken': refreshToken});
    final newAccess = res.data['accessToken'] as String;
    final newRefresh = res.data['refreshToken'] as String;
    await _storage.write(key: 'access_token', value: newAccess);
    await _storage.write(key: 'refresh_token', value: newRefresh);

    final retryOptions = Options(
      method: original.method,
      headers: {...original.headers, 'Authorization': 'Bearer $newAccess'},
    );
    return await Dio(BaseOptions(baseUrl: _baseUrl))
        .request(original.path, data: original.data, options: retryOptions);
  } catch (_) {
    await _storage.deleteAll();
    return null;
  }
}
