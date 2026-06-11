import 'dart:convert';

import 'package:http/http.dart' as http;

class BackendApiClient {
  BackendApiClient({
    required this.baseUrl,
    this.authToken,
    http.Client? httpClient,
  })
      : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final String? authToken;
  final http.Client _httpClient;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Uri _uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath');
  }

  Future<dynamic> getJson(String path) async {
    final response = await _httpClient
        .get(_uri(path), headers: _headers)
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('GET $path failed: ${response.statusCode}');
    }

    return _decodeResponse(response.body);
  }

  Future<List<dynamic>> getList(String path) async {
    final decoded = await getJson(path);
    if (decoded is List<dynamic>) {
      return decoded;
    }
    throw Exception('Unexpected list response for $path');
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final decoded = await postJsonAny(path, body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw Exception('Unexpected map response for $path');
  }

  Future<dynamic> postJsonAny(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _httpClient
        .post(
          _uri(path),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('POST $path failed: ${response.statusCode}');
    }

    return _decodeResponse(response.body);
  }

  Future<void> putJson(String path, Map<String, dynamic> body) async {
    final response = await _httpClient
        .put(
          _uri(path),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('PUT $path failed: ${response.statusCode}');
    }
  }

  Future<void> delete(String path) async {
    final response = await _httpClient
        .delete(
          _uri(path),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('DELETE $path failed: ${response.statusCode}');
    }
  }

  dynamic _decodeResponse(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return <String, dynamic>{'raw': rawBody};
    }
  }
}
