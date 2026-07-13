import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendApiClient {
  BackendApiClient({
    required this.baseUrl,
    this.authToken,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

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

  Future<dynamic> putJson(String path, Map<String, dynamic> body) async {
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

    return _decodeResponse(response.body);
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

  /// Uploads an image file via multipart POST to [path] (field name: 'image').
  /// Returns the decoded JSON response or throws on failure.
  Future<Map<String, dynamic>> uploadImageFile(
    String path,
    File file,
  ) async {
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri);
    final uploadHeaders = Map<String, String>.from(_headers)
      ..remove('Content-Type');
    request.headers.addAll(uploadHeaders);
    request.files.add(await http.MultipartFile.fromPath('image', file.path));
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw Exception('POST $path (multipart) failed: ${streamed.statusCode}');
    }
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'raw': body};
  }

  /// Registers a Firebase Cloud Messaging device token for [userId].
  Future<void> registerFcmToken({
    required String userId,
    required String token,
    String platform = 'flutter',
  }) async {
    await postJsonAny(
      '/devices/register-token',
      {'userId': userId, 'token': token, 'platform': platform},
    );
  }

  /// Unregisters an FCM token (e.g. on logout).
  Future<void> unregisterFcmToken({
    required String userId,
    required String token,
  }) async {
    final response = await _httpClient
        .delete(
          _uri('/devices/register-token'),
          headers: _headers,
          body: jsonEncode({'userId': userId, 'token': token}),
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode >= 400) {
      throw Exception('DELETE /devices/register-token failed: ${response.statusCode}');
    }
  }

  dynamic _decodeResponse(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      return jsonDecode(rawBody);
    } catch (e) {
      debugPrint('BackendApiClient._decodeResponse(): non-JSON response fallback: $e');
      return <String, dynamic>{'raw': rawBody};
    }
  }
}
