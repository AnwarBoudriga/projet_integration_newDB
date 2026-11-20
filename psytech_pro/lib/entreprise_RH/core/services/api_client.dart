import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../constants/app_config.dart';

/// Erreur renvoyée par l'API (ou réseau) avec un message lisible en français.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Client HTTP unique du module Entreprise (token JWT en mémoire).
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  String? _token;

  /// Appelé quand le serveur répond 401 (token expiré / invalide) hors écran de connexion.
  void Function()? onUnauthorized;

  bool get hasToken => _token != null;

  void setToken(String? token) => _token = token;

  Uri _uri(String path, Map<String, dynamic>? query) {
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value != null && '$value'.isNotEmpty) params[key] = '$value';
    });
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    final request = http.Request(method, _uri(path, query));
    request.headers['Accept'] = '*/*';
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    late final http.Response response;
    try {
      final streamed = await _http.send(request).timeout(AppConfig.requestTimeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException('Le serveur ne répond pas. Réessayez.');
    } catch (_) {
      throw const ApiException(
          'Serveur injoignable. Vérifiez que le backend est démarré.');
    }

    if (response.statusCode >= 400) {
      if (response.statusCode == 401 && !path.endsWith('/auth/login')) {
        _token = null;
        onUnauthorized?.call();
      }
      throw ApiException(_messageOf(response), statusCode: response.statusCode);
    }
    return response;
  }

  /// Format d'erreur de l'API: { message, errors: [{champ, message}] }.
  String _messageOf(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map) {
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors
              .map((e) => e is Map ? '${e['message']}' : '$e')
              .join('\n');
        }
        if (data['message'] != null) return '${data['message']}';
      }
    } catch (_) {}
    return 'Erreur serveur (${response.statusCode}).';
  }

  dynamic _json(http.Response response) {
    if (response.statusCode == 204 || response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      _json(await _request('GET', path, query: query));

  Future<dynamic> post(String path, {Object? body}) async =>
      _json(await _request('POST', path, body: body ?? <String, dynamic>{}));

  Future<dynamic> put(String path, {Object? body}) async =>
      _json(await _request('PUT', path, body: body ?? <String, dynamic>{}));

  Future<dynamic> patch(String path) async =>
      _json(await _request('PATCH', path));

  /// Retourne le JSON de la réponse (liste mise à jour) ou null pour un 204.
  Future<dynamic> delete(String path) async =>
      _json(await _request('DELETE', path));

  /// Téléchargement d'un fichier (export CSV / PDF).
  Future<Uint8List> getBytes(String path, {Map<String, dynamic>? query}) async =>
      (await _request('GET', path, query: query)).bodyBytes;
}
