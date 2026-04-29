import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
// ignore_for_file: avoid_print

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<AppNotification> _notifications = [];

  // Raw unfiltered list — preserved so filter changes re-apply without a new fetch
  List<AppNotification> _rawNotifications = [];

  FarmerNotificationSettings _farmerSettings =
  const FarmerNotificationSettings();
  AdminNotificationSettings _adminSettings =
  const AdminNotificationSettings();

  // ── ROLE FLAG ──────────────────────────────────────
  // Set this from AuthWrapper / initState so filters know which role to apply.
  bool _isAdmin = false;
  void setIsAdmin(bool value) {
    if (_isAdmin == value) return;
    _isAdmin = value;
    _applyFilters(); // re-apply filters when role changes
  }

  // ✅ Language for UI text direction sync
  String _language = 'ar';
  void setLanguage(String lang) {
    if (_language == lang) return;
    _language = lang;
    notifyListeners();
  }
  String get language => _language;

  bool _isLoading = false;
  bool _isActionLoading = false;
  bool _isSettingsLoading = false;
  String? _error;

  // ── SAFE FETCH CONTROL ─────────────────────────────
  Future<void>? _inFlightFetch;
  DateTime? _lastFetchTime;

  static const _kMinFetchInterval = Duration(seconds: 5);

  // ── GETTERS ────────────────────────────────────────
  List<AppNotification> get notifications => _notifications;
  FarmerNotificationSettings get farmerSettings => _farmerSettings;
  AdminNotificationSettings get adminSettings => _adminSettings;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  bool get isSettingsLoading => _isSettingsLoading;
  String? get error => _error;

  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  // ───────────────────────────────────────────────────
  // CORE FETCH (ANTI DUPLICATE + THROTTLE)
  // ───────────────────────────────────────────────────

  Future<void> fetchNotifications({
    required String userId,
    bool showLoading = true,
    bool force = false,
  }) {
    final now = DateTime.now();

    // ⛔ throttle (prevents spam)
    if (!force &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _kMinFetchInterval) {
      return Future.value();
    }

    // ⛔ prevent duplicate in-flight requests
    if (_inFlightFetch != null) return _inFlightFetch!;

    _inFlightFetch = _runFetch(userId, showLoading).whenComplete(() {
      _inFlightFetch = null;
    });

    return _inFlightFetch!;
  }

  // ───────────────────────────────────────────────────
  // INTERNAL FETCH
  // ───────────────────────────────────────────────────

  Future<void> _runFetch(String userId, bool showLoading) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final results = await _service.getNotifications(userId);

      // Cache raw results so filter changes can re-apply without a new fetch
      _rawNotifications = results;
      _applyFilters();

      _lastFetchTime = DateTime.now();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ───────────────────────────────────────────────────
  // COMPAT
  // ───────────────────────────────────────────────────

  Future<void> fetchNotificationsForUser(String userId) =>
      fetchNotifications(userId: userId, showLoading: false);

  // ───────────────────────────────────────────────────
  // MARK AS READ (OPTIMIZED NOTIFY)
  // ───────────────────────────────────────────────────

  Future<void> markAsRead(String notifId) async {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index == -1 || _notifications[index].isRead) return;

    _isActionLoading = true;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();

    final ok = await _service.markAsRead(notifId);

    _isActionLoading = false;
    if (!ok) {
      _notifications[index] = _notifications[index].copyWith(isRead: false);
    }
    notifyListeners();
  }

  Future<void> markAllAsRead({required String userId}) async {
    if (_notifications.isEmpty) return;

    final previous = List<AppNotification>.from(_notifications);

    _isActionLoading = true;
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    final ok = await _service.markAllAsRead(userId);

    _isActionLoading = false;
    if (!ok) {
      _notifications = previous;
    }
    notifyListeners();
  }

  // ───────────────────────────────────────────────────
  // DELETE (SAFE UI UPDATE)
  // ───────────────────────────────────────────────────

  Future<void> deleteNotification(String notifId) async {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index == -1) return;

    final removed = _notifications.removeAt(index);
    _isActionLoading = true;
    notifyListeners();

    final ok = await _service.deleteNotification(notifId);

    _isActionLoading = false;
    if (!ok) {
      _notifications.insert(index, removed);
    }
    notifyListeners();
  }

  Future<void> deleteAllNotifications({required String userId}) async {
    if (_notifications.isEmpty) return;

    final previous = List<AppNotification>.from(_notifications);

    _isActionLoading = true;
    _notifications = [];
    notifyListeners();

    final ok = await _service.deleteAllNotifications(userId);

    _isActionLoading = false;
    if (!ok) {
      _notifications = previous;
    }
    notifyListeners();
  }

  // ───────────────────────────────────────────────────
  // SETTINGS (NO MULTIPLE NOTIFY FLOOD)
  // ───────────────────────────────────────────────────

  Future<void> fetchFarmerSettings({required String userId}) async {
    _isSettingsLoading = true;
    notifyListeners();

    final result = await _service.getFarmerSettings(userId);
    if (result != null) {
      _farmerSettings = result;
      _applyFilters(); // sync filter to loaded settings
    }

    _isSettingsLoading = false;
    notifyListeners();
  }

  /// Loads admin notification settings from the backend.
  /// Call this from the admin settings page instead of [fetchFarmerSettings].
  Future<void> fetchAdminSettings({required String userId}) async {
    _isSettingsLoading = true;
    notifyListeners();

    final result = await _service.getAdminSettings(userId);
    if (result != null) {
      _adminSettings = result;
    }

    _isSettingsLoading = false;
    notifyListeners();
  }

  Future<bool> updateFarmerSettings({
    required String userId,
    required FarmerNotificationSettings updatedSettings,
  }) async {
    final previous = _farmerSettings;

    _farmerSettings = updatedSettings;
    _applyFilters(); // re-filter in-memory list immediately — no fetch needed

    final ok =
    await _service.updateFarmerSettings(userId, updatedSettings);

    if (!ok) {
      _farmerSettings = previous;
      _applyFilters(); // revert filter to match reverted settings
    }

    return ok;
  }

  Future<bool> updateAdminSettings({
    required String userId,
    required AdminNotificationSettings updatedSettings,
  }) async {
    final previous = _adminSettings;

    _adminSettings = updatedSettings;
    notifyListeners();

    final ok =
    await _service.updateAdminSettings(userId, updatedSettings);

    if (!ok) {
      _adminSettings = previous;
      notifyListeners();
    }

    return ok;
  }

  // ───────────────────────────────────────────────────
  // LOCAL NOTIFICATIONS
  // ───────────────────────────────────────────────────

  void addLocalNotification({
    required String title,
    required String body,
    required NotificationType type,
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'local',
        title: title,
        body: body,
        createdAt: DateTime.now(),
        type: type,
        isRead: false,
      ),
    );

    notifyListeners();
  }

  void addNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.system,
  }) {
    addLocalNotification(
      title: title,
      body: body,
      type: type,
    );
  }

  void addSystemNotification({
    required String title,
    required String body,
  }) {
    addLocalNotification(
      title: title,
      body: body,
      type: NotificationType.system,
    );
  }

  // ───────────────────────────────────────────────────
  // ANALYSIS NOTIFICATION DETECTION
  // ───────────────────────────────────────────────────

  /// Applies current settings to [_rawNotifications] and assigns the result
  /// to [_notifications], then calls [notifyListeners].
  /// Call this whenever settings change OR after a fresh fetch.
  ///
  /// Admin users always see ALL notifications — the analysis-completion filter
  /// is a farmer-only preference and must not affect the admin feed.
  void _applyFilters() {
    // Admin users: no filtering — show everything
    if (_isAdmin) {
      _notifications = List<AppNotification>.from(_rawNotifications)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
      return;
    }

    // Farmer users: apply analysis-completion filter
    var filtered = _rawNotifications;

    if (!_farmerSettings.analysisCompletionAlerts) {
      filtered =
          _rawNotifications.where((n) => !_isAnalysisNotification(n)).toList();
      if (kDebugMode) {
        final removed = _rawNotifications.length - filtered.length;
        print(
            '[NotificationProvider] Analysis notifications filtered: $removed removed');
      }
    }

    _notifications = filtered
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    notifyListeners();
  }

  /// Returns true when a notification was produced by an analysis service
  /// (animal, crop, plant, fruit, soil) so it can be filtered out when the
  /// user disables [FarmerNotificationSettings.analysisCompletionAlerts].
  ///
  /// Detection is title-based because the backend maps all analysis results
  /// to [NotificationType.report] or [NotificationType.system], making the
  /// type field alone insufficient to distinguish them from other notifications.
  bool _isAnalysisNotification(AppNotification n) {
    final title = n.title.toLowerCase();
    final body  = n.body.toLowerCase();

    // ── English keyword matches ────────────────────────
    const englishKeywords = [
      'animal weight',   // animal provider
      'crop recommendation', // crop provider
      'plant disease',   // plant provider
      'plant looks',     // plant provider (healthy variant)
      'fruit quality',   // fruit provider
      'soil analysis',   // soil provider
      // generic terms used across providers
      'weight estimation',
      'recommendation',
      'detection',
      'analysis completed',
      'analysis results',
    ];

    // ── Arabic keyword matches ────────────────────────
    const arabicKeywords = [
      'تحليل وزن الحيوان', // animal
      'توصية المحصول',      // crop
      'اكتشاف مرض',        // plant disease
      'النبات بصحة',        // plant healthy
      'تحليل جودة الفاكهة', // fruit
      'تحليل التربة',       // soil
      'نتائج تحليل',        // generic analysis results
    ];

    for (final kw in englishKeywords) {
      if (title.contains(kw) || body.contains(kw)) return true;
    }
    for (final kw in arabicKeywords) {
      if (title.contains(kw) || body.contains(kw)) return true;
    }

    return false;
  }

  @override
  void dispose() {
    _inFlightFetch = null;
    super.dispose();
  }
}