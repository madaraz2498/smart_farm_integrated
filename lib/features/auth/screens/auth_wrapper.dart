// lib/features/auth/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/features/notifications/providers/notification_provider.dart';
import 'package:smart_farm/providers/location_provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().requestLocation(force: false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final status = context.watch<AuthProvider>().status;
    
    if (status == AuthStatus.authenticated && _lastStatus != AuthStatus.authenticated) {
      // Schedule the authentication logic after the current build frame
      // to avoid "setState() or markNeedsBuild() called during build" error.
      WidgetsBinding.instance.addPostFrameCallback((_) => _onAuthenticated());
    } else if (status == AuthStatus.unauthenticated && _lastStatus == AuthStatus.authenticated) {
      context.read<NotificationProvider>().stopRefreshTimer();
    }
    _lastStatus = status;
  }

  Future<void> _onAuthenticated() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    // Refresh GPS location after login so weather uses current coordinates.
    await context.read<LocationProvider>().requestLocation(force: true);
    if (!mounted) return;

    final notifProvider = context.read<NotificationProvider>();
    notifProvider.fetchNotifications(userId);
    notifProvider.startRefreshTimer(userId);
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