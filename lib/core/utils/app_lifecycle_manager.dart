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


// ═══════════════════════════════════════════════════════════════════════════════
// ██████████████████████  AppBootstrapController  ██████████████████████████████
// ═══════════════════════════════════════════════════════════════════════════════
//
// Central startup gate that ensures ONLY auth/session runs at app launch.
// All other modules are locked until their screen explicitly unlocks them.
//
// Usage:
//   AppBootstrapController.instance.unlockDashboard();
//   AppBootstrapController.instance.isModuleUnlocked('dashboard');
// ═══════════════════════════════════════════════════════════════════════════════

/// Controls which data modules are allowed to load.
///
/// ┌─────────────────────────────────────────────────────┐
/// │ App Startup: ONLY auth is unlocked.                 │
/// │ Navigation: each screen calls unlock for its module │
/// │ Providers: check isModuleUnlocked() before loading  │
/// └─────────────────────────────────────────────────────┘
class AppBootstrapController {
  AppBootstrapController._();
  static final AppBootstrapController instance = AppBootstrapController._();

  // ── Module unlock registry ────────────────────────────────────────────────
  final Set<String> _unlockedModules = {};

  // Module name constants — use these everywhere to avoid magic strings.
  static const String kAuth          = 'auth';
  static const String kDashboard     = 'dashboard';
  static const String kReports       = 'reports';
  static const String kMessages      = 'messages';
  static const String kNotifications = 'notifications';
  static const String kAdmin         = 'admin';
  static const String kAdminReports  = 'admin_reports';
  static const String kAdminMessages = 'admin_messages';
  static const String kSystem        = 'system';
  static const String kChatbot       = 'chatbot';
  static const String kSettings      = 'settings';

  // ── Listeners ─────────────────────────────────────────────────────────────
  final Map<String, List<VoidCallback>> _unlockListeners = {};

  /// Called once at app start — only auth is pre-unlocked.
  void initForStartup() {
    _unlockedModules.clear();
    _unlockedModules.add(kAuth);
    ProductionLogger.info('[Bootstrap] Startup gate initialized — only auth unlocked');
  }

  /// Reset all unlocks (call on logout).
  void reset() {
    _unlockedModules
      ..clear()
      ..add(kAuth);
    _unlockListeners.clear();
    ProductionLogger.info('[Bootstrap] Gate reset — all modules re-locked');
  }

  /// Returns true if [module] is allowed to load data.
  bool isModuleUnlocked(String module) => _unlockedModules.contains(module);

  // ── Unlock helpers (called by screens in initState) ───────────────────────

  void unlockDashboard()    => _unlock(kDashboard);
  void unlockReports()      => _unlock(kReports);
  void unlockMessages()     => _unlock(kMessages);
  void unlockNotifications() => _unlock(kNotifications);
  void unlockAdminModule()  => _unlock(kAdmin);
  void unlockAdminReports() => _unlock(kAdminReports);
  void unlockAdminMessages() => _unlock(kAdminMessages);
  void unlockSystemModule() => _unlock(kSystem);
  void unlockChatbot()      => _unlock(kChatbot);
  void unlockSettings()     => _unlock(kSettings);

  void _unlock(String module) {
    if (_unlockedModules.add(module)) {
      ProductionLogger.info('[Bootstrap] Module unlocked: $module');
      _notifyListeners(module);
    }
  }

  /// Register a callback to be called when [module] is unlocked.
  /// If already unlocked, the callback fires immediately.
  void onUnlock(String module, VoidCallback callback) {
    if (_unlockedModules.contains(module)) {
      callback();
      return;
    }
    _unlockListeners.putIfAbsent(module, () => []).add(callback);
  }

  void _notifyListeners(String module) {
    final listeners = _unlockListeners.remove(module);
    if (listeners == null) return;
    for (final cb in listeners) {
      try { cb(); } catch (e) {
        ProductionLogger.error('[Bootstrap] Unlock listener error: $e');
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ██████████████████████  PageLifecycleManager  ████████████████████████████████
// ═══════════════════════════════════════════════════════════════════════════════
//
// Tracks which page is currently active. Providers can query this to decide
// whether to load data. Screens call enter/exit in initState/dispose.
// ═══════════════════════════════════════════════════════════════════════════════

class PageLifecycleManager {
  PageLifecycleManager._();
  static final PageLifecycleManager instance = PageLifecycleManager._();

  final Set<String> _activePages = {};

  /// Call from a page's initState (via addPostFrameCallback).
  void onPageEnter(String pageId) {
    _activePages.add(pageId);
    ProductionLogger.info('[PageLifecycle] Enter: $pageId (active: $_activePages)');
  }

  /// Call from a page's dispose.
  void onPageExit(String pageId) {
    _activePages.remove(pageId);
    ProductionLogger.info('[PageLifecycle] Exit: $pageId (active: $_activePages)');
  }

  /// Returns true if the page is currently mounted and visible.
  bool isPageActive(String pageId) => _activePages.contains(pageId);

  // Page ID constants
  static const String kFarmerDashboard = 'farmer_dashboard';
  static const String kFarmerReports   = 'farmer_reports';
  static const String kFarmerMessages  = 'farmer_messages';
  static const String kFarmerSettings  = 'farmer_settings';
  static const String kChatbot         = 'chatbot';
  static const String kAdminDashboard  = 'admin_dashboard';
  static const String kAdminUsers      = 'admin_users';
  static const String kAdminSystem     = 'admin_system';
  static const String kAdminReports    = 'admin_reports';
  static const String kAdminMessages   = 'admin_messages';
  static const String kAdminSettings   = 'admin_settings';
  static const String kNotifications   = 'notifications';
}

// ═══════════════════════════════════════════════════════════════════════════════
// ██████████████████████  RequestDeduplicator  █████████████████████████████████
// ═══════════════════════════════════════════════════════════════════════════════
//
// Thin facade over RequestCache that merges concurrent calls to the same
// endpoint into ONE in-flight Future. Zero duplicate requests.
// ═══════════════════════════════════════════════════════════════════════════════

/// Merges concurrent identical API calls into a single in-flight Future.
///
/// Example:
///   final data = await RequestDeduplicator.instance.execute(
///     key: 'dashboard_\$userId',
///     fetcher: () => _svc.getDashboardData(userId),
///   );
class RequestDeduplicator {
  RequestDeduplicator._();
  static final RequestDeduplicator instance = RequestDeduplicator._();

  final Map<String, Future<dynamic>> _inFlight = {};
  final Map<String, _SessionCache>   _cache    = {};

  /// Default per-session cache TTL — data stays fresh for 5 minutes.
  static const _kCacheTtl = Duration(minutes: 5);

  /// Execute [fetcher] for [key], deduplicating concurrent calls.
  ///
  /// - Concurrent callers get the same Future — one HTTP request total.
  /// - Result is cached for [cacheTtl] (default 5 min).
  /// - Pass [force] = true to bypass cache and start a fresh request.
  Future<T> execute<T>({
    required String key,
    required Future<T> Function() fetcher,
    Duration cacheTtl = _kCacheTtl,
    bool force = false,
  }) {
    // 1. Serve from cache if fresh and not forced.
    if (!force && _cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (!cached.isExpired(cacheTtl)) {
        ProductionLogger.info('[Dedup] Cache hit: $key');
        return Future.value(cached.value as T);
      }
    }

    // 2. Join an existing in-flight request.
    if (_inFlight.containsKey(key)) {
      ProductionLogger.info('[Dedup] Joining in-flight: $key');
      return _inFlight[key]!.then((v) => v as T);
    }

    // 3. Launch new request, cache the Future so concurrent callers join it.
    ProductionLogger.info('[Dedup] New request: $key');
    final future = fetcher().then((result) {
      _cache[key] = _SessionCache(result);
      _inFlight.remove(key);
      return result;
    }).catchError((e) {
      _inFlight.remove(key);
      throw e;
    });

    _inFlight[key] = future;
    return future;
  }

  /// Invalidate a cached result so the next call fetches fresh data.
  void invalidate(String key) {
    _cache.remove(key);
    ProductionLogger.info('[Dedup] Invalidated: $key');
  }

  /// Clear everything on logout.
  void clearAll() {
    _cache.clear();
    _inFlight.clear();
    ProductionLogger.info('[Dedup] Cache cleared');
  }
}

class _SessionCache {
  final dynamic value;
  final DateTime cachedAt = DateTime.now();
  _SessionCache(this.value);
  bool isExpired(Duration ttl) => DateTime.now().difference(cachedAt) > ttl;
}