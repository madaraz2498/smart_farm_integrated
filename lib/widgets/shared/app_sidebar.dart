// lib/widgets/shared/app_sidebar.dart
// Dynamic sidebar used by BOTH Admin and Farmer — auto-switches menus by role.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:smart_farm/l10n/app_localizations.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../shared/theme/app_theme.dart';

IconData _icon(String name) => switch (name) {
  'home_outlined'                  => Icons.home_outlined,
  'local_florist_outlined'         => Icons.local_florist_outlined,
  'monitor_weight_outlined'        => Icons.monitor_weight_outlined,
  'grass_outlined'                 => Icons.grass_outlined,
  'layers_outlined'                => Icons.layers_outlined,
  'apple_outlined'                 => Icons.apple_outlined,
  'chat_bubble_outline'            => Icons.chat_bubble_outline,
  'bar_chart_outlined'             => Icons.bar_chart_outlined,
  'settings_outlined'              => Icons.settings_outlined,
  'dashboard_outlined'             => Icons.dashboard_outlined,
  'people_outline'                 => Icons.people_outline,
  'settings_applications_outlined' => Icons.settings_applications_outlined,
  'tune_outlined'                  => Icons.tune_outlined,
  _                                => Icons.circle_outlined,
};

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key, this.insideDrawer = false});
  final bool insideDrawer;

  static Widget asDrawer() => const AppSidebar(insideDrawer: true);

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final nav     = context.watch<NavigationProvider>();
    final isAdmin = auth.isAdmin;

    final content = _SidebarContent(
      isAdmin:      isAdmin,
      userName:     auth.displayName,
      nav:          nav,
      insideDrawer: insideDrawer,
    );

    if (insideDrawer) {
      return Drawer(backgroundColor: AppColors.surface, child: content);
    }

    return Container(
      width: AppSizes.sidebarWidth,
      decoration: const BoxDecoration(
        color:  AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.cardBorder, width: 1.33)),
      ),
      child: content,
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.isAdmin,
    required this.userName,
    required this.nav,
    required this.insideDrawer,
  });
  final bool               isAdmin;
  final String             userName;
  final NavigationProvider nav;
  final bool               insideDrawer;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _SidebarHeader(isAdmin: isAdmin, userName: userName),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            isAdmin ? 'ADMIN PANEL' : 'MAIN MENU',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.2, color: AppColors.textSubtle),
          ),
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: isAdmin ? _adminItems(context) : _farmerItems(context),
        ),
      ),
    ]);
  }

  List<Widget> _adminItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return List.generate(NavigationProvider.adminPages.length, (i) {
      final meta = NavigationProvider.adminPages[i];
      final isSelected = nav.adminIndex == i;
      final label = switch (meta.page) {
        AdminPage.dashboard => l10n.nav_reports,
        AdminPage.userManagement => 'User Management',
        AdminPage.systemManagement => 'System Management',
        AdminPage.systemReports => l10n.nav_reports,
        AdminPage.settings => l10n.settings,
      };
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _NavTile(
          icon: _icon(meta.icon),
          label: label,
          isSelected: isSelected,
          badge: meta.isAdminOnly ? 'Admin' : null,
          onTap: () {
            nav.goToAdminIndex(i);
            if (insideDrawer) Navigator.pop(context);
          },
        ),
      );
    });
  }

  List<Widget> _farmerItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return List.generate(NavigationProvider.farmerPages.length, (i) {
      final meta = NavigationProvider.farmerPages[i];
      final isSelected = nav.farmerIndex == i;
      final label = switch (meta.page) {
        FarmerPage.welcome => l10n.welcome_user,
        FarmerPage.plantDisease => l10n.nav_plant_disease,
        FarmerPage.animalWeight => l10n.nav_animal_weight,
        FarmerPage.cropRecommendation => l10n.nav_crop_recommendation,
        FarmerPage.soilAnalysis => l10n.nav_soil_analysis,
        FarmerPage.fruitQuality => l10n.nav_fruit_quality,
        FarmerPage.chatbot => l10n.nav_chatbot,
        FarmerPage.reports => l10n.nav_reports,
        FarmerPage.settings => l10n.settings,
      };
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _NavTile(
          icon: _icon(meta.icon),
          svgAsset: meta.svgAsset,
          label: label,
          isSelected: isSelected,
          onTap: () {
            nav.goToFarmerIndex(i);
            if (insideDrawer) Navigator.pop(context);
          },
        ),
      );
    });
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.isAdmin, required this.userName});
  final bool   isAdmin;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        color:  AppColors.primary,
        border: Border(bottom: BorderSide(color: AppColors.primaryDark, width: 1)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusMid)),
          child: Icon(
            isAdmin ? Icons.admin_panel_settings_rounded : Icons.eco_rounded,
            color: Colors.white, size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Smart Farm AI', style: TextStyle(color: Colors.white, fontSize: 15,
              fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(userName, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      ]),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon, required this.label,
    required this.isSelected, required this.onTap,
    this.svgAsset, this.badge,
  });
  final IconData     icon;
  final String       label;
  final bool         isSelected;
  final VoidCallback onTap;
  final String?      svgAsset;
  final String?      badge;

  @override
  Widget build(BuildContext context) {
    final isLong = label.length > 20;
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:        isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(children: [
          if (svgAsset != null)
            SvgPicture.asset(svgAsset!, width: 20, height: 20,
                colorFilter: ColorFilter.mode(
                    isSelected ? Colors.white : AppColors.primary, BlendMode.srcIn))
          else
            Icon(icon, size: 20, color: isSelected ? Colors.white : AppColors.primary),
          const SizedBox(width: 12),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: isLong ? 12.5 : 14,
                  color: isSelected ? Colors.white : AppColors.textDark,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400))),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(badge!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.primary)),
            ),
          ],
        ]),
      ),
    );
  }
}
