import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class CredentialStore {
  final FlutterSecureStorage storage;
  const CredentialStore([this.storage = const FlutterSecureStorage()]);

  Future<String?> get access => storage.read(key: 'access_token');
  Future<String?> get refresh => storage.read(key: 'refresh_token');

  Future<void> save(String access, String refresh) async {
    await storage.write(key: 'access_token', value: access);
    await storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clear() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }
}

class ApiClient {
  final Uri baseUri;
  final http.Client httpClient;
  final CredentialStore credentials;
  Future<void>? _refreshing;
  String? _accessToken;
  String? _refreshToken;
  VoidCallback? onUnauthorized;

  ApiClient({
    Uri? baseUri,
    http.Client? httpClient,
    CredentialStore? credentials,
  }) : baseUri = baseUri ?? _configuredUri(),
       httpClient = httpClient ?? http.Client(),
       credentials = credentials ?? const CredentialStore();

  static Uri _configuredUri() {
    const configured = String.fromEnvironment('API_BASE_URL');
    final uri = Uri.tryParse(
      configured.isEmpty ? ApiConfig.baseUrl : configured,
    );
    if (uri == null ||
        !uri.hasAuthority ||
        !uri.path.endsWith('/api/v1/') ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.scheme != 'https' && !(kDebugMode && uri.scheme == 'http'))) {
      throw StateError(
        'Set a valid API_BASE_URL or backend URL in lib/config/api_config.dart (HTTPS is required outside debug builds).',
      );
    }
    return uri;
  }

  bool get hasSession => _refreshToken != null;

  Future<void> restore() async {
    _accessToken = await credentials.access;
    _refreshToken = await credentials.refresh;
    if (_accessToken == null || _refreshToken == null) await clearSession();
  }

  Future<void> setSession(Map<String, Object?> json) async {
    final access = json['token'];
    final refresh = json['refresh_token'];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty) {
      throw const ApiException('The server returned an invalid session.');
    }
    await credentials.save(access, refresh);
    _accessToken = access;
    _refreshToken = refresh;
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    await credentials.clear();
  }

  Future<Object?> get(String path) => request('GET', path);
  Future<Object?> post(String path, [Map<String, Object?>? body]) =>
      request('POST', path, body: body);
  Future<Object?> patch(String path, [Map<String, Object?>? body]) =>
      request('PATCH', path, body: body);

  Future<void> revokeSession() async {
    if (_accessToken == null && _refreshToken != null) await _refresh();
    var response = await _send('POST', 'auth/logout', {
      'refresh_token': _refreshToken,
    }, true);
    if (response.statusCode == 401) {
      try {
        await _refresh();
      } on ApiException catch (error) {
        if (error.statusCode != 401) rethrow;
        await clearSession();
        onUnauthorized?.call();
        return;
      }
      response = await _send('POST', 'auth/logout', {
        'refresh_token': _refreshToken,
      }, true);
    }
    _decode(response);
    await clearSession();
  }

  Future<Object?> request(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool authenticated = true,
  }) async {
    if (authenticated && _accessToken == null && _refreshToken != null) {
      await _refresh();
    }
    final response = await _send(method, path, body, authenticated);
    if (response.statusCode == 401 && authenticated) {
      try {
        await _refresh();
      } on ApiException catch (error) {
        if (error.statusCode != 401) rethrow;
        await clearSession();
        onUnauthorized?.call();
        throw const ApiException(
          'Your session expired. Please sign in again.',
          401,
        );
      }
      final retried = await _send(method, path, body, true);
      if (retried.statusCode == 401) {
        await clearSession();
        onUnauthorized?.call();
      }
      return _decode(retried);
    }
    return _decode(response);
  }

  Future<http.Response> _send(
    String method,
    String path,
    Map<String, Object?>? body,
    bool authenticated,
  ) async {
    final uri = baseUri.resolve(path);
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (authenticated && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    for (var attempt = 0; ; attempt++) {
      try {
        final request = http.Request(method, uri)..headers.addAll(headers);
        if (body != null) request.body = jsonEncode(body);
        final streamed = await httpClient
            .send(request)
            .timeout(const Duration(seconds: 12));
        final response = await http.Response.fromStream(
          streamed,
        ).timeout(const Duration(seconds: 12));
        if (method == 'GET' && attempt < 2 && response.statusCode >= 500) {
          await Future<void>.delayed(
            Duration(milliseconds: 300 * (attempt + 1)),
          );
          continue;
        }
        return response;
      } on SocketException catch (_) {
        if (method == 'GET' && attempt < 2) continue;
        throw const ApiException(
          'Could not connect. Check your internet connection.',
        );
      } on TimeoutException catch (_) {
        if (method == 'GET' && attempt < 2) continue;
        throw const ApiException('The request timed out. Please retry.');
      } on http.ClientException catch (_) {
        if (method == 'GET' && attempt < 2) continue;
        throw const ApiException(
          'The connection was interrupted. Please retry.',
        );
      } on IOException catch (_) {
        if (method == 'GET' && attempt < 2) continue;
        throw const ApiException(
          'Could not establish a secure connection. Please retry.',
        );
      }
    }
  }

  Object? _decode(http.Response response) {
    if (response.statusCode >= 500) {
      throw ApiException(
        'The service is temporarily unavailable. Please retry.',
        response.statusCode,
      );
    }
    Object? json;
    try {
      json = jsonDecode(response.body);
    } on FormatException {
      throw const ApiException('The server returned an unreadable response.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return json;
    if (response.statusCode == 401) {
      throw const ApiException(
        'Your session expired. Please sign in again.',
        401,
      );
    }
    if (response.statusCode == 429) {
      throw const ApiException(
        'Too many requests. Please wait and retry.',
        429,
      );
    }
    if (response.statusCode == 503) {
      throw const ApiException(
        'The service is temporarily unavailable. Please retry.',
        503,
      );
    }
    final message = json is Map ? json['message'] : null;
    if (response.statusCode == 422 && json is Map && json['errors'] is Map) {
      final errors = json['errors'] as Map;
      final first = errors.values
          .whereType<List>()
          .expand((items) => items)
          .whereType<String>()
          .firstOrNull;
      if (first != null) throw ApiException(first, 422);
    }
    throw ApiException(
      message is String && response.statusCode < 500
          ? message
          : 'The request could not be completed.',
      response.statusCode,
    );
  }

  Future<void> _refresh() async {
    if (_refreshing != null) return _refreshing;
    final refreshToken = _refreshToken;
    if (refreshToken == null) {
      throw const ApiException('Please sign in again.', 401);
    }
    final future = () async {
      final response = await _send('POST', 'auth/refresh', {
        'refresh_token': refreshToken,
      }, false);
      final json = _decode(response);
      if (json is! Map<String, Object?>) {
        throw const ApiException('The server returned an invalid session.');
      }
      await setSession(json);
    }();
    _refreshing = future;
    try {
      await future;
    } finally {
      _refreshing = null;
    }
  }
}
