// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:smart_farm/core/theme/app_theme.dart';
import 'package:smart_farm/core/theme/theme_provider.dart';
import 'package:smart_farm/features/auth/providers/auth_provider.dart';
import 'package:smart_farm/features/auth/screens/auth_wrapper.dart';
import 'package:smart_farm/l10n/app_localizations.dart';
import 'package:smart_farm/providers/navigation_provider.dart';
import 'package:smart_farm/providers/locale_provider.dart';
import 'package:smart_farm/features/chatbot/providers/chatbot_provider.dart';
import 'package:smart_farm/features/reports/providers/reports_provider.dart';
import 'package:smart_farm/features/animals/providers/animal_provider.dart';
import 'package:smart_farm/features/plants/providers/plant_provider.dart';
import 'package:smart_farm/features/fruits/providers/fruit_provider.dart';
import 'package:smart_farm/features/soil/providers/soil_provider.dart';
import 'package:smart_farm/features/crops/providers/crop_provider.dart';
import 'package:smart_farm/features/admin/providers/admin_provider.dart';
import 'package:smart_farm/features/admin/reports/providers/report_provider.dart';
import 'package:smart_farm/features/notifications/providers/notification_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProxyProvider<NotificationProvider, AuthProvider>(
          create: (_) => AuthProvider(),
          update: (_, notif, auth) => auth!..updateNotif(notif),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChatbotProvider>(
          create: (_) => ChatbotProvider('0'),
          update: (_, auth, chatbot) =>
              chatbot!..updateUserId(auth.currentUser?.id ?? '0'),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ReportsProvider>(
          create: (_) => ReportsProvider('0'),
          update: (_, auth, reports) =>
              reports!..updateUserId(auth.currentUser?.id ?? '0'),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AnimalProvider>(
          create: (_) => AnimalProvider('0'),
          update: (_, auth, animal) =>
              animal!..updateUserId(auth.currentUser?.id ?? '0'),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PlantProvider>(
          create: (_) => PlantProvider('0'),
          update: (_, auth, plant) =>
              plant!..updateUserId(auth.currentUser?.id ?? '0'),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FruitProvider>(
          create: (_) => FruitProvider('0'),
          update: (_, auth, fruit) =>
              fruit!..updateUserId(auth.currentUser?.id ?? '0'),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SoilProvider>(
          create: (_) => SoilProvider('0'),
          update: (_, auth, soil) =>
              soil!..updateUserId(auth.currentUser?.id ?? '0'),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CropProvider>(
          create: (_) => CropProvider('0'),
          update: (_, auth, crop) =>
              crop!..updateUserId(auth.currentUser?.id ?? '0'),
        ),
        ChangeNotifierProvider(create: (_) => AdminReportProvider()),
        ChangeNotifierProxyProvider<NotificationProvider, AdminProvider>(
          create: (_) => AdminProvider(),
          update: (_, notif, admin) => admin!..updateNotif(notif),
        ),
      ],
      child: const SmartFarmApp(),
    ),
  );
}

class SmartFarmApp extends StatelessWidget {
  const SmartFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Smart Farm AI',
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthWrapper(),
    );
  }
}
