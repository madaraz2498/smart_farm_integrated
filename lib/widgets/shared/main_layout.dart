// lib/widgets/shared/main_layout.dart
// Persistent shell — sidebar + topbar stay fixed, only IndexedStack body swaps.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../shared/theme/app_theme.dart';

// ── Farmer pages ──────────────────────────────────────────────────────────────
import '../../features/home/screens/farmer_welcome_screen.dart';
import '../../features/home/screens/farmer_settings_screen.dart';
import '../../features/plants/screens/plant_disease_screen.dart';
import '../../features/animals/screens/animal_weight_screen.dart';
import '../../features/crops/screens/crop_recommendation_screen.dart';
import '../../features/soil/screens/soil_analysis_screen.dart';
import '../../features/fruits/screens/fruit_quality_screen.dart';
import '../../features/chatbot/screens/chatbot_screen.dart';
import '../../features/reports/screens/reports_screen.dart';

// ── Admin pages ───────────────────────────────────────────────────────────────
import '../../features/admin/pages/admin_dashboard_page.dart';
import '../../features/admin/pages/user_management_page.dart';
import '../../features/admin/pages/system_management_page.dart';
import '../../features/admin/pages/admin_settings_page.dart';
import '../../features/admin/reports/screens/admin_reports_screen.dart';
import '../../features/admin/providers/admin_provider.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/admin/pages/messages_page.dart' as admin;
import '../../features/farmer/pages/messages_page.dart' as farmer;

// ── Shared shell widgets ──────────────────────────────────────────────────────
import 'app_sidebar.dart';
import 'app_top_bar.dart';

// Page registries — order must match enum order in NavigationProvider
const List<Widget> _farmerPages = [
  FarmerWelcomeScreen(), // FarmerPage.welcome
  PlantDiseaseScreen(), // FarmerPage.plantDisease
  AnimalWeightScreen(), // FarmerPage.animalWeight
  CropRecommendationScreen(), // FarmerPage.cropRecommendation
  SoilAnalysisScreen(), // FarmerPage.soilAnalysis
  FruitQualityScreen(), // FarmerPage.fruitQuality
  ChatbotScreen(), // FarmerPage.chatbot
  farmer.FarmerMessagesPage(), // FarmerPage.messages
  ReportsScreen(), // FarmerPage.reports
  FarmerSettingsScreen(), // FarmerPage.settings
];

const List<Widget> _adminPages = [
  AdminDashboardPage(), // AdminPage.dashboard
  UserManagementPage(), // AdminPage.userManagement
  SystemManagementPage(), // AdminPage.systemManagement
  AdminReportsScreen(), // AdminPage.systemReports (Replaced SystemReportsPage)
  admin.AdminMessagesPage(), // AdminPage.messages
  AdminSettingsPage(), // AdminPage.settings
  ProfilePage(), // AdminPage.profile
];

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final nav = context.watch<NavigationProvider>();
    final isWide = MediaQuery.of(context).size.width > AppSizes.wideBreak;

    if (isAdmin) {
      return ChangeNotifierProvider(
        create: (_) => AdminProvider(),
        child: _Shell(
            isWide: isWide, pageIndex: nav.adminIndex, pages: _adminPages),
      );
    }
    return _Shell(
        isWide: isWide, pageIndex: nav.farmerIndex, pages: _farmerPages);
  }
}

class _Shell extends StatelessWidget {
  const _Shell(
      {required this.isWide, required this.pageIndex, required this.pages});
  final bool isWide;
  final int pageIndex;
  final List<Widget> pages;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isWide ? null : AppSidebar.asDrawer(),
      body: SafeArea(
          child: Column(children: [
        AppTopBar(showBurger: !isWide),
        Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (isWide) const AppSidebar(),
          Expanded(child: IndexedStack(index: pageIndex, children: pages)),
        ])),
      ])),
    );
  }
}
