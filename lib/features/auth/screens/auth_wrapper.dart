// lib/features/auth/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/features/notifications/providers/notification_provider.dart';
import 'package:smart_farm/providers/locale_provider.dart';
import '../providers/auth_provider.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final status = context.watch<AuthProvider>().status;

    if (status == AuthStatus.authenticated && _lastStatus != AuthStatus.authenticated) {
      // Guard: only schedule once per login transition to avoid duplicate fetches
      if (!_authCallbackScheduled) {
        _authCallbackScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _onAuthenticated());
      }
    } else if (status == AuthStatus.unauthenticated && _lastStatus == AuthStatus.authenticated) {
      _authCallbackScheduled = false;
      context.read<NotificationProvider>().stopRefreshTimer();
    }
    _lastStatus = status;
  }

  Future<void> _onAuthenticated() async {
    if (!mounted) return;
    _authCallbackScheduled = false;
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    final notifProvider = context.read<NotificationProvider>();

    // ✅ Sync language so translations work immediately after login
    final lang = context.read<LocaleProvider>().locale.languageCode;
    notifProvider.setLanguage(lang);

    // Role filter: admin sees all, farmer applies analysis filter
    notifProvider.setIsAdmin(authProvider.isAdmin);

    notifProvider.fetchNotifications(userId: userId);
    notifProvider.startRefreshTimer(userId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // ✅ Keep language in sync when user changes locale in settings
    final lang = context.watch<LocaleProvider>().locale.languageCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().setLanguage(lang);
    });
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