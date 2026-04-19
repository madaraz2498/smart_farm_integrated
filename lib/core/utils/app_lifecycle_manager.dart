import 'package:flutter/widgets.dart';
import '../utils/production_logger.dart';

/// App lifecycle manager to handle refresh when app is resumed
class AppLifecycleManager extends WidgetsBindingObserver {
  static AppLifecycleManager? _instance;
  static AppLifecycleManager get instance => _instance ??= AppLifecycleManager._();
  
  AppLifecycleManager._();
  
  final List<VoidCallback> _onResumeCallbacks = [];
  final List<VoidCallback> _onPauseCallbacks = [];
  final List<VoidCallback> _onInactiveCallbacks = [];
  
  bool _isInitialized = false;
  AppLifecycleState? _lastState;

  /// Initialize the lifecycle manager
  void initialize() {
    if (_isInitialized) return;
    
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    ProductionLogger.info('App lifecycle manager initialized');
  }

  /// Dispose the lifecycle manager
  void dispose() {
    if (!_isInitialized) return;
    
    WidgetsBinding.instance.removeObserver(this);
    _onResumeCallbacks.clear();
    _onPauseCallbacks.clear();
    _onInactiveCallbacks.clear();
    _isInitialized = false;
    ProductionLogger.info('App lifecycle manager disposed');
  }

  /// Add callback for app resume
  void addOnResumeCallback(VoidCallback callback) {
    _onResumeCallbacks.add(callback);
    ProductionLogger.info('Added resume callback (${_onResumeCallbacks.length} total)');
  }

  /// Add callback for app pause
  void addOnPauseCallback(VoidCallback callback) {
    _onPauseCallbacks.add(callback);
    ProductionLogger.info('Added pause callback (${_onPauseCallbacks.length} total)');
  }

  /// Add callback for app inactive
  void addOnInactiveCallback(VoidCallback callback) {
    _onInactiveCallbacks.add(callback);
    ProductionLogger.info('Added inactive callback (${_onInactiveCallbacks.length} total)');
  }

  /// Remove a specific callback
  void removeCallback(VoidCallback callback) {
    _onResumeCallbacks.remove(callback);
    _onPauseCallbacks.remove(callback);
    _onInactiveCallbacks.remove(callback);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    ProductionLogger.info('App lifecycle state changed: $_lastState -> $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        _handleResumed();
        break;
      case AppLifecycleState.paused:
        _handlePaused();
        break;
      case AppLifecycleState.inactive:
        _handleInactive();
        break;
      case AppLifecycleState.detached:
        _handleDetached();
        break;
      case AppLifecycleState.hidden:
        _handleHidden();
        break;
    }
    
    _lastState = state;
  }

  void _handleResumed() {
    ProductionLogger.info('App resumed - executing ${_onResumeCallbacks.length} callbacks');
    
    for (final callback in _onResumeCallbacks) {
      try {
        callback();
      } catch (e) {
        ProductionLogger.error('Error in resume callback: $e');
      }
    }
  }

  void _handlePaused() {
    ProductionLogger.info('App paused - executing ${_onPauseCallbacks.length} callbacks');
    
    for (final callback in _onPauseCallbacks) {
      try {
        callback();
      } catch (e) {
        ProductionLogger.error('Error in pause callback: $e');
      }
    }
  }

  void _handleInactive() {
    ProductionLogger.info('App inactive - executing ${_onInactiveCallbacks.length} callbacks');
    
    for (final callback in _onInactiveCallbacks) {
      try {
        callback();
      } catch (e) {
        ProductionLogger.error('Error in inactive callback: $e');
      }
    }
  }

  void _handleDetached() {
    ProductionLogger.info('App detached');
    // Clean up resources when app is completely detached
    dispose();
  }

  void _handleHidden() {
    ProductionLogger.info('App hidden');
    // Handle app being hidden (similar to inactive)
    _handleInactive();
  }

  /// Check if app is currently in foreground
  bool get isAppInForeground => _lastState == AppLifecycleState.resumed;
  
  /// Check if app is currently in background
  bool get isAppInBackground => 
      _lastState == AppLifecycleState.paused || 
      _lastState == AppLifecycleState.hidden ||
      _lastState == AppLifecycleState.inactive;
}
