// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/auth_wrapper.dart';
import 'providers/navigation_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const SmartFarmApp(),
    ),
  );
}

class SmartFarmApp extends StatelessWidget {
  const SmartFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                     'Smart Farm AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily:              'Inter',
        colorScheme:             ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
        useMaterial3:            true,
        scaffoldBackgroundColor: const Color(0xFFFAFBF7),
      ),
      home: const AuthWrapper(),
    );
  }
}
