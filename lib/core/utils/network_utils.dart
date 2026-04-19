import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/production_logger.dart';

/// Network utility with retry handling and timeout for API calls
class NetworkUtils {
  static const int _defaultTimeout = 30; // seconds
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// HTTP GET with retry and timeout
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    int? timeoutSeconds,
    int? maxRetries,
  }) async {
    return _executeWithRetry(
      () => http.get(url, headers: headers),
      url.toString(),
      timeoutSeconds: timeoutSeconds,
      maxRetries: maxRetries,
    );
  }

  /// HTTP POST with retry and timeout
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    int? timeoutSeconds,
    int? maxRetries,
  }) async {
    return _executeWithRetry(
      () => http.post(url, headers: headers, body: body, encoding: encoding),
      url.toString(),
      timeoutSeconds: timeoutSeconds,
      maxRetries: maxRetries,
    );
  }

  /// HTTP PUT with retry and timeout
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    int? timeoutSeconds,
    int? maxRetries,
  }) async {
    return _executeWithRetry(
      () => http.put(url, headers: headers, body: body, encoding: encoding),
      url.toString(),
      timeoutSeconds: timeoutSeconds,
      maxRetries: maxRetries,
    );
  }

  /// HTTP DELETE with retry and timeout
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    int? timeoutSeconds,
    int? maxRetries,
  }) async {
    return _executeWithRetry(
      () => http.delete(url, headers: headers, body: body, encoding: encoding),
      url.toString(),
      timeoutSeconds: timeoutSeconds,
      maxRetries: maxRetries,
    );
  }

  /// Execute HTTP request with retry logic and timeout
  static Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() requestFn,
    String url, {
    int? timeoutSeconds,
    int? maxRetries,
  }) async {
    final timeout = timeoutSeconds ?? _defaultTimeout;
    final retries = maxRetries ?? _maxRetries;
    
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        ProductionLogger.api('Request: $url (attempt ${attempt + 1})');
        
        final response = await requestFn()
            .timeout(Duration(seconds: timeout), onTimeout: () {
          throw TimeoutException('Request timeout after ${timeout}s', null);
        });
        
        ProductionLogger.api('Response: ${response.statusCode} for $url');
        
        // Don't retry on client errors (4xx)
        if (response.statusCode >= 400 && response.statusCode < 500) {
          return response;
        }
        
        // Success response
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        
        // Server error, retry if we have attempts left
        if (attempt < retries) {
          ProductionLogger.warning('Server error ${response.statusCode}, retrying...', response.body);
          await Future.delayed(_retryDelay * (attempt + 1)); // Exponential backoff
          continue;
        }
        
        return response;
        
      } catch (e) {
        ProductionLogger.error('Request failed (attempt ${attempt + 1}): $e');
        
        // Last attempt, rethrow the exception
        if (attempt == retries) {
          rethrow;
        }
        
        // Wait before retry
        await Future.delayed(_retryDelay * (attempt + 1));
      }
    }
    
    throw Exception('Max retries exceeded for $url');
  }

  /// Check if device is online (basic connectivity check)
  static Future<bool> isOnline() async {
    try {
      final response = await http.get(
        Uri.parse('https://dns.google/resolve?name=google.com'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      ProductionLogger.warning('Connectivity check failed: $e');
      return false;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  final dynamic cause;
  
  const TimeoutException(this.message, this.cause);
  
  @override
  String toString() => 'TimeoutException: $message';
}
