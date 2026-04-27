import 'dart:async';
import 'dart:collection';

/// Centralized request deduplication and caching layer
/// Prevents duplicate API calls and implements basic caching
class RequestCache {
  static final RequestCache _instance = RequestCache._();
  static RequestCache get instance => _instance;
  
  RequestCache._();

  final Map<String, _CachedRequest> _cache = {};
  final Map<String, Future<dynamic>> _inFlightRequests = {};
  
  /// Default cache duration (5 minutes)
  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  
  /// Minimum interval between identical requests (2 seconds)
  static const Duration _minRequestInterval = Duration(seconds: 2);

  /// Execute a request with deduplication and caching
  /// 
  /// [key] - Unique cache key for the request
  /// [fetcher] - Function that performs the actual API call
  /// [cacheDuration] - How long to cache the result
  /// [forceRefresh] - Skip cache and force fresh request
  /// [throttle] - Apply throttling to prevent rapid requests
  Future<T> execute<T>({
    required String key,
    required Future<T> Function() fetcher,
    Duration? cacheDuration,
    bool forceRefresh = false,
    bool throttle = true,
  }) async {
    final now = DateTime.now();
    final duration = cacheDuration ?? _defaultCacheDuration;
    
    // Check if we have a valid cached result
    if (!forceRefresh && _cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (!cached.isExpired(duration)) {
        return cached.value as T;
      } else {
        // Remove expired cache entry
        _cache.remove(key);
      }
    }
    
    // Check throttling (prevent rapid duplicate requests)
    if (throttle && !forceRefresh && _cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (now.difference(cached.timestamp) < _minRequestInterval) {
        return cached.value as T;
      }
    }
    
    // Check if there's already an in-flight request
    if (_inFlightRequests.containsKey(key)) {
      return await _inFlightRequests[key] as T;
    }
    
    // Execute the request
    final future = fetcher();
    _inFlightRequests[key] = future;
    
    try {
      final result = await future;
      
      // Cache the result
      _cache[key] = _CachedRequest(
        value: result,
        timestamp: now,
      );
      
      return result;
    } finally {
      // Clean up in-flight request
      _inFlightRequests.remove(key);
    }
  }

  /// Clear cache for a specific key
  void invalidate(String key) {
    _cache.remove(key);
    _inFlightRequests.remove(key);
  }

  /// Clear all cache
  void clearAll() {
    _cache.clear();
    _inFlightRequests.clear();
  }

  /// Clear expired cache entries
  void clearExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, cached) {
      return cached.isExpired(_defaultCacheDuration);
    });
  }

  /// Get cache statistics
  CacheStats get stats => CacheStats(
    cacheSize: _cache.length,
    inFlightRequests: _inFlightRequests.length,
  );
}

/// Internal cached request wrapper
class _CachedRequest<T> {
  final T value;
  final DateTime timestamp;
  
  _CachedRequest({
    required this.value,
    required this.timestamp,
  });
  
  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(timestamp) > maxAge;
  }
}

/// Cache statistics
class CacheStats {
  final int cacheSize;
  final int inFlightRequests;
  
  const CacheStats({
    required this.cacheSize,
    required this.inFlightRequests,
  });
  
  @override
  String toString() => 'CacheStats(size: $cacheSize, inFlight: $inFlightRequests)';
}

/// Extension for easy cache key generation
extension CacheKeys on String {
  String withParams(Map<String, dynamic> params) {
    if (params.isEmpty) return this;
    final paramString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '$this?$paramString';
  }
}
