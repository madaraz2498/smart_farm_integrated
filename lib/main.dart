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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),

        // Auth — gets NotificationProvider
        ChangeNotifierProxyProvider<NotificationProvider, AuthProvider>(
          create: (_) => AuthProvider(),
          update: (_, notif, auth) => auth!..updateNotificationProvider(notif),
        ),

        // Chatbot — gets Auth + Notification
        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            ChatbotProvider>(
          create: (_) => ChatbotProvider('0'),
          update: (_, auth, notif, chatbot) => chatbot!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        // Reports — gets Auth + Notification
        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            ReportsProvider>(
          create: (_) => ReportsProvider('0'),
          update: (_, auth, notif, reports) => reports!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        // Animal — gets Auth + Notification
        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            AnimalProvider>(
          create: (_) => AnimalProvider('0'),
          update: (_, auth, notif, animal) => animal!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        // Plant — gets Auth + Notification
        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            PlantProvider>(
          create: (_) => PlantProvider('0'),
          update: (_, auth, notif, plant) => plant!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        // Fruit — gets Auth + Notification
        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            FruitProvider>(
          create: (_) => FruitProvider('0'),
          update: (_, auth, notif, fruit) => fruit!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        // Soil — gets Auth + Notification
        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            SoilProvider>(
          create: (_) => SoilProvider('0'),
          update: (_, auth, notif, soil) => soil!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        // Crop — gets Auth + Notification
        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            CropProvider>(
          create: (_) => CropProvider('0'),
          update: (_, auth, notif, crop) => crop!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateNotifProvider(notif),
        ),

        ChangeNotifierProvider(create: (_) => AdminReportProvider()),

        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            AdminProvider>(
          create: (_) => AdminProvider(),
          update: (_, auth, notif, admin) {
            debugPrint(
                '[Main] Updating AdminProvider with NotificationProvider');
            return admin!
              ..updateUserId(auth.currentUser?.id ?? '0')
              ..updateNotif(notif);
          },
        ),

        ChangeNotifierProxyProvider<AdminProvider, AdminMessageProvider>(
          create: (_) => AdminMessageProvider(),
          update: (_, admin, msg) => msg!..updateAdminProv(admin),
        ),

        // FarmerMessageProvider — gets NotificationProvider
        ChangeNotifierProxyProvider<NotificationProvider,
            FarmerMessageProvider>(
          create: (_) => FarmerMessageProvider(),
          update: (_, notif, msg) => msg!..updateNotifProvider(notif),
        ),

        // Dashboard — gets Auth + Location + Locale
        ChangeNotifierProxyProvider3<AuthProvider, LocationProvider,
            LocaleProvider, DashboardProvider>(
          create: (_) => DashboardProvider('0'),
          update: (_, auth, loc, locale, dashboard) => dashboard!
            ..updateUserId(auth.currentUser?.id ?? '0')
            ..updateLocation(loc.lat, loc.lon)
            ..updateLocale(locale.locale.languageCode),
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
