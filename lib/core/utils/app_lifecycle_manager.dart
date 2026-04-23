import 'dart:async';
import 'package:flutter/widgets.dart';
import '../utils/production_logger.dart';

/// App lifecycle manager to handle refresh when app is resumed.
///
/// FIXES applied:
/// - Resume callbacks are debounced (500 ms) so rapid inactive→resumed
///   transitions (e.g. permission dialogs) only fire once.
/// - A minimum gap of 30 seconds is enforced between resume-triggered
///   refreshes, preventing full data reloads every time the user briefly
///   switches away and returns.
class AppLifecycleManager extends WidgetsBindingObserver {
  static AppLifecycleManager? _instance;
  static AppLifecycleManager get instance =>
      _instance ??= AppLifecycleManager._();

  AppLifecycleManager._();

  final List<VoidCallback> _onResumeCallbacks = [];
  final List<VoidCallback> _onPauseCallbacks = [];
  final List<VoidCallback> _onInactiveCallbacks = [];

  bool _isInitialized = false;
  AppLifecycleState? _lastState;

  // ── Resume debounce & gap guard ────────────────────────────────────────────
  Timer? _resumeDebounce;
  DateTime? _lastResumeExecution;
  // Minimum wall-clock time between full resume-triggered refreshes.
  static const _kMinResumeGap = Duration(seconds: 30);
  // Debounce window to collapse rapid lifecycle transitions.
  static const _kResumeDebounce = Duration(milliseconds: 500);

  void initialize() {
    if (_isInitialized) return;
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    ProductionLogger.info('App lifecycle manager initialized');
  }

  void dispose() {
    if (!_isInitialized) return;
    _resumeDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _onResumeCallbacks.clear();
    _onPauseCallbacks.clear();
    _onInactiveCallbacks.clear();
    _isInitialized = false;
    ProductionLogger.info('App lifecycle manager disposed');
  }

  void addOnResumeCallback(VoidCallback callback) {
    _onResumeCallbacks.add(callback);
    ProductionLogger.info(
        'Added resume callback (${_onResumeCallbacks.length} total)');
  }

  void addOnPauseCallback(VoidCallback callback) {
    _onPauseCallbacks.add(callback);
    ProductionLogger.info(
        'Added pause callback (${_onPauseCallbacks.length} total)');
  }

  void addOnInactiveCallback(VoidCallback callback) {
    _onInactiveCallbacks.add(callback);
    ProductionLogger.info(
        'Added inactive callback (${_onInactiveCallbacks.length} total)');
  }

  void removeCallback(VoidCallback callback) {
    _onResumeCallbacks.remove(callback);
    _onPauseCallbacks.remove(callback);
    _onInactiveCallbacks.remove(callback);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    ProductionLogger.info(
        'App lifecycle state changed: $_lastState -> $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _scheduleResumed();
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

  // ── Debounced resume ───────────────────────────────────────────────────────

  void _scheduleResumed() {
    // Cancel any previously scheduled (but not yet fired) resume callback.
    _resumeDebounce?.cancel();
    _resumeDebounce = Timer(_kResumeDebounce, _handleResumed);
  }

  void _handleResumed() {
    final now = DateTime.now();

    // If the app returned from background less than [_kMinResumeGap] ago,
    // skip the refresh — the user only briefly switched context.
    if (_lastResumeExecution != null &&
        now.difference(_lastResumeExecution!) < _kMinResumeGap) {
      ProductionLogger.info(
          'App resumed but within minimum gap (${_kMinResumeGap.inSeconds}s) — skipping refresh callbacks');
      return;
    }

    _lastResumeExecution = now;
    ProductionLogger.info(
        'App resumed — executing ${_onResumeCallbacks.length} callbacks');

    for (final callback in List<VoidCallback>.from(_onResumeCallbacks)) {
      try {
        callback();
      } catch (e) {
        ProductionLogger.error('Error in resume callback: $e');
      }
    }
  }

  void _handlePaused() {
    ProductionLogger.info(
        'App paused — executing ${_onPauseCallbacks.length} callbacks');
    for (final callback in List<VoidCallback>.from(_onPauseCallbacks)) {
      try {
        callback();
      } catch (e) {
        ProductionLogger.error('Error in pause callback: $e');
      }
    }
  }

  void _handleInactive() {
    ProductionLogger.info(
        'App inactive — executing ${_onInactiveCallbacks.length} callbacks');
    for (final callback in List<VoidCallback>.from(_onInactiveCallbacks)) {
      try {
        callback();
      } catch (e) {
        ProductionLogger.error('Error in inactive callback: $e');
      }
    }
  }

  void _handleDetached() {
    ProductionLogger.info('App detached');
    dispose();
  }

  void _handleHidden() {
    ProductionLogger.info('App hidden');
    _handleInactive();
  }

  bool get isAppInForeground => _lastState == AppLifecycleState.resumed;
  bool get isAppInBackground =>
      _lastState == AppLifecycleState.paused ||
      _lastState == AppLifecycleState.hidden ||
      _lastState == AppLifecycleState.inactive;
}
