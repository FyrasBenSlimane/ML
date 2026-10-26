import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.status});

  final String message;
  final int? status;

  bool get isOffline => status == null;

  @override
  String toString() => message;
}

/// Thin JSON client shared by every model module. The base URL is read on each
/// call, so changing the server in Settings takes effect immediately.
class ApiClient {
  ApiClient(this._baseUrl, {http.Client? client}) : _http = client ?? http.Client();

  final String Function() _baseUrl;
  final http.Client _http;

  /// Bearer token of the signed-in user (set by AuthCubit). When present it is
  /// sent on every request so the backend knows who is calling.
  String? authToken;

  String get baseUrl => _baseUrl();

  Uri uri(String path) => Uri.parse('$baseUrl$path');

  /// Auth header + any per-call extras (e.g. the patient code on /predict).
  Map<String, String> _headers([Map<String, String>? extra]) {
    final headers = <String, String>{};
    final token = authToken;
    if (token != null) headers['Authorization'] = 'Bearer $token';
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  Future<Map<String, dynamic>> getJson(String path,
          {Duration timeout = const Duration(seconds: 12)}) =>
      _send(() => _http.get(uri(path), headers: _headers()), timeout);

  Future<Map<String, dynamic>> postJson(String path, Object body,
          {Map<String, String>? headers, Duration timeout = const Duration(seconds: 25)}) =>
      _send(
        () => _http.post(
          uri(path),
          headers: _headers({'Content-Type': 'application/json', ...?headers}),
          body: jsonEncode(body),
        ),
        timeout,
      );

  Future<List<dynamic>> getList(String path,
      {Duration timeout = const Duration(seconds: 12)}) async {
    final res = await _raw(() => _http.get(uri(path), headers: _headers()), timeout);
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  Future<Map<String, dynamic>> _send(
      Future<http.Response> Function() call, Duration timeout) async {
    final res = await _raw(call, timeout);
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<http.Response> _raw(Future<http.Response> Function() call, Duration timeout) async {
    final http.Response res;
    try {
      res = await call().timeout(timeout);
    } on TimeoutException {
      throw ApiException('The server at $baseUrl took too long to answer.');
    } on http.ClientException {
      throw ApiException("Can't reach the server at $baseUrl. "
          'Is the backend running and is the address right?');
    } catch (_) {
      throw ApiException("Can't reach the server at $baseUrl.");
    }
    if (res.statusCode >= 400) {
      var detail = 'Server error ${res.statusCode}';
      try {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        if (body is Map && body['detail'] != null) detail = body['detail'].toString();
      } catch (_) {}
      throw ApiException(detail, status: res.statusCode);
    }
    return res;
  }
}
