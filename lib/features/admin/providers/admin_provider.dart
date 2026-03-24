import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _svc = AdminService.instance;

  // ── Stats ─────────────────────────────────────────────────────────────────
  DashboardStats? _stats;
  bool            _statsLoading = false;
  String?         _statsError;

  DashboardStats? get stats        => _stats;
  bool            get statsLoading => _statsLoading;
  String?         get statsError   => _statsError;

  // ── Users ─────────────────────────────────────────────────────────────────
  List<AdminUser> _users        = [];
  bool            _usersLoading = false;
  String?         _usersError;

  List<AdminUser> get users        => List.unmodifiable(_users);
  bool            get usersLoading => _usersLoading;
  String?         get usersError   => _usersError;

  // ── Load stats ─────────────────────────────────────────────────────────────
  Future<void> loadStats({bool force = false}) async {
    if (_stats != null && !force) return;
    _statsLoading = true; _statsError = null; notifyListeners();
    try {
      _stats = await _svc.getDashboardStats();
    } on ApiException catch (e) {
      _statsError = e.message;
    } catch (_) {
      _statsError = 'Failed to load statistics.';
    } finally {
      _statsLoading = false; notifyListeners();
    }
  }

  // ── Load users ─────────────────────────────────────────────────────────────
  Future<void> loadUsers({bool force = false}) async {
    if (_users.isNotEmpty && !force) return;
    _usersLoading = true; _usersError = null; notifyListeners();
    try {
      final data = await _svc.getUsersAndSummary();
      _users = data.users;
    } on ApiException catch (e) {
      _usersError = e.message;
    } catch (_) {
      _usersError = 'Failed to load users.';
    } finally {
      _usersLoading = false; notifyListeners();
    }
  }

  // ── User actions ───────────────────────────────────────────────────────────
  Future<bool> deleteUser(String userId) async {
    try {
      await _svc.deleteUser(userId);
      _users.removeWhere((u) => u.id == userId);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _usersError = e.message; notifyListeners(); return false;
    }
  }

  Future<bool> deactivateUser(String userId) async => _toggleActive(userId, false);
  Future<bool> activateUser(String userId)   async => _toggleActive(userId, true);

  Future<bool> _toggleActive(String userId, bool active) async {
    try {
      if (active) await _svc.activateUser(userId);
      else        await _svc.deactivateUser(userId);
      final i = _users.indexWhere((u) => u.id == userId);
      if (i != -1) _users[i] = _users[i].copyWith(isActive: active);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _usersError = e.message; notifyListeners(); return false;
    }
  }

  Future<bool> promoteToAdmin(String userId) async {
    try {
      await _svc.promoteToAdmin(userId);
      await loadUsers(force: true);
      return true;
    } on ApiException catch (e) {
      _usersError = e.message; notifyListeners(); return false;
    }
  }

  // ── Refresh all ────────────────────────────────────────────────────────────
  Future<void> refreshAll() async {
    await Future.wait([loadStats(force: true), loadUsers(force: true)]);
  }

  void clearErrors() { _statsError = null; _usersError = null; notifyListeners(); }
}
