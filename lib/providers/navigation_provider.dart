import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:smart_farm/core/constants/app_assets.dart';
import 'package:smart_farm/l10n/app_localizations.dart';

enum FarmerPage {
  welcome,
  plantDisease,
  animalWeight,
  cropRecommendation,
  soilAnalysis,
  fruitQuality,
  chatbot,
  messages,
  reports,
  settings,
  profile,
}

enum AdminPage {
  dashboard,
  userManagement,
  systemManagement,
  systemReports,
  messages,
  settings,
  profile,
}

class FarmerPageMeta {
  const FarmerPageMeta({
    required this.page,
    required this.label,
    required this.icon,
    this.svgAsset,
  });
  final FarmerPage page;
  final String label;
  final String icon;
  final String? svgAsset;
}

class AdminPageMeta {
  const AdminPageMeta({
    required this.page,
    required this.label,
    required this.icon,
    this.isAdminOnly = false,
  });
  final AdminPage page;
  final String label;
  final String icon;
  final bool isAdminOnly;
}

class NavigationProvider extends ChangeNotifier {
  // ── Farmer state ──────────────────────────────────────────────────────────
  FarmerPage _farmerPage = FarmerPage.welcome;
  FarmerPage get farmerPage => _farmerPage;
  int get farmerIndex => FarmerPage.values.indexOf(_farmerPage);

  void goToFarmerPage(FarmerPage page) {
    if (_farmerPage == page) return;
    _farmerPage = page;
    notifyListeners();
  }

  void goToFarmerIndex(int index) {
    if (index < 0 || index >= FarmerPage.values.length) return;
    goToFarmerPage(FarmerPage.values[index]);
  }

  // ── Admin state ────────────────────────────────────────────────────────────
  AdminPage _adminPage = AdminPage.dashboard;
  AdminPage get adminPage => _adminPage;
  int get adminIndex => AdminPage.values.indexOf(_adminPage);

  void goToAdminPage(AdminPage page) {
    if (_adminPage == page) return;
    _adminPage = page;
    notifyListeners();
  }

  void goToAdminIndex(int index) {
    if (index < 0 || index >= AdminPage.values.length) return;
    goToAdminPage(AdminPage.values[index]);
  }

  // ── Reset on logout ────────────────────────────────────────────────────────
  void reset() {
    _farmerPage = FarmerPage.welcome;
    _adminPage = AdminPage.dashboard;
    notifyListeners();
  }

  // ── Farmer metadata ────────────────────────────────────────────────────────
  static const List<FarmerPageMeta> farmerPages = [
    FarmerPageMeta(
        page: FarmerPage.welcome, label: 'Welcome', icon: 'home_outlined'),
    FarmerPageMeta(
        page: FarmerPage.plantDisease,
        label: 'Plant Disease Detection',
        icon: 'local_florist_outlined',
        svgAsset: AppAssets.plantIcon),
    FarmerPageMeta(
        page: FarmerPage.animalWeight,
        label: 'Animal Weight Estimation',
        icon: 'monitor_weight_outlined',
        svgAsset: AppAssets.animalIcon),
    FarmerPageMeta(
        page: FarmerPage.cropRecommendation,
        label: 'Crop Recommendation',
        icon: 'grass_outlined',
        svgAsset: AppAssets.cropIcon),
    FarmerPageMeta(
        page: FarmerPage.soilAnalysis,
        label: 'Soil Type Analysis',
        icon: 'layers_outlined',
        svgAsset: AppAssets.soilIcon),
    FarmerPageMeta(
        page: FarmerPage.fruitQuality,
        label: 'Fruit Quality Analysis',
        icon: 'apple_outlined',
        svgAsset: AppAssets.fruitIcon),
    FarmerPageMeta(
        page: FarmerPage.chatbot,
        label: 'Smart Farm Chatbot',
        icon: 'chat_bubble_outline',
        svgAsset: AppAssets.chatIcon),
    FarmerPageMeta(
        page: FarmerPage.messages, label: 'Messages', icon: 'email_outlined'),
    FarmerPageMeta(
        page: FarmerPage.reports, label: 'Reports', icon: 'bar_chart_outlined'),
    FarmerPageMeta(
        page: FarmerPage.settings,
        label: 'Settings',
        icon: 'settings_outlined'),
  ];

  // ── Admin metadata ─────────────────────────────────────────────────────────
  static const List<AdminPageMeta> adminPages = [
    AdminPageMeta(
        page: AdminPage.dashboard,
        label: 'Admin Dashboard',
        icon: 'dashboard_outlined'),
    AdminPageMeta(
        page: AdminPage.userManagement,
        label: 'User Management',
        icon: 'people_outline'),
    AdminPageMeta(
        page: AdminPage.systemManagement,
        label: 'System Management',
        icon: 'settings_applications_outlined',
        isAdminOnly: true),
    AdminPageMeta(
        page: AdminPage.systemReports,
        label: 'System Reports',
        icon: 'bar_chart_outlined'),
    AdminPageMeta(
        page: AdminPage.messages, label: 'Messages', icon: 'email_outlined'),
    AdminPageMeta(
        page: AdminPage.settings, label: 'Settings', icon: 'tune_outlined'),
  ];

  String getFarmerLabel(AppLocalizations l10n) => switch (_farmerPage) {
        FarmerPage.welcome => l10n.welcome_user,
        FarmerPage.profile => l10n.profile,
        FarmerPage.plantDisease => l10n.nav_plant_disease,
        FarmerPage.animalWeight => l10n.nav_animal_weight,
        FarmerPage.cropRecommendation => l10n.nav_crop_recommendation,
        FarmerPage.soilAnalysis => l10n.nav_soil_analysis,
        FarmerPage.fruitQuality => l10n.nav_fruit_quality,
        FarmerPage.chatbot => l10n.nav_chatbot,
        FarmerPage.messages => l10n.messages,
        FarmerPage.reports => l10n.nav_reports,
        FarmerPage.settings => l10n.settings,
      };

  String getAdminLabel(AppLocalizations l10n) => switch (_adminPage) {
        AdminPage.dashboard => l10n.admin_dashboard,
        AdminPage.userManagement => l10n.user_management,
        AdminPage.systemManagement => l10n.system_management,
        AdminPage.systemReports => l10n.nav_reports,
        AdminPage.messages => l10n.messages,
        AdminPage.settings => l10n.settings,
        AdminPage.profile => l10n.profile_settings,
      };
}
