// lib/features/auth/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/features/notifications/providers/notification_provider.dart';
import 'package:smart_farm/providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/utils/app_lifecycle_manager.dart'; // AppBootstrapController, PageLifecycleManager
import 'login_screen.dart';
import '../../../widgets/shared/main_layout.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AuthStatus? _lastStatus;
  bool _authCallbackScheduled = false;

  @override
  void initState() {
    super.initState();
    // LocationProvider._init() runs automatically on construction and handles
    // loading the persisted location + scheduling a background GPS refresh.
    // No explicit call needed here.
  }

  String? _lastLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final status = context.watch<AuthProvider>().status;
    final lang = context.read<LocaleProvider>().locale.languageCode;

    if (status == AuthStatus.authenticated && _lastStatus != AuthStatus.authenticated) {
      if (!_authCallbackScheduled) {
        _authCallbackScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _onAuthenticated());
      }
    } else if (status == AuthStatus.unauthenticated && _lastStatus == AuthStatus.authenticated) {
      _authCallbackScheduled = false;
      // Re-lock all modules so the next login starts clean.
      AppBootstrapController.instance.reset();
    }
    _lastStatus = status;

    if (_lastLanguage != lang) {
      _lastLanguage = lang;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<NotificationProvider>().setLanguage(lang);
      });
    }
  }

  Future<void> _onAuthenticated() async {
    if (!mounted) return;
    _authCallbackScheduled = false;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    final notifProvider = context.read<NotificationProvider>();

    // Sync language and role filter immediately — these are pure in-memory ops,
    // no API involved.
    final lang = context.read<LocaleProvider>().locale.languageCode;
    notifProvider.setLanguage(lang);
    notifProvider.setIsAdmin(authProvider.isAdmin);

    // ── Bootstrap unlock (admin unlocks admin module) ─────────────────────
    final boot = AppBootstrapController.instance;
    if (authProvider.isAdmin) {
      boot.unlockAdminModule();
    }

    // ── Notifications: unlock but do NOT fetch immediately ────────────────
    // The top-bar bell icon and NotificationsScreen call fetchNotifications
    // on demand (lazy). No polling timer — prevents excessive API calls.
    boot.unlockNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return switch (auth.status) {
      AuthStatus.unknown => const Scaffold(
          body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading…',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                ],
              ))),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.authenticated => const MainLayout(),
    };
  }
}