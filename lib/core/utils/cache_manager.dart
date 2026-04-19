import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/production_logger.dart';

/// Local cache manager for reports and messages
class CacheManager {
  static const String _reportsKey = 'cached_reports';
  static const String _messagesKey = 'cached_messages';
  static const String _dashboardKey = 'cached_dashboard';
  static const Duration _cacheExpiry = Duration(hours: 1);
  
  static CacheManager? _instance;
  static CacheManager get instance => _instance ??= CacheManager._();
  CacheManager._();

  /// Cache reports data locally
  Future<void> cacheReports(String userId, List<Map<String, dynamic>> reports) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_reportsKey}_$userId';
      
      final cacheData = {
        'data': reports,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(key, jsonEncode(cacheData));
      ProductionLogger.reports('Cached ${reports.length} reports for user $userId');
    } catch (e) {
      ProductionLogger.error('Failed to cache reports: $e');
    }
  }

  /// Get cached reports data
  Future<List<Map<String, dynamic>>?> getCachedReports(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_reportsKey}_$userId';
      final cached = prefs.getString(key);
      
      if (cached == null) return null;
      
      final cacheData = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      
      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        await prefs.remove(key);
        ProductionLogger.reports('Reports cache expired for user $userId');
        return null;
      }
      
      final reports = (cacheData['data'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      
      ProductionLogger.reports('Loaded ${reports.length} cached reports for user $userId');
      return reports;
    } catch (e) {
      ProductionLogger.error('Failed to load cached reports: $e');
      return null;
    }
  }

  /// Cache messages data locally
  Future<void> cacheMessages(String userId, List<Map<String, dynamic>> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_messagesKey}_$userId';
      
      final cacheData = {
        'data': messages,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(key, jsonEncode(cacheData));
      ProductionLogger.notifications('Cached ${messages.length} messages for user $userId');
    } catch (e) {
      ProductionLogger.error('Failed to cache messages: $e');
    }
  }

  /// Get cached messages data
  Future<List<Map<String, dynamic>>?> getCachedMessages(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_messagesKey}_$userId';
      final cached = prefs.getString(key);
      
      if (cached == null) return null;
      
      final cacheData = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      
      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        await prefs.remove(key);
        ProductionLogger.notifications('Messages cache expired for user $userId');
        return null;
      }
      
      final messages = (cacheData['data'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
      
      ProductionLogger.notifications('Loaded ${messages.length} cached messages for user $userId');
      return messages;
    } catch (e) {
      ProductionLogger.error('Failed to load cached messages: $e');
      return null;
    }
  }

  /// Cache dashboard data locally
  Future<void> cacheDashboard(String userId, Map<String, dynamic> dashboard) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_dashboardKey}_$userId';
      
      final cacheData = {
        'data': dashboard,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(key, jsonEncode(cacheData));
      ProductionLogger.dashboard('Cached dashboard data for user $userId');
    } catch (e) {
      ProductionLogger.error('Failed to cache dashboard: $e');
    }
  }

  /// Get cached dashboard data
  Future<Map<String, dynamic>?> getCachedDashboard(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_dashboardKey}_$userId';
      final cached = prefs.getString(key);
      
      if (cached == null) return null;
      
      final cacheData = jsonDecode(cached) as Map<String, dynamic>;
      final timestamp = DateTime.parse(cacheData['timestamp'] as String);
      
      // Check if cache is expired (shorter expiry for dashboard)
      if (DateTime.now().difference(timestamp) > const Duration(minutes: 30)) {
        await prefs.remove(key);
        ProductionLogger.dashboard('Dashboard cache expired for user $userId');
        return null;
      }
      
      final dashboard = cacheData['data'] as Map<String, dynamic>;
      ProductionLogger.dashboard('Loaded cached dashboard for user $userId');
      return dashboard;
    } catch (e) {
      ProductionLogger.error('Failed to load cached dashboard: $e');
      return null;
    }
  }

  /// Clear all cached data for a user
  Future<void> clearUserCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove('${_reportsKey}_$userId'),
        prefs.remove('${_messagesKey}_$userId'),
        prefs.remove('${_dashboardKey}_$userId'),
      ]);
      ProductionLogger.info('Cleared all cache for user $userId');
    } catch (e) {
      ProductionLogger.error('Failed to clear cache: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final cacheKeys = keys.where((key) => 
        key.startsWith(_reportsKey) || 
        key.startsWith(_messagesKey) || 
        key.startsWith(_dashboardKey)
      ).toList();
      
      for (final key in cacheKeys) {
        await prefs.remove(key);
      }
      
      ProductionLogger.info('Cleared all cache data');
    } catch (e) {
      ProductionLogger.error('Failed to clear all cache: $e');
    }
  }

  /// Get cache size information
  Future<Map<String, int>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int reportsCount = 0, messagesCount = 0, dashboardCount = 0;
      
      for (final key in keys) {
        if (key.startsWith(_reportsKey)) reportsCount++;
        if (key.startsWith(_messagesKey)) messagesCount++;
        if (key.startsWith(_dashboardKey)) dashboardCount++;
      }
      
      return {
        'reports': reportsCount,
        'messages': messagesCount,
        'dashboard': dashboardCount,
      };
    } catch (e) {
      ProductionLogger.error('Failed to get cache info: $e');
      return {'reports': 0, 'messages': 0, 'dashboard': 0};
    }
  }
}
