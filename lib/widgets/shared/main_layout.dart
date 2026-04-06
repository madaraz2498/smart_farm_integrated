// lib/widgets/shared/main_layout.dart
// Persistent shell — sidebar + topbar stay fixed, only IndexedStack body swaps.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../shared/theme/app_theme.dart';

// ── Farmer pages ──────────────────────────────────────────────────────────────
import '../../features/farmer/pages/farmer_welcome_page.dart';
import '../../features/farmer/pages/farmer_settings_page.dart';
import '../../features/farmer/pages/plant_disease_page.dart';
import '../../features/farmer/pages/animal_weight_page.dart';
import '../../features/farmer/pages/crop_recommendation_page.dart';
import '../../features/farmer/pages/soil_analysis_page.dart';
import '../../features/farmer/pages/fruit_quality_page.dart';
import '../../features/farmer/pages/chatbot_page.dart';
import '../../features/farmer/pages/reports_page.dart';

// ── Admin pages ───────────────────────────────────────────────────────────────
import '../../features/admin/pages/admin_dashboard_page.dart';
import '../../features/admin/pages/user_management_page.dart';
import '../../features/admin/pages/system_management_page.dart';
import '../../features/admin/pages/admin_settings_page.dart';
import '../../features/admin/reports/screens/admin_reports_screen.dart';
import '../../features/admin/providers/admin_provider.dart';
import '../../features/shared/profile/pages/profile_page.dart';
import '../../features/admin/pages/messages_page.dart' as admin;
import '../../features/farmer/pages/messages_page.dart' as farmer;

// ── Shared shell widgets ──────────────────────────────────────────────────────
import 'app_sidebar.dart';
import 'app_top_bar.dart';

// Page registries — order must match enum order in NavigationProvider
const List<Widget> _farmerPages = [
  FarmerWelcomePage(), // FarmerPage.welcome
  PlantDiseasePage(), // FarmerPage.plantDisease
  AnimalWeightPage(), // FarmerPage.animalWeight
  CropRecommendationPage(), // FarmerPage.cropRecommendation
  SoilAnalysisPage(), // FarmerPage.soilAnalysis
  FruitQualityPage(), // FarmerPage.fruitQuality
  ChatbotPage(), // FarmerPage.chatbot
  farmer.FarmerMessagesPage(), // FarmerPage.messages
  ReportsPage(), // FarmerPage.reports
  FarmerSettingsPage(), // FarmerPage.settings
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
