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
import 'package:smart_farm/features/farmer/providers/chatbot_provider.dart';
import 'package:smart_farm/features/farmer/providers/reports_provider.dart';
import 'package:smart_farm/features/farmer/providers/animal_provider.dart';
import 'package:smart_farm/features/farmer/providers/plant_provider.dart';
import 'package:smart_farm/features/farmer/providers/fruit_provider.dart';
import 'package:smart_farm/features/farmer/providers/soil_provider.dart';
import 'package:smart_farm/features/farmer/providers/crop_provider.dart';
import 'package:smart_farm/features/admin/providers/admin_provider.dart';
import 'package:smart_farm/features/admin/reports/providers/report_provider.dart';
import 'package:smart_farm/features/notifications/providers/notification_provider.dart';
import 'package:smart_farm/features/admin/providers/message_provider.dart';
import 'package:smart_farm/features/farmer/providers/message_provider.dart';
import 'package:smart_farm/features/farmer/providers/dashboard_provider.dart';
import 'package:smart_farm/providers/location_provider.dart';
import 'package:smart_farm/core/utils/app_lifecycle_manager.dart';
import 'package:smart_farm/core/network/token_storage.dart';
import 'package:smart_farm/core/utils/production_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Migrate any legacy tokens from SharedPreferences → flutter_secure_storage.
  await TokenStorage.migrateFromSharedPreferences();

  // Initialize app lifecycle manager
  AppLifecycleManager.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        // Critical providers - loaded immediately
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        // Auth gets NotificationProvider
        ChangeNotifierProxyProvider<NotificationProvider, AuthProvider>(
          create: (_) => AuthProvider(),
          update: (_, notif, auth) => auth!..updateNotificationProvider(notif),
        ),

        // Dashboard gets Auth + Location + Locale (critical for main view)
        ChangeNotifierProxyProvider3<AuthProvider, LocationProvider,
            LocaleProvider, DashboardProvider>(
          create: (_) => DashboardProvider('0'),
          update: (_, auth, loc, locale, dashboard) => dashboard!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateLocation(loc.lat, loc.lon)
            ..updateLocale(locale.locale.languageCode),
        ),

        // Secondary providers - loaded after auth but optimized
        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            ChatbotProvider>(
          create: (_) => ChatbotProvider('0'),
          update: (_, auth, notif, chatbot) => chatbot!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        // Reports gets Auth + Notification
        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            ReportsProvider>(
          create: (_) => ReportsProvider('0'),
          update: (_, auth, notif, reports) => reports!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        // Message providers
        ChangeNotifierProxyProvider<NotificationProvider,
            FarmerMessageProvider>(
          create: (_) => FarmerMessageProvider(),
          update: (_, notif, msg) => msg!..updateNotifProvider(notif),
        ),

        // Service providers - lazy loaded when needed
        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            AnimalProvider>(
          create: (_) => AnimalProvider('0'),
          update: (_, auth, notif, animal) => animal!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            PlantProvider>(
          create: (_) => PlantProvider('0'),
          update: (_, auth, notif, plant) => plant!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            FruitProvider>(
          create: (_) => FruitProvider('0'),
          update: (_, auth, notif, fruit) => fruit!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            SoilProvider>(
          create: (_) => SoilProvider('0'),
          update: (_, auth, notif, soil) => soil!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            CropProvider>(
          create: (_) => CropProvider('0'),
          update: (_, auth, notif, crop) => crop!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        // Admin providers
        ChangeNotifierProvider(create: (_) => AdminReportProvider()),
        ChangeNotifierProxyProvider3<AuthProvider, NotificationProvider,
            LocaleProvider, AdminProvider>(
          create: (_) => AdminProvider(),
          update: (_, auth, notif, locale, admin) {
            ProductionLogger.info('Updating AdminProvider');
            return admin!
              ..updateUserId(auth.currentUser?.id ?? '0')
              ..updateNotif(notif)
              ..updateLocale(locale.locale.languageCode);
          },
        ),

        ChangeNotifierProxyProvider<AdminProvider, AdminMessageProvider>(
          create: (_) => AdminMessageProvider(),
          update: (_, admin, msg) => msg!..updateAdminProv(admin),
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
