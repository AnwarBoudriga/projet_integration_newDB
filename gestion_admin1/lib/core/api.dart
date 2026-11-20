import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Api {
  /// Changez avec: flutter run --dart-define=API_URL=http://10.0.2.2:3000
  /// Accepte avec ou sans le suffixe /api (les chemins ci-dessous incluent déjà /api).
  static const _rawUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');
  static final String baseUrl = _rawUrl.replaceFirst(RegExp(r'/+$'), '').replaceFirst(RegExp(r'/api$'), '');

  static const _storage = FlutterSecureStorage();
  static VoidCallback? onUnauthorized;

  static final Dio dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) async {
        final isLogin = e.requestOptions.path.contains('/auth/login');
        if (e.response?.statusCode == 401 && !isLogin) {
          await logout();
          onUnauthorized?.call();
        }
        handler.next(e);
      },
    ));

  static Future<bool> hasToken() async => (await _storage.read(key: 'token')) != null;

  static Future<void> login(String identifiant, String motDePasse) async {
    final r = await dio.post('/api/admin/auth/login',
        data: {'identifiant': identifiant, 'motDePasse': motDePasse});
    await _storage.write(key: 'token', value: r.data['token'] as String);
  }

  static Future<void> logout() => _storage.delete(key: 'token');

  /// Extrait un message lisible d'une erreur Dio (format API: {message, errors[]}).
  static String errorMessage(Object e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map) {
        final errs = d['errors'];
        if (errs is List && errs.isNotEmpty) return errs.map((x) => x['message']).join('\n');
        if (d['message'] != null) return d['message'].toString();
      }
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
        return 'Serveur injoignable.';
      }
    }
    return 'Une erreur est survenue.';
  }
}
