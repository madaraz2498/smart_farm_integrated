// lib/features/auth/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  @override
  void initState() {
    super.initState();
    // Request location on first startup to get city & coords
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().requestLocation(force: false);
    });
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
