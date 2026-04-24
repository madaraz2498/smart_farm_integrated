import 'dart:async';
import 'dart:convert';
import 'package:smart_farm/core/utils/production_logger.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Central HTTP gateway. Singleton — call [ApiClient.instance].
///
/// Base URL: https://mahmoud123mahmoud-smartfarm-api.hf.space
///
/// Endpoints are form-encoded for auth, multipart for image uploads,
/// and JSON for admin / system calls.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String baseUrl         = 'https://mahmoud123mahmoud-smartfarm-api.hf.space';
  static const Duration _timeout      = Duration(seconds: 30);
  static const Duration _uploadTimeout = Duration(seconds: 60);

  String? _token;

  void setToken(String? t) {
    _token = t;
    ProductionLogger.api('token ${t != null ? "SET" : "CLEARED"}');
  }

  String? get token => _token;

  // ── Headers ────────────────────────────────────────────────────────────────

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Map<String, String> _formHeaders() => {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept':       'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── GET ────────────────────────────────────────────────────────────────────

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = _uri(path, query);
    ProductionLogger.api('GET $uri');
    try {
      return _handle(await http.get(uri, headers: _jsonHeaders()).timeout(_timeout));
    } on SocketException  { throw const ApiException('No internet connection.', statusCode: 0); }
    on TimeoutException   { throw const ApiException('Request timed out.',       statusCode: 408); }
  }

  // ── POST JSON ──────────────────────────────────────────────────────────────

  Future<dynamic> post(String path,
      {Map<String, dynamic>? body, Map<String, String>? query}) async {
    final uri = _uri(path, query);
    ProductionLogger.api('POST $uri');
    try {
      return _handle(await http
          .post(uri,
              headers: _jsonHeaders(),
              body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout));
    } on SocketException {
      throw const ApiException('No internet connection.', statusCode: 0);
    } on TimeoutException {
      throw const ApiException('Request timed out.', statusCode: 408);
    }
  }

  // ── POST form-encoded ──────────────────────────────────────────────────────
  // Used for: POST /login · POST /register · chatbot · crop · soil

  Future<dynamic> postForm(String path, Map<String, String> fields) async {
    final uri = _uri(path);
    ProductionLogger.api('POST-FORM $uri  keys=${fields.keys.toList()}');
    try {
      return _handle(await http.post(uri,
          headers: _formHeaders(),
          body:    fields
      ).timeout(_timeout));
    } on SocketException  { throw const ApiException('No internet connection.', statusCode: 0); }
    on TimeoutException   { throw const ApiException('Request timed out.',       statusCode: 408); }
  }

  // ── PUT ────────────────────────────────────────────────────────────────────

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _uri(path);
    ProductionLogger.api('PUT $uri');
    try {
      return _handle(await http.put(uri,
          headers: _jsonHeaders(),
          body: body != null ? jsonEncode(body) : null
      ).timeout(_timeout));
    } on SocketException  { throw const ApiException('No internet connection.', statusCode: 0); }
    on TimeoutException   { throw const ApiException('Request timed out.',       statusCode: 408); }
  }

  // ── PATCH ──────────────────────────────────────────────────────────────────
  // Used for PATCH /admin/users/activate|deactivate/{id}

  Future<dynamic> patch(String path,
      {Map<String, dynamic>? body, Map<String, String>? query}) async {
    final uri = _uri(path, query);
    ProductionLogger.api('PATCH $uri');
    try {
      return _handle(await http
          .patch(uri,
              headers: _jsonHeaders(),
              body: body != null ? jsonEncode(body) : null)
          .timeout(_timeout));
    } on SocketException {
      throw const ApiException('No internet connection.', statusCode: 0);
    } on TimeoutException {
      throw const ApiException('Request timed out.', statusCode: 408);
    }
  }

  // ── PATCH form-encoded ─────────────────────────────────────────────────────
  // Used for endpoints that require form data with PATCH requests.
  Future<dynamic> patchForm(String path, Map<String, String> fields,
      {Map<String, String>? query}) async {
    final uri = _uri(path, query);
    ProductionLogger.api('PATCH-FORM $uri  keys=${fields.keys.toList()}');
    try {
      return _handle(await http
          .patch(uri, headers: _formHeaders(), body: fields)
          .timeout(_timeout));
    } on SocketException {
      throw const ApiException('No internet connection.', statusCode: 0);
    } on TimeoutException {
      throw const ApiException('Request timed out.', statusCode: 408);
    }
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────

  Future<dynamic> delete(String path, {Map<String, String>? query}) async {
    final uri = _uri(path, query);
    ProductionLogger.api('DELETE $uri');
    try {
      return _handle(
          await http.delete(uri, headers: _jsonHeaders()).timeout(_timeout));
    } on SocketException {
      throw const ApiException('No internet connection.', statusCode: 0);
    } on TimeoutException {
      throw const ApiException('Request timed out.', statusCode: 408);
    }
  }

  // ── Multipart upload ───────────────────────────────────────────────────────
  // Used for: /plants/detect · /animals/estimate-weight · /fruits/analyze-fruit

  Future<dynamic> postMultipart(
    String path, {
    required String fileField,
    required List<int> fileBytes,
    required String fileName,
    Map<String, String>? fields,
  }) async =>
      _multipart('POST', path,
          fileField: fileField,
          fileBytes: fileBytes,
          fileName: fileName,
          fields: fields);

  Future<dynamic> putMultipart(
    String path, {
    String? fileField,
    List<int>? fileBytes,
    String? fileName,
    Map<String, String>? fields,
  }) async =>
      _multipart('PUT', path,
          fileField: fileField,
          fileBytes: fileBytes,
          fileName: fileName,
          fields: fields);

  Future<dynamic> _multipart(
    String method,
    String path, {
    String? fileField,
    List<int>? fileBytes,
    String? fileName,
    Map<String, String>? fields,
  }) async {
    final uri = _uri(path);
    ProductionLogger.api('[$method-MULTIPART] $uri  field=$fileField');
    try {
      final req = http.MultipartRequest(method, uri);
      if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
      req.headers['Accept'] = 'application/json';
      if (fields != null) req.fields.addAll(fields);

      if (fileField != null && fileBytes != null && fileName != null) {
        req.files.add(
            http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName));
      }

      final resp =
          await http.Response.fromStream(await req.send().timeout(_uploadTimeout));
      return _handle(resp);
    } on SocketException {
      throw const ApiException('No internet connection.', statusCode: 0);
    } on TimeoutException {
      throw const ApiException('Upload timed out.', statusCode: 408);
    }
  }

  // ── Response handler ───────────────────────────────────────────────────────

  dynamic _handle(http.Response r) {
    ProductionLogger.api('RESPONSE ${r.statusCode}  ${r.request?.url}');
    if (kDebugMode && r.body.isNotEmpty) {
      ProductionLogger.api('BODY ${r.body.length > 500 ? "${r.body.substring(0, 500)}…" : r.body}');
    }

    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return null;
      try { return jsonDecode(r.body); } catch (_) { return r.body; }
    }

    final msg = _extractMessage(r);
    ProductionLogger.api('Error ${r.statusCode}: $msg');
    switch (r.statusCode) {
      case 400:
        throw ApiException(msg, statusCode: 400);
      case 401:
        throw ApiException(msg, statusCode: 401);
      case 403:
        throw ApiException(msg, statusCode: 403);
      case 404:
        throw ApiException('Endpoint not found: ${r.request?.url.path}',
            statusCode: 404);
      case 422:
        throw ApiException(msg, statusCode: 422);
      case 500:
        throw ApiException('Internal server error.', statusCode: 500);
      default:
        throw ApiException(msg, statusCode: r.statusCode);
    }
  }

  String _extractMessage(http.Response r) {
    if (r.body.isEmpty) return 'Error ${r.statusCode}.';
    try {
      final e = jsonDecode(r.body);
      if (e is Map) {
        if (e['detail'] is String) return e['detail'] as String;
        if (e['detail'] is List)  return (e['detail'] as List)
            .map((x) => x is Map ? (x['msg'] ?? '') : x.toString())
            .where((s) => s.toString().isNotEmpty)
            .join(', ');
        if (e['message'] is String) return e['message'] as String;
        if (e['msg']     is String) return e['msg']     as String;
      }
    } catch (_) {}
    return r.body;
  }

  // ── URI builder ────────────────────────────────────────────────────────────

  Uri _uri(String path, [Map<String, String>? q]) {
    final b = Uri.parse(baseUrl);
    return Uri(scheme: b.scheme, host: b.host, path: path, queryParameters: q);
  }
}
