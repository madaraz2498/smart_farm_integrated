import 'package:flutter/foundation.dart';

/// Structured logging utility for consistent debug logs
class AppLogger {
  static const String _prefix = '[SmartFarm]';
  
  // Category-specific loggers
  static void auth(String message, [Object? error]) {
    _log('AUTH', message, error);
  }
  
  static void dashboard(String message, [Object? error]) {
    _log('DASHBOARD', message, error);
  }
  
  static void api(String message, [Object? error]) {
    _log('API', message, error);
  }
  
  static void reports(String message, [Object? error]) {
    _log('REPORTS', message, error);
  }
  
  static void notifications(String message, [Object? error]) {
    _log('NOTIFICATIONS', message, error);
  }
  
  static void plant(String message, [Object? error]) {
    _log('PLANT', message, error);
  }
  
  static void animal(String message, [Object? error]) {
    _log('ANIMAL', message, error);
  }
  
  static void soil(String message, [Object? error]) {
    _log('SOIL', message, error);
  }
  
  static void crop(String message, [Object? error]) {
    _log('CROP', message, error);
  }
  
  static void fruit(String message, [Object? error]) {
    _log('FRUIT', message, error);
  }
  
  static void chatbot(String message, [Object? error]) {
    _log('CHATBOT', message, error);
  }
  
  static void location(String message, [Object? error]) {
    _log('LOCATION', message, error);
  }
  
  static void error(String message, [Object? error]) {
    _log('ERROR', message, error);
  }
  
  static void warning(String message, [Object? error]) {
    _log('WARNING', message, error);
  }
  
  static void info(String message, [Object? error]) {
    _log('INFO', message, error);
  }
  
  static void _log(String category, String message, [Object? error]) {
    if (!kDebugMode) return;
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logMessage = '$_prefix[$category] $timestamp: $message';
    if (error != null) {
      debugPrint('$logMessage - Error: $error');
    } else {
      debugPrint(logMessage);
    }
  }
}
